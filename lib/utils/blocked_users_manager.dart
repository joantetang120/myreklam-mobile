import 'package:shared_preferences/shared_preferences.dart';
import 'package:myreklam/services/profile_service.dart';

class BlockedUsersManager {
  static const _key = 'blocked_user_ids';

  static Future<Set<String>> getBlockedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  /// Block a user locally and notify backend via report
  static Future<void> blockUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? []).toSet();
    current.add(userId);
    await prefs.setStringList(_key, current.toList());

    // Notify backend via existing report endpoint
    try {
      await ProfileService().reportUser(userId, 'block');
    } catch (_) {
      // Silently ignore — local block is already saved
    }
  }

  static Future<void> removeBlockedId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? []).toSet();
    current.remove(userId);
    await prefs.setStringList(_key, current.toList());
  }

  static Future<bool> isBlocked(String userId) async {
    final blocked = await getBlockedIds();
    return blocked.contains(userId);
  }

  /// Filter a list of items by removing blocked users
  static Future<List<Map<String, dynamic>>> filterBlocked(
    List<Map<String, dynamic>> items, {
    String userIdKey = 'user_id',
  }) async {
    final blocked = await getBlockedIds();
    if (blocked.isEmpty) return items;
    return items.where((item) {
      final id =
          item[userIdKey]?.toString() ??
          item['user']?['id']?.toString() ??
          item['author']?['id']?.toString() ??
          item['owner_id']?.toString();
      return id == null || !blocked.contains(id);
    }).toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
