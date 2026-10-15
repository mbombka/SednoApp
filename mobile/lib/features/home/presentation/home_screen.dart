import 'package:sedno_app/features/privacy/presentation/privacy_screen.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sedno_app/features/home/presentation/home_view_model.dart';
import 'package:sedno_app/features/home/presentation/text_input_view_model.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/history/domain/history_repository.dart';
import 'package:sedno_app/features/photo/domain/photo_text_repository.dart';
import 'package:sedno_app/features/photo/presentation/photo_input_view_model.dart';
import 'package:sedno_app/features/quota/domain/quota_repository.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/simplification/presentation/result_screen.dart';
import 'package:sedno_app/features/simplification/presentation/simplification_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.appName,
    required this.textController,
    this.onSubmit,
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
  SimplificationViewModel? _simplificationViewModel;
  QuotaStateSource? _quotaSource;
  Timer? _resetTimer;
  Timer? _counterTimer;
  final Stopwatch _quotaAge = Stopwatch();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    if (state == AppLifecycleState.resumed) _loadQuota();
  }

  void _onQuotaChanged() {
    _resetTimer?.cancel();
    _counterTimer?.cancel();
    _quotaAge
      ..reset()
      ..start();
    final quota = _quotaSource?.quotaListenable.value;
    if (quota == null) return;
    _resetTimer = Timer(
      _remainingUntilReset(quota) + const Duration(seconds: 1),
      _loadQuota,
    );
    if (quota.remaining < 2) {
      _counterTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
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
    if (oldWidget.textController != widget.textController) {
      oldWidget.textController.removeListener(_onTextChanged);
      _inputViewModel.setText(widget.textController.text);
      widget.textController.addListener(_onTextChanged);
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
      _counterTimer?.cancel();
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
    _inputViewModel.dispose();
    _photoViewModel?.dispose();
    _quotaSource?.quotaListenable.removeListener(_onQuotaChanged);
    _resetTimer?.cancel();
    _counterTimer?.cancel();
    _quotaAge.stop();
    super.dispose();
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aparat będzie dostępny wkrótce.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = HomeViewModel(appName: widget.appName);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _inputViewModel,
        ?_photoViewModel,
        ?_quotaSource?.quotaListenable,
      ]),
      builder: (context, _) {
        final quota = _quotaSource?.quotaListenable.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.welcomeMessage,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: widget.textController,
                enabled:
                    !_inputViewModel.isLoading &&
                    !(_photoViewModel?.isLoading ?? false),
                minLines: 6,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Tekst do uproszczenia',
                  hintText: 'Wpisz lub wklej tekst',
                  alignLabelWithHint: true,
                  errorText: _inputViewModel.errorMessage,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _inputViewModel.characterCounter,
                  key: const Key('characterCounter'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                PrivacyScreen.aiNotice,
                key: Key('aiProcessingNotice'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                ),
                child: const Text('Prywatność i dane'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        _inputViewModel.isLoading ||
                            (_photoViewModel?.isLoading ?? false)
                        ? null
                        : _openCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      (_photoViewModel?.isLoading ?? false)
                          ? 'Odczytywanie…'
                          : 'Aparat',
                    ),
                  ),
                  FilledButton(
                    onPressed:
                        _inputViewModel.canSubmit &&
                            (quota == null || quota.remaining > 0) &&
                            !(_photoViewModel?.isLoading ?? false)
                        ? _inputViewModel.submit
                        : null,
                    child: _inputViewModel.isLoading
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Upraszczanie…'),
                            ],
                          )
                        : const Text('Uprość'),
                  ),
                ],
              ),
              if (_photoViewModel?.message case final message?) ...[
                const SizedBox(height: 12),
                Text(message, key: const Key('photoMessage')),
              ],
              if (quota != null &&
                  quota.tier == QuotaTier.free &&
                  quota.remaining < 2) ...[
                const SizedBox(height: 12),
                Text(
                  quota.remaining == 1
                      ? 'Pozostało 1 uproszczenie. Limit odnowi się o 00:00 UTC (${_timeUntilReset(quota)}).'
                      : 'Wykorzystano dzienny limit. Odnowi się o 00:00 UTC (${_timeUntilReset(quota)}). Subskrypcję i jej cenę znajdziesz w zakładce Konto.',
                  key: const Key('quotaMessage'),
                ),
              ],
              if (_inputViewModel.errorMessage == null &&
                  _quotaSource != null &&
                  quota == null) ...[
                const SizedBox(height: 12),
                const Text('Nie można sprawdzić limitu. Sprawdź połączenie.'),
              ],
              const SizedBox(height: 16),
              if (_inputViewModel.status == TextInputStatus.success &&
                  widget.simplificationRepository == null) ...[
                const SizedBox(height: 16),
                const Text('Tekst został przekazany do uproszczenia.'),
              ],
            ],
          ),
        );
      },
    );
  }
}
