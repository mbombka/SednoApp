import 'package:sedno_app/l10n/localization.dart';

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sedno_app/features/photo/presentation/camera_view_model.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({required this.model, super.key});

  final CameraViewModel model;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.model.setActive(true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(widget.model.setActive(state == AppLifecycleState.resumed));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final strings = context.l10n;
    if (widget.model.strings.localeName != strings.localeName) {
      widget.model.message = null;
    }
    widget.model.localizations = () => strings;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final model = widget.model;
      final controller = model.camera.controller;
      return PopScope(
        canPop: !model.busy,
        child: Scaffold(
          appBar: AppBar(title: Text(context.l10n.takeTextPhoto)),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: model.ready && controller != null
                        ? CameraPreview(controller)
                        : model.message != null
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              model.message!,
                              semanticsLabel: model.message,
                            ),
                          )
                        : CircularProgressIndicator(
                            semanticsLabel: context.l10n.startingCamera,
                          ),
                  ),
                ),
                if (model.ready && model.message != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(model.message!),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 56),
                      ),
                      onPressed: model.ready && !model.busy
                          ? () async {
                              final path = await model.takePicture();
                              if (context.mounted && path != null) {
                                Navigator.pop(context, path);
                              }
                            }
                          : null,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(
                        model.busy
                            ? context.l10n.takingPhoto
                            : context.l10n.takePhoto,
                      ),
                    ),
                  ),
                ),
                if (!model.ready && model.message != null)
                  TextButton(
                    onPressed: () => model.setActive(true),
                    child: Text(context.l10n.tryAgain),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
