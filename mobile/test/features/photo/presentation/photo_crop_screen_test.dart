import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/photo/data/local_photo_image_service.dart';
import 'package:sedno_app/features/photo/presentation/photo_crop_screen.dart';
import 'package:sedno_app/features/photo/presentation/photo_crop_view_model.dart';

import '../support/test_photo.dart';

class FakeImages implements PhotoImageService {
  FakeImages(this.image);
  final ui.Image image;
  ui.Rect? selected;
  Completer<String>? output;
  int reads = 0;
  @override
  Future<ui.Image> load(String path) async => image;
  @override
  Future<String> crop(String path, ui.Image image, ui.Rect selection) async {
    selected = selection;
    reads++;
    return output == null ? path : await output!.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('corner movement stays inside the photo and cannot invert the crop', () {
    final model = PhotoCropViewModel(
      path: 'photo.jpg',
      images: LocalPhotoImageService(),
    );
    addTearDown(model.dispose);
    model.moveCorner(CropCorner.topLeft, const Offset(-2, -2));
    expect(model.selection, const Rect.fromLTWH(0, 0, 1, 1));
    model.moveCorner(CropCorner.topLeft, const Offset(2, 2));
    expect(model.selection.left, closeTo(0.95, 0.0001));
    expect(model.selection.top, closeTo(0.95, 0.0001));
    model.moveCorner(CropCorner.bottomRight, const Offset(-2, -2));
    expect(model.selection.width, closeTo(0.05, 0.0001));
    expect(model.selection.height, closeTo(0.05, 0.0001));
  });

  testWidgets('one Uprość button reads the whole photo by default', (
    tester,
  ) async {
    final image = await tester.runAsync(testPhoto);
    final images = FakeImages(image!);
    final model = PhotoCropViewModel(path: 'photo.jpg', images: images);
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => PhotoCropScreen(model: model),
                ),
              );
            },
            child: const Text('Otwórz'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Otwórz'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Uprość'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsNothing);
    await tester.tap(find.text('Uprość'));
    await tester.pumpAndSettle();
    expect(result, 'photo.jpg');
    expect(images.selected, const Rect.fromLTWH(0, 0, 1, 1));
    expect(images.reads, 1);
  });

  testWidgets(
    'dragging a corner changes the selection; dragging the photo does not',
    (tester) async {
      final image = await tester.runAsync(testPhoto);
      final model = PhotoCropViewModel(
        path: 'photo.jpg',
        images: FakeImages(image!),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PhotoCropScreen(model: model),
        ),
      );
      await tester.pumpAndSettle();
      final photo = find.byType(RawImage);
      final before = tester.getRect(photo);
      await tester.drag(photo, const Offset(50, 50));
      await tester.pump();
      expect(model.selection, const Rect.fromLTWH(0, 0, 1, 1));
      expect(tester.getRect(photo), before);
      final corner = find.byKey(const ValueKey(CropCorner.topLeft));
      expect(tester.getSize(corner), const Size(48, 48));
      await tester.drag(corner, const Offset(65, 65));
      await tester.pump();
      expect(model.selection.left, greaterThan(0));
      expect(model.selection.top, greaterThan(0));
      expect(tester.getRect(photo), before);
      final semantics = tester.ensureSemantics();
      final node = tester.getSemantics(
        find.bySemanticsLabel('Lewy górny róg ramki'),
      );
      expect(
        node.getSemanticsData().hasAction(ui.SemanticsAction.increase),
        isTrue,
      );
      expect(
        node.getSemanticsData().hasAction(ui.SemanticsAction.decrease),
        isTrue,
      );
      semantics.dispose();
    },
  );

  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets('supports large text at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final image = await tester.runAsync(testPhoto);
      final model = PhotoCropViewModel(
        path: 'photo.jpg',
        images: FakeImages(image!),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: PhotoCropScreen(model: model),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  }

  test(
    'closing while encoding deletes a late crop and blocks repeated reads',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sedno-late-crop-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final cropped = await File('${directory.path}/crop.png')
          .writeAsBytes([1]);
      final images = FakeImages(await testPhoto())
        ..output = Completer<String>();
      final model = PhotoCropViewModel(
        path: '${directory.path}/original.jpg',
        images: images,
      );
      await model.load();
      final reading = model.read();
      expect(await model.read(), isNull);
      model.dispose();
      images.output!.complete(cropped.path);
      expect(await reading, isNull);
      expect(await cropped.exists(), isFalse);
      expect(images.reads, 1);
    },
  );
}
