import 'package:flutter/material.dart';
import 'package:sedno_app/features/photo/data/camera_device_service.dart';
import 'package:sedno_app/features/photo/data/local_photo_image_service.dart';
import 'package:sedno_app/features/photo/data/local_photo_text_repository.dart';
import 'package:sedno_app/features/photo/presentation/camera_screen.dart';
import 'package:sedno_app/features/photo/presentation/camera_view_model.dart';
import 'package:sedno_app/features/photo/presentation/photo_crop_screen.dart';
import 'package:sedno_app/features/photo/presentation/photo_crop_view_model.dart';

class PhotoNavigationService implements PhotoCaptureService, PhotoCropService {
  PhotoNavigationService(this.context);
  final BuildContext Function() context;

  @override
  Future<String?> capture() {
    final model = CameraViewModel(AndroidCameraDeviceService());
    return Navigator.of(context()).push<String>(
      MaterialPageRoute(builder: (_) => CameraScreen(model: model)),
    );
  }

  @override
  Future<String?> crop(String path) {
    final model = PhotoCropViewModel(
      path: path,
      images: LocalPhotoImageService(),
    );
    return Navigator.of(context()).push<String>(
      MaterialPageRoute(builder: (_) => PhotoCropScreen(model: model)),
    );
  }
}
