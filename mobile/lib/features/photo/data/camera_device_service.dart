import 'package:camera/camera.dart';
import 'package:sedno_app/features/photo/domain/photo_text_repository.dart';

abstract interface class CameraDeviceService {
  CameraController? get controller;
  Future<void> initialize();
  Future<String> takePicture();
  Future<void> release();
}

class AndroidCameraDeviceService implements CameraDeviceService {
  CameraController? _controller;

  @override
  CameraController? get controller => _controller;

  @override
  Future<void> initialize() async {
    await release();
    try {
      final cameras = await availableCameras();
      final rear = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      final selected = rear.isNotEmpty ? rear.first : cameras.first;
      final controller = CameraController(
        selected,
        ResolutionPreset.max,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
    } on CameraException catch (error) {
      await release();
      if (const {
        'CameraAccessDenied',
        'CameraAccessDeniedWithoutPrompt',
        'CameraAccessRestricted',
      }.contains(error.code)) {
        throw const CameraPermissionDenied();
      }
      rethrow;
    }
  }

  @override
  Future<String> takePicture() async => (await _controller!.takePicture()).path;

  @override
  Future<void> release() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }
}
