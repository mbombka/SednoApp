import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:sedno_app/features/photo/domain/photo_text_repository.dart';

abstract interface class PhotoCaptureService {
  Future<String?> capture();
}

abstract interface class PhotoCropService {
  Future<String?> crop(String path);
}

abstract interface class PhotoOcrService {
  Future<String> recognize(String path);
}

abstract interface class TemporaryPhotoStore {
  Future<void> delete(String path);
}

class LocalPhotoTextRepository implements PhotoTextRepository {
  LocalPhotoTextRepository({
    required this.captureService,
    required this.cropService,
    required this.ocrService,
    required this.temporaryPhotoStore,
  });

  final PhotoCaptureService captureService;
  final PhotoCropService cropService;
  final PhotoOcrService ocrService;
  final TemporaryPhotoStore temporaryPhotoStore;

  @override
  Future<String?> recognizeFromCamera() async {
    String? capturedPath;
    String? croppedPath;
    try {
      capturedPath = await captureService.capture();
      if (capturedPath == null) return null;
      croppedPath = await cropService.crop(capturedPath);
      if (croppedPath == null) return null;
      return await ocrService.recognize(croppedPath);
    } finally {
      // Capture and cropping write into temporary app storage.
      // Delete both copies after OCR, cancellation, and processing errors.
      for (final path in {?capturedPath, ?croppedPath}) {
        try {
          await temporaryPhotoStore.delete(path);
        } on FileSystemException {
          // A temporary file may already have been removed by Android.
        }
      }
    }
  }
}

class MlKitPhotoOcrService implements PhotoOcrService {
  @override
  Future<String> recognize(String path) async {
    // Polish is covered by ML Kit's bundled Latin-script recognizer.
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = InputImage.fromFilePath(path);
      return (await recognizer.processImage(image)).text;
    } finally {
      await recognizer.close();
    }
  }
}

class FileTemporaryPhotoStore implements TemporaryPhotoStore {
  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
