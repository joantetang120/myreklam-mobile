import 'package:flutter/material.dart';
import 'package:myreklam/models/story_model.dart';

class StoryStore {
  StoryStore._internal();
  static final StoryStore _instance = StoryStore._internal();
  factory StoryStore() => _instance;

  final List<StoryModel> _stories = [];
  final ValueNotifier<List<StoryModel>> storiesNotifier =
      ValueNotifier<List<StoryModel>>(<StoryModel>[]);

  List<StoryModel> get stories => List.unmodifiable(_stories);

  void addStory(StoryModel story) {
    _stories.add(story);
    _notify();
  }

  void replaceStories(List<StoryModel> newStories) {
    _stories
      ..clear()
      ..addAll(newStories);
    _notify();
  }

  void clear() {
    _stories.clear();
    _notify();
  }

  void _notify() {
    storiesNotifier.value = List.unmodifiable(_stories);
  }
}
