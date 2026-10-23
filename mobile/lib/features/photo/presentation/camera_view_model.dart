import 'package:sedno_app/l10n/localization.dart';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/photo/data/camera_device_service.dart';
import 'package:sedno_app/features/photo/domain/photo_text_repository.dart';

class CameraViewModel extends ChangeNotifier {
  AppLocalizations Function() localizations = polishStrings;
  AppLocalizations get strings => localizations();

  CameraViewModel(this.camera);

  final CameraDeviceService camera;
  bool ready = false;
  bool busy = false;
  String? message;
  bool _disposed = false;
  bool _active = false;
  int _revision = 0;
  Future<void> _lifecycle = Future.value();

  Future<void> setActive(bool active) {
    final revision = ++_revision;
    _active = active;
    ready = false;
    if (!_disposed) notifyListeners();
    // Serialize release/reinitialization when Android opens a permission dialog
    // or the user backgrounds the app while the camera is starting.
    _lifecycle = _lifecycle.then((_) async {
      if (_disposed || !active || !_active) {
        await camera.release();
        return;
      }
      try {
        message = null;
        await camera.initialize();
        ready = !_disposed && _active && revision == _revision;
      } on CameraPermissionDenied {
        message = strings.cameraPermission;
      } catch (_) {
        message = strings.cameraStartFailed;
      }
      if (!_disposed) notifyListeners();
    });
    return _lifecycle;
  }

  Future<String?> takePicture() async {
    if (!ready || busy || _disposed) return null;
    busy = true;
    message = null;
    notifyListeners();
    try {
      final path = await camera.takePicture();
      if (_disposed || !_active) {
        try {
          await File(path).delete();
        } on FileSystemException {
          // The camera may already have removed the temporary file.
        }
        return null;
      }
      return path;
    } catch (_) {
      message = strings.photoCaptureFailed;
      return null;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    // Do not release the device midway through an initialization.
    _lifecycle.then((_) => camera.release());
    super.dispose();
  }
}
