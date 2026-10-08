import 'dart:io';

import 'package:video_compress/video_compress.dart';

class VideoCompressionResult {
  final File file;
  final int originalBytes;
  final int compressedBytes;

  const VideoCompressionResult({
    required this.file,
    required this.originalBytes,
    required this.compressedBytes,
  });

  int get savedBytes => originalBytes - compressedBytes;
  bool get wasCompressed => savedBytes > 0;
}

class VideoCompressionService {
  static const int compressionThreshold = 3 * 1024 * 1024;

  static Future<VideoCompressionResult> compress(File source) async {
    final originalBytes = await source.length();
    if (originalBytes < compressionThreshold ||
        !(Platform.isAndroid || Platform.isIOS)) {
      return VideoCompressionResult(
        file: source,
        originalBytes: originalBytes,
        compressedBytes: originalBytes,
      );
    }

    try {
      final info = await VideoCompress.compressVideo(
        source.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
      );
      final path = info?.path;
      if (path == null || path.isEmpty) {
        throw const FileSystemException('Aucune vidéo compressée produite');
      }
      final compressed = File(path);
      final compressedBytes = await compressed.length();
      if (compressedBytes <= 0 || compressedBytes >= originalBytes) {
        return VideoCompressionResult(
          file: source,
          originalBytes: originalBytes,
          compressedBytes: originalBytes,
        );
      }
      return VideoCompressionResult(
        file: compressed,
        originalBytes: originalBytes,
        compressedBytes: compressedBytes,
      );
    } catch (_) {
      return VideoCompressionResult(
        file: source,
        originalBytes: originalBytes,
        compressedBytes: originalBytes,
      );
    }
  }
}
