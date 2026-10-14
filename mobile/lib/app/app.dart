import 'package:flutter/material.dart';
import 'package:simplifier_app/app/app_theme.dart';
import 'package:simplifier_app/features/account/presentation/account_screen.dart';
import 'package:simplifier_app/features/history/presentation/history_screen.dart';
import 'package:simplifier_app/features/home/presentation/home_screen.dart';
import 'package:simplifier_app/features/photo/data/local_photo_text_repository.dart';
import 'package:simplifier_app/features/shared/data/development_mocks.dart';
import 'package:simplifier_app/features/simplification/domain/simplification_repository.dart';

class SimplifierApp extends StatelessWidget {
  const SimplifierApp({this.simplificationRepository, super.key});

  final SimplificationRepository? simplificationRepository;

  static const name = 'SimplifierApp';
  static const displayName = 'Simplyfi_it';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: displayName,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: _AppNavigation(simplificationRepository: simplificationRepository),
    );
  }
}

class _AppNavigation extends StatefulWidget {
  const _AppNavigation({this.simplificationRepository});

  final SimplificationRepository? simplificationRepository;

  @override
  State<_AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<_AppNavigation> {
  final TextEditingController _inputController = TextEditingController();
  final _photoRepository = LocalPhotoTextRepository.android();
  late final SimplificationRepository? _simplificationRepository;

  @override
  void initState() {
    super.initState();
    if (widget.simplificationRepository case final repository?) {
      _simplificationRepository = repository;
    } else if (const bool.fromEnvironment('dart.vm.product')) {
      _simplificationRepository = null;
    } else {
      final quota = MockQuotaRepository(clock: DateTime.now);
      _simplificationRepository = MockSimplificationRepository(
        quota: quota,
        clock: DateTime.now,
      );
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(SimplifierApp.displayName),
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
              appName: SimplifierApp.displayName,
              textController: _inputController,
              photoRepository: _photoRepository,
              simplificationRepository: _simplificationRepository,
            ),
            const HistoryScreen(),
            const AccountScreen(),
          ],
        ),
      ),
    );
  }
}
