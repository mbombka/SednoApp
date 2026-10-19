import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/photo/data/local_photo_image_service.dart';

import '../support/test_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'unchanged selection returns original photo without another file',
    () async {
      final image = await testPhoto();
      addTearDown(image.dispose);
      final result = await LocalPhotoImageService().crop(
        'original.jpg',
        image,
        const ui.Rect.fromLTWH(0, 0, 1, 1),
      );
      expect(result, 'original.jpg');
    },
  );

  test('crop saves only selected pixels at original resolution', () async {
    final directory = await Directory.systemTemp.createTemp('sedno-crop-test-');
    addTearDown(() => directory.delete(recursive: true));
    final image = await testPhoto();
    addTearDown(image.dispose);
    final service = LocalPhotoImageService();
    final path = await service.crop(
      '${directory.path}/photo.jpg',
      image,
      const ui.Rect.fromLTRB(0.5, 0.25, 1, 0.75),
    );
    final cropped = await service.load(path);
    addTearDown(cropped.dispose);
    expect(cropped.width, 50);
    expect(cropped.height, 40);
    final pixels = (await cropped.toByteData())!.buffer.asUint8List();
    for (var offset = 0; offset < pixels.length; offset += 4) {
      expect(pixels.sublist(offset, offset + 4), [0, 255, 0, 255]);
    }
  });

  test('rounds outward at fractional pixel boundaries', () async {
    final directory = await Directory.systemTemp.createTemp('sedno-crop-test-');
    addTearDown(() => directory.delete(recursive: true));
    final image = await testPhoto();
    addTearDown(image.dispose);
    final service = LocalPhotoImageService();
    final path = await service.crop(
      '${directory.path}/photo.jpg',
      image,
      const ui.Rect.fromLTRB(0.501, 0.251, 0.999, 0.749),
    );
    final cropped = await service.load(path);
    addTearDown(cropped.dispose);
    expect(cropped.width, 50);
    expect(cropped.height, 40);
  });
}
