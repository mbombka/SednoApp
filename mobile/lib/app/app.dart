import 'package:sedno_app/features/account/presentation/user_menu_screen.dart';

import 'dart:io';

import 'package:sedno_app/features/simplification/domain/text_mode.dart';

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
import 'package:sedno_app/features/photo/presentation/photo_navigation_service.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/features/quota/domain/quota_repository.dart';
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
      debugShowCheckedModeBanner: false,
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
  late final _photoNavigation = PhotoNavigationService(() => context);
  late final _photoRepository = LocalPhotoTextRepository(
    captureService: _photoNavigation,
    cropService: _photoNavigation,
    ocrService: MlKitPhotoOcrService(),
    temporaryPhotoStore: FileTemporaryPhotoStore(),
  );
  late final SimplificationRepository? _simplificationRepository;
  late final HistoryRepository _historyRepository;
  final ValueNotifier<int> _historyRevision = ValueNotifier<int>(0);
  bool _disposed = false;
  int _dataRevision = 0;
  int _selectedPage = 0;
  TextMode _mode = TextMode.simplify;
  final List<int> _previousPages = [];

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
    unawaited(widget.subscriptionModel?.start());
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

  bool _showingMenu = false;

  Future<void> _openUserMenu() async {
    setState(() => _showingMenu = true);
    FocusManager.instance.primaryFocus?.unfocus();
    UserMenuDestination? destination;
    try {
      destination = await Navigator.of(context).push<UserMenuDestination>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const UserMenuScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _showingMenu = false);
    }
    if (!mounted || destination == null) return;
    final page = switch (destination) {
      UserMenuDestination.start => 0,
      UserMenuDestination.history => 1,
      UserMenuDestination.account => 2,
    };
    if (page == _selectedPage) return;
    setState(() {
      if (page == 0) {
        _previousPages.clear();
      } else {
        _previousPages.add(_selectedPage);
      }
      _selectedPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = _selectedPage == 0
            ? '${SednoApp.displayName} - ${_mode.heading}:'
            : SednoApp.displayName;
        final titleLayout =
            TextPainter(
              text: TextSpan(
                text: title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(
              maxWidth: (constraints.maxWidth - 100).clamp(
                1.0,
                double.infinity,
              ),
            );
        final toolbarHeight = (titleLayout.height + 16).clamp(
          kToolbarHeight,
          double.infinity,
        );
        titleLayout.dispose();
        return PopScope<void>(
          canPop: _selectedPage == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop || _selectedPage == 0) return;
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _selectedPage = _previousPages.removeLast());
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: toolbarHeight,
              title: Text(title, softWrap: true, maxLines: 10),
              centerTitle: false,
              actions: [
                IconButton(
                  tooltip: 'Menu użytkownika',
                  icon: const Icon(Icons.account_circle_outlined, size: 32),
                  color: AppTheme.blue,
                  onPressed: _openUserMenu,
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: IndexedStack(
              index: _selectedPage,
              children: [
                HomeScreen(
                  key: ValueKey('home-$_dataRevision'),
                  appName: SednoApp.displayName,
                  onModeChanged: (mode) => setState(() => _mode = mode),
                  isActive: _selectedPage == 0 && !_showingMenu,
                  textController: _inputController,
                  photoRepository: _photoRepository,
                  simplificationRepository: _simplificationRepository,
                  historyRepository: _historyRepository,
                  onHistorySaved: () => _historyRevision.value++,
                ),
                if (_selectedPage == 1)
                  HistoryScreen(
                    key: ValueKey('history-$_dataRevision'),
                    repository: _historyRepository,
                    revision: _historyRevision,
                  )
                else
                  const SizedBox.shrink(),
                AccountScreen(
                  onDataCleared: () {
                    _inputController.clear();
                    _historyRevision.value++;
                    setState(() {
                      _dataRevision++;
                      _mode = TextMode.simplify;
                    });
                  },
                  repository: widget.accountRepository,
                  subscriptionModel: widget.subscriptionModel,
                  quota: switch (_simplificationRepository) {
                    final QuotaStateSource source => source.quotaListenable,
                    _ => null,
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
