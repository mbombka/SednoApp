import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/photo/domain/photo_text_repository.dart';
import 'package:sedno_app/features/photo/presentation/camera_view_model.dart';

import '../support/fake_camera.dart';

void main() {
  test(
    'one capture returns the photo directly and blocks repeated taps',
    () async {
      final camera = FakeCamera()..picture = Completer<String>();
      final model = CameraViewModel(camera);
      addTearDown(model.dispose);
      await model.setActive(true);
      final capture = model.takePicture();
      expect(model.busy, isTrue);
      expect(await model.takePicture(), isNull);
      camera.picture!.complete('photo.jpg');
      expect(await capture, 'photo.jpg');
      expect(camera.captures, 1);
    },
  );

  test('permission denial has a Polish message and blocks capture', () async {
    final camera = FakeCamera()..error = const CameraPermissionDenied();
    final model = CameraViewModel(camera);
    addTearDown(model.dispose);
    await model.setActive(true);
    expect(model.ready, isFalse);
    expect(model.message, contains('Brak dostępu do aparatu'));
    expect(await model.takePicture(), isNull);
    expect(camera.captures, 0);
  });

  test(
    'backgrounding releases the camera and resuming reinitializes it',
    () async {
      final camera = FakeCamera();
      final model = CameraViewModel(camera);
      addTearDown(model.dispose);
      await model.setActive(true);
      await model.setActive(false);
      expect(model.ready, isFalse);
      expect(camera.releases, 1);
      await model.setActive(true);
      expect(model.ready, isTrue);
      expect(camera.starts, 2);
    },
  );

  test(
    'permission lifecycle changes do not expose a stale initialization',
    () async {
      final camera = FakeCamera()..initialization = Completer<void>();
      final model = CameraViewModel(camera);
      addTearDown(model.dispose);
      final first = model.setActive(true);
      await Future<void>.delayed(Duration.zero);
      final inactive = model.setActive(false);
      final resumed = model.setActive(true);
      camera.initialization!.complete();
      await first;
      expect(model.ready, isFalse);
      await inactive;
      await resumed;
      expect(model.ready, isTrue);
    },
  );

  test('photo completed after leaving the screen is deleted', () async {
    final directory = await Directory.systemTemp.createTemp(
      'sedno-camera-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = await File('${directory.path}/late.jpg').writeAsBytes([1, 2]);
    final camera = FakeCamera()..picture = Completer<String>();
    final model = CameraViewModel(camera);
    await model.setActive(true);
    final capture = model.takePicture();
    model.dispose();
    camera.picture!.complete(file.path);
    expect(await capture, isNull);
    expect(await file.exists(), isFalse);
  });
}
