import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sedno_app/features/home/presentation/text_input_view_model.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/history/domain/history_repository.dart';
import 'package:sedno_app/features/photo/domain/photo_text_repository.dart';
import 'package:sedno_app/features/photo/presentation/photo_input_view_model.dart';
import 'package:sedno_app/features/privacy/presentation/privacy_screen.dart';
import 'package:sedno_app/features/quota/domain/quota_repository.dart';
import 'package:sedno_app/features/quota/domain/quota_reset.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/simplification/presentation/result_screen.dart';
import 'package:sedno_app/features/simplification/presentation/simplification_view_model.dart';
import 'package:sedno_app/features/speech/data/android_speech_service.dart';
import 'package:sedno_app/features/speech/domain/speech_service.dart';
import 'package:sedno_app/features/speech/presentation/speech_input_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.appName,
    required this.textController,
    this.onSubmit,
    this.isActive = true,
    this.speechService = const AndroidSpeechService(),
    this.onCameraPressed,
    this.photoRepository,
    this.simplificationRepository,
    this.historyRepository,
    this.onHistorySaved,
    super.key,
  });

  final String appName;
  final TextEditingController textController;
  final SubmitText? onSubmit;
  final bool isActive;
  final SpeechService speechService;
  final VoidCallback? onCameraPressed;
  final PhotoTextRepository? photoRepository;
  final SimplificationRepository? simplificationRepository;
  final HistoryRepository? historyRepository;
  final VoidCallback? onHistorySaved;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final TextInputViewModel _inputViewModel;
  PhotoInputViewModel? _photoViewModel;
  late SpeechInputViewModel _speechViewModel;
  SimplificationViewModel? _simplificationViewModel;
  QuotaStateSource? _quotaSource;
  Timer? _resetTimer;
  final Stopwatch _quotaAge = Stopwatch();
  bool _aiNoticeAccepted = false;
  bool _confirmingSubmission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speechViewModel = SpeechInputViewModel(widget.speechService);
    _inputViewModel = TextInputViewModel(onSubmit: _submit);
    _inputViewModel.setText(widget.textController.text);
    if (widget.photoRepository case final repository?) {
      _photoViewModel = PhotoInputViewModel(repository);
    }
    if (widget.simplificationRepository case final repository?) {
      _simplificationViewModel = SimplificationViewModel(
        repository: repository,
      );
    }
    _attachQuota(widget.simplificationRepository);
    widget.textController.addListener(_onTextChanged);
  }

  void _attachQuota(SimplificationRepository? repository) {
    if (repository case final QuotaStateSource source) {
      _quotaSource = source;
      source.quotaListenable.addListener(_onQuotaChanged);
    } else {
      return;
    }
    _onQuotaChanged();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    try {
      await _quotaSource?.current();
    } catch (_) {
      final quota = _quotaSource?.quotaListenable.value;
      if (quota != null &&
          quota.remaining == 0 &&
          _remainingUntilReset(quota) == Duration.zero) {
        _resetTimer?.cancel();
        _resetTimer = Timer(const Duration(seconds: 30), _loadQuota);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadQuota();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_speechViewModel.cancel());
    }
  }

  void _onQuotaChanged() {
    _resetTimer?.cancel();
    _quotaAge
      ..reset()
      ..start();
    final quota = _quotaSource?.quotaListenable.value;
    if (quota == null) return;
    _resetTimer = Timer(
      _remainingUntilReset(quota) + const Duration(seconds: 1),
      _loadQuota,
    );
  }

  Duration _remainingUntilReset(QuotaState quota) {
    final remaining =
        quota.resetAt.difference(quota.serverTime) - _quotaAge.elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _timeUntilReset(QuotaState quota) {
    final remaining = _remainingUntilReset(quota);
    final totalMinutes =
        (remaining.inMicroseconds + Duration.microsecondsPerMinute - 1) ~/
        Duration.microsecondsPerMinute;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes.remainder(60);
    return 'za $hours godz. $minutes min';
  }

  static Future<void> _unavailableSubmission(InputText _) async {
    throw const SubmissionUnavailableException();
  }

  Future<void> _requestSubmission() async {
    if (_confirmingSubmission) return;
    _confirmingSubmission = true;
    try {
      // Let the existing validator report empty or overlong input before asking.
      try {
        InputText(widget.textController.text);
      } on FormatException {
        await _inputViewModel.submit();
        return;
      }
      if (!mounted) return;
      if (_quotaSource != null && _quotaSource!.quotaListenable.value == null) {
        await _loadQuota();
        if (!mounted) return;
      }
      final quota = _quotaSource?.quotaListenable.value;
      if (_quotaSource != null && quota == null) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sprawdź połączenie'),
            content: const Text(
              'Nie można sprawdzić limitu. Sprawdź połączenie.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Zamknij'),
              ),
            ],
          ),
        );
        return;
      }
      if (quota != null &&
          quota.tier == QuotaTier.free &&
          quota.remaining < 2) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Dzienny limit'),
            content: Text(
              quota.remaining == 1
                  ? 'Pozostało 1 uproszczenie.\n'
                        'Nowy limit o ${QuotaReset.localTime(resetAt: quota.resetAt)} (${_timeUntilReset(quota)}).'
                  : 'Wykorzystano dzienny limit.\n'
                        'Nowy limit o ${QuotaReset.localTime(resetAt: quota.resetAt)} (${_timeUntilReset(quota)}).\n'
                        'Subskrypcję i jej cenę znajdziesz w menu Konto.',
              key: const Key('quotaMessage'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Zamknij'),
              ),
              if (quota.remaining > 0)
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Dalej'),
                ),
            ],
          ),
        );
        if (!mounted || proceed != true || quota.remaining == 0) return;
      }
      if (!mounted) return;
      if (!_aiNoticeAccepted) {
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Zanim uprościsz tekst'),
            content: const SingleChildScrollView(
              child: Text(
                PrivacyScreen.aiNotice,
                key: Key('aiProcessingNotice'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Anuluj'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                ),
                child: const Text('Prywatność i dane'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Rozumiem, wyślij'),
              ),
            ],
          ),
        );
        if (!mounted || accepted != true) return;
        _aiNoticeAccepted = true;
      }
      if (!mounted) return;
      if (_quotaSource?.quotaListenable.value?.remaining == 0) return;
      await _inputViewModel.submit();
    } finally {
      _confirmingSubmission = false;
    }
  }

  Future<void> _submit(InputText input) async {
    if (widget.onSubmit case final callback?) return callback(input);
    if (_simplificationViewModel case final model?) {
      final result = await model.simplify(input);
      if (!mounted) return;
      if (widget.historyRepository case final history?) {
        try {
          await history.save(HistoryEntry(original: input, result: result));
          widget.onHistorySaved?.call();
        } catch (_) {
          // A storage failure must not hide a successful simplification.
        }
      }
      if (!mounted) return;
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            result: result,
            originalText: input.value,
            onNewText: widget.textController.clear,
          ),
        ),
      );
      return;
    }
    return _unavailableSubmission(input);
  }

  void _onTextChanged() => _inputViewModel.setText(widget.textController.text);

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive) unawaited(_speechViewModel.cancel());
    if (oldWidget.textController != widget.textController) {
      oldWidget.textController.removeListener(_onTextChanged);
      _inputViewModel.setText(widget.textController.text);
      widget.textController.addListener(_onTextChanged);
    }
    if (oldWidget.speechService != widget.speechService) {
      _speechViewModel.dispose();
      _speechViewModel = SpeechInputViewModel(widget.speechService);
    }
    if (oldWidget.photoRepository != widget.photoRepository) {
      _photoViewModel?.dispose();
      _photoViewModel = widget.photoRepository == null
          ? null
          : PhotoInputViewModel(widget.photoRepository!);
    }
    if (oldWidget.simplificationRepository != widget.simplificationRepository) {
      _quotaSource?.quotaListenable.removeListener(_onQuotaChanged);
      _resetTimer?.cancel();
      _quotaSource = null;
      _simplificationViewModel = widget.simplificationRepository == null
          ? null
          : SimplificationViewModel(
              repository: widget.simplificationRepository!,
            );
      _attachQuota(widget.simplificationRepository);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.textController.removeListener(_onTextChanged);
    _speechViewModel.dispose();
    _inputViewModel.dispose();
    _photoViewModel?.dispose();
    _quotaSource?.quotaListenable.removeListener(_onQuotaChanged);
    _resetTimer?.cancel();
    _quotaAge.stop();
    super.dispose();
  }

  Future<void> _listen() async {
    FocusScope.of(context).unfocus();
    final text = await _speechViewModel.listen();
    if (!mounted || !widget.isActive || text == null) return;
    widget.textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    await _requestSubmission();
  }

  Future<void> _openCamera() async {
    if (widget.onCameraPressed case final callback?) {
      callback();
    } else if (_photoViewModel case final model?) {
      final text = await model.scan();
      if (!mounted || text == null) return;
      widget.textController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      // The crop screen's Uprość button submits the recognized text directly.
      // Validation, quota and AI notice still apply; on failure the text stays
      // in the editor for manual correction.
      await _requestSubmission();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aparat będzie dostępny wkrótce.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _inputViewModel,
        _speechViewModel,
        ?_photoViewModel,
        ?_quotaSource?.quotaListenable,
      ]),
      builder: (context, _) {
        final busy =
            _inputViewModel.isLoading ||
            _speechViewModel.busy ||
            (_photoViewModel?.isLoading ?? false);
        return LayoutBuilder(
          builder: (context, constraints) {
            // Match the compact bottom spacing in the reference, while
            // leaving the Android navigation area outside the touch targets.
            final bottomSpacing = 32.0 + MediaQuery.paddingOf(context).bottom;
            final editorHeight =
                (constraints.maxHeight - 112 - 28 - bottomSpacing).clamp(
                  160.0,
                  double.infinity,
                );
            return SizedBox(
              height: constraints.maxHeight,
              child: ColoredBox(
                color: const Color(0xFFF5F7FB),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: editorHeight,
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(36),
                          ),
                        ),
                        child: Semantics(
                          label: 'Tekst do uproszczenia',
                          child: TextField(
                            controller: widget.textController,
                            enabled: !busy,
                            expands: true,
                            minLines: null,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Wpisz lub wklej tekst',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Center(
                                child: IconButton.filledTonal(
                                  key: const Key('microphoneButton'),
                                  tooltip: _speechViewModel.busy
                                      ? 'Anuluj nagrywanie'
                                      : 'Uprość mowę',
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(56, 56),
                                    backgroundColor: const Color(0xFFC2E7FF),
                                    foregroundColor: const Color(0xFF14243A),
                                  ),
                                  onPressed: _speechViewModel.busy
                                      ? _speechViewModel.cancel
                                      : busy ||
                                            !widget.isActive ||
                                            _confirmingSubmission
                                      ? null
                                      : _listen,
                                  icon: Icon(
                                    _speechViewModel.busy
                                        ? Icons.stop_rounded
                                        : Icons.mic_rounded,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: FilledButton(
                                  key: const Key('simplifyButton'),
                                  style: FilledButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(20),
                                    minimumSize: const Size(112, 112),
                                  ),
                                  onPressed: _inputViewModel.canSubmit && !busy
                                      ? _requestSubmission
                                      : null,
                                  child: _inputViewModel.isLoading
                                      ? const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            semanticsLabel: 'Upraszczanie…',
                                          ),
                                        )
                                      : const Text('Uprość'),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: OutlinedButton(
                                  key: const Key('cameraButton'),
                                  style: OutlinedButton.styleFrom(
                                    shape: const CircleBorder(),
                                    side: BorderSide.none,
                                    backgroundColor: const Color(0xFFC2E7FF),
                                    foregroundColor: const Color(0xFF14243A),
                                    minimumSize: const Size(56, 56),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  onPressed: busy ? null : _openCamera,
                                  child: Semantics(
                                    label: (_photoViewModel?.isLoading ?? false)
                                        ? 'Odczytywanie…'
                                        : 'Aparat',
                                    child: const ExcludeSemantics(
                                      child: Icon(
                                        Icons.photo_camera_outlined,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_speechViewModel.busy)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Semantics(
                            liveRegion: true,
                            child: const Text(
                              'Nasłuchiwanie… Mów po polsku. Koniec po 1,5 sekundy ciszy lub po 60 sekundach. Przycisk stop anuluje nagrywanie.',
                              key: Key('speechStatus'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (_speechViewModel.message case final message?)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              message,
                              key: const Key('speechMessage'),
                            ),
                          ),
                        ),
                      if (_inputViewModel.errorMessage case final error?)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(error, semanticsLabel: error),
                        ),
                      if (_photoViewModel?.message case final message?) ...[
                        const SizedBox(height: 12),
                        Text(message, key: const Key('photoMessage')),
                      ],
                      SizedBox(height: bottomSpacing),
                      if (_inputViewModel.status == TextInputStatus.success &&
                          widget.simplificationRepository == null) ...[
                        const SizedBox(height: 16),
                        const Text('Tekst został przekazany do uproszczenia.'),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
