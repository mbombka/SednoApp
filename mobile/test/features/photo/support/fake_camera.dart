import 'dart:async';

import 'package:camera/camera.dart';
import 'package:sedno_app/features/photo/data/camera_device_service.dart';

class FakeCamera implements CameraDeviceService {
  Object? error;
  int starts = 0;
  int releases = 0;
  int captures = 0;
  Completer<void>? initialization;
  Completer<String>? picture;
  @override
  CameraController? get controller => null;
  @override
  Future<void> initialize() async {
    starts++;
    await initialization?.future;
    if (error != null) throw error!;
  }

  @override
  Future<void> release() async {
    releases++;
  }

  @override
  Future<String> takePicture() async {
    captures++;
    return picture == null ? 'photo.jpg' : await picture!.future;
  }
}
