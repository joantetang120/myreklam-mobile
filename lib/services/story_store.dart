import 'package:flutter/material.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/services/story_service.dart';

class StoryStore {
  StoryStore._internal();
  static final StoryStore _instance = StoryStore._internal();
  factory StoryStore() => _instance;

  final StoryService _service = StoryService();

  // Own stories
  final List<StoryModel> _myStories = [];
  final ValueNotifier<List<StoryModel>> myStoriesNotifier =
      ValueNotifier<List<StoryModel>>(<StoryModel>[]);

  // Feed (all users grouped)
  final List<StoryUserGroup> _feed = [];
  final ValueNotifier<List<StoryUserGroup>> feedNotifier =
      ValueNotifier<List<StoryUserGroup>>(<StoryUserGroup>[]);

  // Legacy accessor
  List<StoryModel> get stories => List.unmodifiable(_myStories);

  /// Fetch the story feed from the API.
  Future<void> loadFeed() async {
    try {
      final groups = await _service.getFeed();
      _feed
        ..clear()
        ..addAll(groups);
      feedNotifier.value = List.unmodifiable(_feed);

      // Also update own stories from the feed
      final ownGroup = groups.where((g) => g.isOwn).toList();
      if (ownGroup.isNotEmpty) {
        _myStories
          ..clear()
          ..addAll(ownGroup.first.stories);
        _notifyMine();
      }
    } catch (e) {
      debugPrint('StoryStore.loadFeed error: $e');
    }
  }

  /// Fetch own stories with viewer details.
  Future<void> loadMyStories() async {
    try {
      final list = await _service.getMyStories();
      _myStories
        ..clear()
        ..addAll(list);
      _notifyMine();
    } catch (e) {
      debugPrint('StoryStore.loadMyStories error: $e');
    }
  }

  /// Add a story that was just uploaded.
  void addStory(StoryModel story) {
    _myStories.insert(0, story);
    _notifyMine();
    // Reload the feed so the dashboard updates
    loadFeed();
  }

  /// Remove a story locally after deletion.
  void removeStory(int storyId) {
    _myStories.removeWhere((s) => s.id == storyId);
    _notifyMine();
    loadFeed();
  }

  void clear() {
    _myStories.clear();
    _feed.clear();
    _notifyMine();
    feedNotifier.value = List.unmodifiable(_feed);
  }

  void _notifyMine() {
    myStoriesNotifier.value = List.unmodifiable(_myStories);
  }
}
