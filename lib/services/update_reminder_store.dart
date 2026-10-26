import 'package:shared_preferences/shared_preferences.dart';

/// A reminder belongs to a release, not to the account currently signed in.
class UpdateReminderStore {
  UpdateReminderStore({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const delay = Duration(hours: 24);
  final DateTime Function() _now;
  final Map<String, DateTime> _memory = {};

  String _key(String version) => 'myreklam.ios-update-reminder.v1.$version';

  Future<bool> shouldPrompt(String version) async {
    DateTime? last = _memory[version];
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
      final stored = prefs.getInt(_key(version));
      if (stored != null) {
        final saved = DateTime.fromMillisecondsSinceEpoch(stored);
        if (last == null || saved.isAfter(last)) last = saved;
      }
    } catch (_) {
      // A preferences failure must never prevent access to the application.
    }
    if (last == null) return true;
    final elapsed = _now().difference(last);
    // A clock correction must not hide the reminder indefinitely.
    return elapsed.isNegative || elapsed >= delay;
  }

  Future<void> postpone(String version) async {
    final now = _now();
    _memory[version] = now;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
      await prefs
          .setInt(_key(version), now.millisecondsSinceEpoch)
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // The in-memory reminder still prevents a prompt loop during this run.
    }
  }
}
