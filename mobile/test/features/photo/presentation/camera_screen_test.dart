import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/photo/domain/photo_text_repository.dart';
import 'package:sedno_app/features/photo/presentation/camera_screen.dart';
import 'package:sedno_app/features/photo/presentation/camera_view_model.dart';

import '../support/fake_camera.dart';

void main() {
  testWidgets(
    'taking a photo returns immediately without a confirmation screen',
    (tester) async {
      final camera = FakeCamera();
      final model = CameraViewModel(camera);
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => CameraScreen(model: model)),
                );
              },
              child: const Text('Aparat'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Aparat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Zrób zdjęcie'));
      await tester.pumpAndSettle();
      expect(result, 'photo.jpg');
      expect(camera.captures, 1);
      expect(find.byType(CameraScreen), findsNothing);
      expect(camera.releases, 1);
    },
  );

  testWidgets('permission error and retry remain visible with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final camera = FakeCamera()..error = const CameraPermissionDenied();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: CameraScreen(model: CameraViewModel(camera)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Brak dostępu do aparatu'), findsOneWidget);
    expect(find.text('Spróbuj ponownie'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
  });
}
