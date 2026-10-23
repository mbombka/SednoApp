import 'package:sedno_app/app/app_language.dart';
import 'package:sedno_app/l10n/localization.dart';
import 'package:sedno_app/features/account/presentation/user_menu_screen.dart';

import 'dart:io';

import 'package:sedno_app/features/home/presentation/editor_result_view_model.dart';

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

class SednoApp extends StatefulWidget {
  const SednoApp({
    this.languageController,
    this.simplificationRepository,
    this.historyRepository,
    this.accountRepository,
    this.subscriptionModel,
    super.key,
  });

  final LanguageController? languageController;
  final SimplificationRepository? simplificationRepository;
  final HistoryRepository? historyRepository;
  final AccountRepository? accountRepository;
  final SubscriptionViewModel? subscriptionModel;

  static const name = 'SednoApp';
  static const displayName = 'Sedno';

  @override
  State<SednoApp> createState() => _SednoAppState();
}

class _SednoAppState extends State<SednoApp> {
  late final LanguageController _languages =
      widget.languageController ?? LanguageController();
  @override
  void dispose() {
    if (widget.languageController == null) _languages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
    controller: _languages,
    child: ListenableBuilder(
      listenable: _languages,
      builder: (context, _) => MaterialApp(
        title: SednoApp.displayName,
        debugShowCheckedModeBanner: false,
        locale: _languages.language.locale,
        supportedLocales: AppLanguage.values.map((language) => language.locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        home: _AppNavigation(
          simplificationRepository: widget.simplificationRepository,
          historyRepository: widget.historyRepository,
          accountRepository: widget.accountRepository,
          subscriptionModel: widget.subscriptionModel,
        ),
      ),
    ),
  );
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
  final EditorResultViewModel _editorResult = EditorResultViewModel();
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
    _editorResult.addListener(_onEditorResultChanged);
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

  String? _localeName;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeName = context.l10n.localeName;
    if (_localeName != null && _localeName != localeName) {
      widget.subscriptionModel?.message = null;
    }
    _localeName = localeName;
  }

  void _onEditorResultChanged() {
    if (mounted) setState(() {});
  }

  void _restoreOriginal() {
    final original = _editorResult.restoreOriginal();
    if (original == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _inputController.value = TextEditingValue(
      text: original,
      selection: TextSelection.collapsed(offset: original.length),
    );
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
    _editorResult.removeListener(_onEditorResultChanged);
    _editorResult.dispose();
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
            ? (_editorResult.mode?.localizedResultHeading(context.l10n) ??
                  '${SednoApp.displayName} - ${_mode.localizedHeading(context.l10n)}:')
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
              title: _selectedPage == 0 && _editorResult.hasOriginal
                  ? Tooltip(
                      message: context.l10n.restoreOriginal,
                      child: TextButton(
                        key: const Key('restoreOriginalButton'),
                        onPressed: _editorResult.busy ? null : _restoreOriginal,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.navy,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 48),
                          alignment: Alignment.centerLeft,
                          textStyle: Theme.of(context).textTheme.titleLarge,
                        ),
                        child: Text(title, softWrap: true, maxLines: 10),
                      ),
                    )
                  : Text(title, softWrap: true, maxLines: 10),
              centerTitle: false,
              actions: [
                IconButton(
                  tooltip: context.l10n.userMenu,
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
                  editorResult: _editorResult,
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
                    _editorResult.clear();
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
