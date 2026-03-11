import 'dart:typed_data';

class StoryModel {
  final Uint8List imageBytes;
  final String caption;
  final DateTime timestamp;

  StoryModel({
    required this.imageBytes,
    required this.caption,
    required this.timestamp,
  });
}
