import 'package:shared_preferences/shared_preferences.dart';
import 'package:myreklam/utils/user_session.dart';

class ReactionCacheService {
  static SharedPreferences? _prefs;
  static const _prefix = 'rxn_';
  static const _countPrefix = 'rxn_cnt_';
  static const _commentCountPrefix = 'cmt_cnt_';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Include user ID in cache key to prevent cross-user pollution
  static String _userPrefix() {
    final userId = UserSession().id ?? 'anonymous';
    return '${userId}_';
  }

  static String _key(String apiSlug, String entityId) =>
      '$_prefix${_userPrefix()}${apiSlug}_$entityId';

  static String _countKey(String apiSlug, String entityId) =>
      '$_countPrefix${_userPrefix()}${apiSlug}_$entityId';

  static void save(String apiSlug, String entityId, String? reaction) {
    _prefs?.setString(_key(apiSlug, entityId), reaction ?? 'none');
  }

  static void saveCount(String apiSlug, String entityId, int count) {
    _prefs?.setInt(_countKey(apiSlug, entityId), count);
  }

  static bool isCached(String apiSlug, String entityId) =>
      _prefs?.containsKey(_key(apiSlug, entityId)) ?? false;

  static String? load(String apiSlug, String entityId) {
    final v = _prefs?.getString(_key(apiSlug, entityId));
    if (v == null) return null;
    if (v == 'none') return null;
    return v;
  }

  static int? loadCount(String apiSlug, String entityId) =>
      _prefs?.getInt(_countKey(apiSlug, entityId));

  static String _commentCountKey(String apiSlug, String entityId) =>
      '$_commentCountPrefix${_userPrefix()}${apiSlug}_$entityId';

  static void saveCommentsCount(String apiSlug, String entityId, int count) {
    _prefs?.setInt(_commentCountKey(apiSlug, entityId), count);
  }

  static int? loadCommentsCount(String apiSlug, String entityId) =>
      _prefs?.getInt(_commentCountKey(apiSlug, entityId));

  /// Clear all cached reactions for the current user
  static Future<void> clearCurrentUserCache() async {
    if (_prefs == null) return;
    final userPrefix = _userPrefix();
    final keysToRemove = _prefs!.getKeys().where((key) {
      return key.contains('$_prefix$userPrefix') ||
          key.contains('$_countPrefix$userPrefix') ||
          key.contains('$_commentCountPrefix$userPrefix');
    }).toList();
    for (final key in keysToRemove) {
      await _prefs!.remove(key);
    }
  }
}
