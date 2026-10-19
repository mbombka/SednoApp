import 'dart:io';
import 'dart:ui' as ui;

abstract interface class PhotoImageService {
  Future<ui.Image> load(String path);
  Future<String> crop(String path, ui.Image image, ui.Rect selection);
}

class LocalPhotoImageService implements PhotoImageService {
  @override
  Future<ui.Image> load(String path) async {
    final codec = await ui.instantiateImageCodec(
      await File(path).readAsBytes(),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  Future<String> crop(String path, ui.Image image, ui.Rect selection) async {
    if (selection == const ui.Rect.fromLTWH(0, 0, 1, 1)) return path;
    // Round outward so no selected text disappears at the crop boundary.
    final left = (selection.left * image.width).floor();
    final top = (selection.top * image.height).floor();
    final right = (selection.right * image.width).ceil();
    final bottom = (selection.bottom * image.height).ceil();
    final width = right - left;
    final height = bottom - top;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTRB(
        left.toDouble(),
        top.toDouble(),
        right.toDouble(),
        bottom.toDouble(),
      ),
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint(),
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(width, height);
    final output = File('$path.sedno-crop.png');
    try {
      final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Image encoding failed');
      await output.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return output.path;
    } catch (_) {
      if (await output.exists()) await output.delete();
      rethrow;
    } finally {
      cropped.dispose();
      picture.dispose();
    }
  }
}
