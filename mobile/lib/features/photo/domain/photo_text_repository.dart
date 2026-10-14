/// A photo stays on the device. Only the recognized text reaches the editor.
abstract interface class PhotoTextRepository {
  /// Returns null if taking or cropping the photo was cancelled.
  Future<String?> recognizeFromCamera();
}

class CameraPermissionDenied implements Exception {
  const CameraPermissionDenied();
}
