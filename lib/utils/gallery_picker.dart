import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class GalleryMedia {
  final String path;
  final String name;
  final Uint8List? bytes;
  final String? extension;
  final int size;

  GalleryMedia({
    required this.path,
    required this.name,
    this.bytes,
    this.extension,
    this.size = 0,
  });
}

class GalleryPicker {
  static final ImagePicker _picker = ImagePicker();

  static Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // On iOS, image_picker uses PHPicker (iOS 14+) which needs NO photo
      // permission. Pre-checking Permission.photos here wrongly blocks picking
      // if the user previously denied access — so let image_picker handle it.
      return true;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (await Permission.photos.request().isGranted) return true;
      if (await Permission.storage.request().isGranted) return true;
      if (await Permission.manageExternalStorage.request().isGranted) return true;
      return false;
    }

    return true;
  }

  static Future<List<GalleryMedia>?> pickImagesFromGallery({
    bool allowMultiple = true,
  }) async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) return null;

    try {
      // imageQuality forces image_picker to re-encode the picked image as JPEG.
      // This converts iPhone HEIC/HEIF (and other formats Flutter can't decode)
      // to a universally displayable JPEG, so uploads pass backend validation
      // and render on every screen (cards, detail, editor).
      const int quality = 88;
      if (allowMultiple) {
        final files = await _picker.pickMultiImage(imageQuality: quality);
        if (files.isEmpty) return null;
        return await Future.wait(files.map(_toGalleryMedia));
      } else {
        final file = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: quality,
        );
        if (file == null) return null;
        return [await _toGalleryMedia(file)];
      }
    } catch (e) {
      debugPrint('GalleryPicker error: $e');
      return null;
    }
  }

  static Future<GalleryMedia?> pickVideoFromGallery() async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) return null;

    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return null;
      return await _toGalleryMedia(file);
    } catch (e) {
      debugPrint('GalleryPicker error: $e');
      return null;
    }
  }

  static Future<GalleryMedia> _toGalleryMedia(XFile xfile) async {
    final path = xfile.path;
    final name = path.split(Platform.pathSeparator).last;
    final ext = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : null;
    int fileSize = 0;
    Uint8List? bytes;
    try {
      final file = File(path);
      fileSize = await file.length();
    } catch (_) {}
    try {
      bytes = await xfile.readAsBytes();
    } catch (_) {}
    return GalleryMedia(
      path: path,
      name: name,
      bytes: bytes,
      extension: ext,
      size: fileSize,
    );
  }
}
