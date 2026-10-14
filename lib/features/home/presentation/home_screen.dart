import 'package:flutter/material.dart';
import 'package:simplifier_app/features/home/presentation/home_view_model.dart';
import 'package:simplifier_app/features/home/presentation/text_input_view_model.dart';
import 'package:simplifier_app/features/simplification/domain/input_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.appName,
    required this.textController,
    this.onSubmit,
    this.onCameraPressed,
    super.key,
  });

  final String appName;
  final TextEditingController textController;
  final SubmitText? onSubmit;
  final VoidCallback? onCameraPressed;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextInputViewModel _inputViewModel;

  @override
  void initState() {
    super.initState();
    _inputViewModel = TextInputViewModel(
      onSubmit: widget.onSubmit ?? _unavailableSubmission,
    );
    _inputViewModel.setText(widget.textController.text);
    widget.textController.addListener(_onTextChanged);
  }

  static Future<void> _unavailableSubmission(InputText _) async {
    throw const SubmissionUnavailableException();
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
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    _inputViewModel.dispose();
    super.dispose();
  }

  void _openCamera() {
    if (widget.onCameraPressed case final callback?) {
      callback();
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
      animation: _inputViewModel,
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
              enabled: !_inputViewModel.isLoading,
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
                  onPressed: _inputViewModel.isLoading ? null : _openCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Aparat'),
                ),
                FilledButton(
                  onPressed: _inputViewModel.canSubmit
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
            const SizedBox(height: 16),
            const Text(
              'Tekst zostanie przekazany dostawcy AI do uproszczenia.',
            ),
            if (_inputViewModel.status == TextInputStatus.success) ...[
              const SizedBox(height: 16),
              const Text('Tekst został przekazany do uproszczenia.'),
            ],
          ],
        ),
      ),
    );
  }
}
