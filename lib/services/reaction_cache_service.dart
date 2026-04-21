import 'package:shared_preferences/shared_preferences.dart';

class ReactionCacheService {
  static SharedPreferences? _prefs;
  static const _prefix = 'rxn_';
  static const _countPrefix = 'rxn_cnt_';
  static const _commentCountPrefix = 'cmt_cnt_';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String _key(String apiSlug, String entityId) =>
      '$_prefix${apiSlug}_$entityId';

  static String _countKey(String apiSlug, String entityId) =>
      '$_countPrefix${apiSlug}_$entityId';

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
      '$_commentCountPrefix${apiSlug}_$entityId';

  static void saveCommentsCount(String apiSlug, String entityId, int count) {
    _prefs?.setInt(_commentCountKey(apiSlug, entityId), count);
  }

  static int? loadCommentsCount(String apiSlug, String entityId) =>
      _prefs?.getInt(_commentCountKey(apiSlug, entityId));
}
