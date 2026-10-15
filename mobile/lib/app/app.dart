import 'dart:io';
import 'dart:async';

import 'package:sedno_app/features/subscription/presentation/subscription_view_model.dart';

import 'package:flutter/material.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/account/presentation/account_screen.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';
import 'package:sedno_app/features/history/data/encrypted_history_repository.dart';
import 'package:sedno_app/features/history/domain/history_repository.dart';
import 'package:sedno_app/features/history/presentation/history_screen.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/photo/data/local_photo_text_repository.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';

class SednoApp extends StatelessWidget {
  const SednoApp({
    this.simplificationRepository,
    this.historyRepository,
    this.accountRepository,
    this.subscriptionModel,
    super.key,
  });

  final SimplificationRepository? simplificationRepository;
  final HistoryRepository? historyRepository;
  final AccountRepository? accountRepository;
  final SubscriptionViewModel? subscriptionModel;

  static const name = 'SednoApp';
  static const displayName = 'Sedno';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: displayName,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: _AppNavigation(
        simplificationRepository: simplificationRepository,
        historyRepository: historyRepository,
        accountRepository: accountRepository,
        subscriptionModel: subscriptionModel,
      ),
    );
  }
}

class _AppNavigation extends StatefulWidget {
  const _AppNavigation({
    this.simplificationRepository,
    this.historyRepository,
    this.accountRepository,
    this.subscriptionModel,
  });

  final SimplificationRepository? simplificationRepository;
  final HistoryRepository? historyRepository;
  final AccountRepository? accountRepository;
  final SubscriptionViewModel? subscriptionModel;

  @override
  State<_AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<_AppNavigation>
    with WidgetsBindingObserver {
  final TextEditingController _inputController = TextEditingController();
  final _photoRepository = LocalPhotoTextRepository.android();
  late final SimplificationRepository? _simplificationRepository;
  late final HistoryRepository _historyRepository;
  final ValueNotifier<int> _historyRevision = ValueNotifier<int>(0);
  bool _disposed = false;
  int _dataRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _historyRepository =
        widget.historyRepository ??
        (Platform.isAndroid
            ? EncryptedHistoryRepository(
                store: const AndroidHistoryDocumentStore(),
                clock: DateTime.now,
              )
            : MockHistoryRepository(clock: DateTime.now));
    _purgeHistory();
    _simplificationRepository = widget.simplificationRepository;
  }

  Future<void> _purgeHistory() async {
    if (_disposed) return;
    _historyRevision.value++;
    try {
      await _historyRepository.readAll();
      if (!_disposed) _historyRevision.value++;
    } catch (_) {
      // The history screen shows storage errors when opened.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _purgeHistory();
      unawaited(widget.subscriptionModel?.refresh());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _historyRevision.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(SednoApp.displayName),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(height: 56, text: 'Start'),
              Tab(height: 56, text: 'Historia'),
              Tab(height: 56, text: 'Konto'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            HomeScreen(
              key: ValueKey('home-$_dataRevision'),
              appName: SednoApp.displayName,
              textController: _inputController,
              photoRepository: _photoRepository,
              simplificationRepository: _simplificationRepository,
              historyRepository: _historyRepository,
              onHistorySaved: () => _historyRevision.value++,
            ),
            HistoryScreen(
              key: ValueKey('history-$_dataRevision'),
              repository: _historyRepository,
              revision: _historyRevision,
            ),
            AccountScreen(
              onDataCleared: () {
                _inputController.clear();
                _historyRevision.value++;
                setState(() => _dataRevision++);
              },
              repository: widget.accountRepository,
              subscriptionModel: widget.subscriptionModel,
            ),
          ],
        ),
      ),
    );
  }
}
