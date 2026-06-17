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
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
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
      if (allowMultiple) {
        final files = await _picker.pickMultiImage();
        if (files.isEmpty) return null;
        return await Future.wait(files.map(_toGalleryMedia));
      } else {
        final file = await _picker.pickImage(source: ImageSource.gallery);
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
