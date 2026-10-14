import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simplifier_app/features/photo/data/local_photo_text_repository.dart';
import 'package:simplifier_app/features/photo/domain/photo_text_repository.dart';

class FakeCapture implements PhotoCaptureService {
  FakeCapture(this.result);
  final String? result;
  Object? error;
  @override
  Future<String?> capture() async {
    if (error != null) throw error!;
    return result;
  }
}

class FakeCrop implements PhotoCropService {
  FakeCrop(this.result);
  final String? result;
  Object? error;
  String? input;
  @override
  Future<String?> crop(String path) async {
    input = path;
    if (error != null) throw error!;
    return result;
  }
}

class FakeOcr implements PhotoOcrService {
  FakeOcr(this.result);
  final String result;
  Object? error;
  String? input;
  @override
  Future<String> recognize(String path) async {
    input = path;
    if (error != null) throw error!;
    return result;
  }
}

class FakeTemporaryStore implements TemporaryPhotoStore {
  final deleted = <String>[];
  @override
  Future<void> delete(String path) async => deleted.add(path);
}

class DeniedImagePicker extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    throw PlatformException(
      code: 'camera_access_denied',
      message: 'private detail',
    );
  }
}

void main() {
  test('maps Android camera permission denial', () async {
    final capture = ImagePickerCaptureService(picker: DeniedImagePicker());
    await expectLater(
      capture.capture(),
      throwsA(isA<CameraPermissionDenied>()),
    );
  });

  test('deletes a real temporary file', () async {
    final directory = await Directory.systemTemp.createTemp(
      'simplyfi-photo-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/capture.jpg');
    await file.writeAsBytes([1, 2, 3]);

    await FileTemporaryPhotoStore().delete(file.path);
    expect(await file.exists(), isFalse);
  });

  test('recognizes cropped photo and deletes both temporary files', () async {
    final capture = FakeCapture('capture.jpg');
    final crop = FakeCrop('crop.jpg');
    final ocr = FakeOcr('Zażółć gęślą jaźń');
    final files = FakeTemporaryStore();
    final repository = LocalPhotoTextRepository(
      captureService: capture,
      cropService: crop,
      ocrService: ocr,
      temporaryPhotoStore: files,
    );

    expect(await repository.recognizeFromCamera(), 'Zażółć gęślą jaźń');
    expect(crop.input, 'capture.jpg');
    expect(ocr.input, 'crop.jpg');
    expect(files.deleted, containsAll(['capture.jpg', 'crop.jpg']));
  });

  test('camera cancellation does not crop or create a file', () async {
    final crop = FakeCrop('crop.jpg');
    final files = FakeTemporaryStore();
    final repository = LocalPhotoTextRepository(
      captureService: FakeCapture(null),
      cropService: crop,
      ocrService: FakeOcr('tekst'),
      temporaryPhotoStore: files,
    );

    expect(await repository.recognizeFromCamera(), isNull);
    expect(crop.input, isNull);
    expect(files.deleted, isEmpty);
  });

  test('crop cancellation deletes captured photo', () async {
    final files = FakeTemporaryStore();
    final repository = LocalPhotoTextRepository(
      captureService: FakeCapture('capture.jpg'),
      cropService: FakeCrop(null),
      ocrService: FakeOcr('tekst'),
      temporaryPhotoStore: files,
    );

    expect(await repository.recognizeFromCamera(), isNull);
    expect(files.deleted, ['capture.jpg']);
  });

  test('permission denial returns a typed failure with no files', () async {
    final capture = FakeCapture(null)..error = const CameraPermissionDenied();
    final files = FakeTemporaryStore();
    final repository = LocalPhotoTextRepository(
      captureService: capture,
      cropService: FakeCrop(null),
      ocrService: FakeOcr(''),
      temporaryPhotoStore: files,
    );

    await expectLater(
      repository.recognizeFromCamera(),
      throwsA(isA<CameraPermissionDenied>()),
    );
    expect(files.deleted, isEmpty);
  });

  test('OCR failure deletes both temporary photos', () async {
    final files = FakeTemporaryStore();
    final ocr = FakeOcr('')..error = StateError('private detail');
    final repository = LocalPhotoTextRepository(
      captureService: FakeCapture('capture.jpg'),
      cropService: FakeCrop('crop.jpg'),
      ocrService: ocr,
      temporaryPhotoStore: files,
    );

    await expectLater(repository.recognizeFromCamera(), throwsStateError);
    expect(files.deleted, containsAll(['capture.jpg', 'crop.jpg']));
  });

  test('crop failure deletes captured photo', () async {
    final files = FakeTemporaryStore();
    final crop = FakeCrop(null)..error = StateError('private detail');
    final repository = LocalPhotoTextRepository(
      captureService: FakeCapture('capture.jpg'),
      cropService: crop,
      ocrService: FakeOcr(''),
      temporaryPhotoStore: files,
    );

    await expectLater(repository.recognizeFromCamera(), throwsStateError);
    expect(files.deleted, ['capture.jpg']);
  });
}
