import 'dart:ui' as ui;

Future<ui.Image> testPhoto() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 100, 80),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(50, 0, 50, 80),
    ui.Paint()..color = const ui.Color(0xFF00FF00),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(100, 80);
  } finally {
    picture.dispose();
  }
}
