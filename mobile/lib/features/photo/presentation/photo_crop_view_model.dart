import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/photo/data/local_photo_image_service.dart';

enum CropCorner { topLeft, topRight, bottomLeft, bottomRight }

class PhotoCropViewModel extends ChangeNotifier {
  PhotoCropViewModel({required this.path, required this.images});

  final String path;
  final PhotoImageService images;
  ui.Image? image;
  ui.Rect selection = const ui.Rect.fromLTWH(0, 0, 1, 1);
  bool busy = false;
  String? message;
  bool _disposed = false;

  Future<void> load() async {
    try {
      final loaded = await images.load(path);
      if (_disposed) {
        loaded.dispose();
        return;
      }
      image = loaded;
    } catch (_) {
      message = 'Nie udało się otworzyć zdjęcia. Zrób nowe zdjęcie.';
    }
    if (!_disposed) notifyListeners();
  }

  void moveCorner(CropCorner corner, ui.Offset delta) {
    if (busy) return;
    const minSize = 0.05;
    final left =
        corner == CropCorner.topLeft || corner == CropCorner.bottomLeft;
    final top = corner == CropCorner.topLeft || corner == CropCorner.topRight;
    selection = ui.Rect.fromLTRB(
      left
          ? (selection.left + delta.dx).clamp(0, selection.right - minSize)
          : selection.left,
      top
          ? (selection.top + delta.dy).clamp(0, selection.bottom - minSize)
          : selection.top,
      left
          ? selection.right
          : (selection.right + delta.dx).clamp(selection.left + minSize, 1),
      top
          ? selection.bottom
          : (selection.bottom + delta.dy).clamp(selection.top + minSize, 1),
    );
    notifyListeners();
  }

  Future<String?> read() async {
    final loaded = image;
    if (loaded == null || busy || _disposed) return null;
    busy = true;
    message = null;
    notifyListeners();
    // Keep the image alive until encoding completes even if the route closes.
    final retained = loaded.clone();
    try {
      final output = await images.crop(path, retained, selection);
      if (_disposed) {
        if (output != path) {
          try {
            await File(output).delete();
          } on FileSystemException {
            // Already removed by the operating system.
          }
        }
        return null;
      }
      return output;
    } catch (_) {
      message = 'Nie udało się przygotować zdjęcia. Spróbuj ponownie.';
      return null;
    } finally {
      retained.dispose();
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    image?.dispose();
    super.dispose();
  }
}
