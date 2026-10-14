import 'package:flutter/material.dart';
import 'package:simplifier_app/features/home/presentation/home_view_model.dart';
import 'package:simplifier_app/features/home/presentation/text_input_view_model.dart';
import 'package:simplifier_app/features/photo/domain/photo_text_repository.dart';
import 'package:simplifier_app/features/photo/presentation/photo_input_view_model.dart';
import 'package:simplifier_app/features/simplification/domain/input_text.dart';
import 'package:simplifier_app/features/simplification/domain/simplification_repository.dart';
import 'package:simplifier_app/features/simplification/presentation/result_screen.dart';
import 'package:simplifier_app/features/simplification/presentation/simplification_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.appName,
    required this.textController,
    this.onSubmit,
    this.onCameraPressed,
    this.photoRepository,
    this.simplificationRepository,
    super.key,
  });

  final String appName;
  final TextEditingController textController;
  final SubmitText? onSubmit;
  final VoidCallback? onCameraPressed;
  final PhotoTextRepository? photoRepository;
  final SimplificationRepository? simplificationRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextInputViewModel _inputViewModel;
  PhotoInputViewModel? _photoViewModel;
  SimplificationViewModel? _simplificationViewModel;

  @override
  void initState() {
    super.initState();
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
    widget.textController.addListener(_onTextChanged);
  }

  static Future<void> _unavailableSubmission(InputText _) async {
    throw const SubmissionUnavailableException();
  }

  Future<void> _submit(InputText input) async {
    if (widget.onSubmit case final callback?) return callback(input);
    if (_simplificationViewModel case final model?) {
      final result = await model.simplify(input);
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
      _simplificationViewModel = widget.simplificationRepository == null
          ? null
          : SimplificationViewModel(
              repository: widget.simplificationRepository!,
            );
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    _inputViewModel.dispose();
    _photoViewModel?.dispose();
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
      animation: Listenable.merge([_inputViewModel, ?_photoViewModel]),
      builder: (context, _) => SingleChildScrollView(
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
            const SizedBox(height: 16),
            const Text(
              'Tekst zostanie przekazany dostawcy AI do uproszczenia.',
            ),
            if (_inputViewModel.status == TextInputStatus.success &&
                widget.simplificationRepository == null) ...[
              const SizedBox(height: 16),
              const Text('Tekst został przekazany do uproszczenia.'),
            ],
          ],
        ),
      ),
    );
  }
}
