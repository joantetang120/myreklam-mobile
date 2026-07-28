import 'package:flutter/foundation.dart';
import 'package:myreklam/services/token_storage.dart';

/// Holds the active account-delegation state (when a manager is acting as a
/// managed account) for the global banner and UI permission checks.
///
/// Token swapping itself lives in [TokenStorage]; this only mirrors the state
/// and notifies listeners. Server-side disconnect is done by the caller via
/// DelegationService before [exitLocal].
class DelegationManager extends ChangeNotifier {
  DelegationManager._();
  static final DelegationManager instance = DelegationManager._();

  bool _active = false;
  int _ownerId = 0;
  String _ownerName = '';
  String? _ownerAvatar;
  List<String> _permissions = const [];

  bool get isActive => _active;
  int get ownerId => _ownerId;
  String get ownerName => _ownerName;
  String? get ownerAvatar => _ownerAvatar;
  List<String> get permissions => _permissions;

  /// True if the current (possibly delegated) session may perform [permission].
  /// The real account owner is never restricted.
  bool can(String permission) => !_active || _permissions.contains(permission);

  /// Load persisted delegation state at app startup.
  Future<void> init() async {
    final info = await TokenStorage.getDelegationInfo();
    if (info != null) {
      _active = true;
      _ownerId = info['owner_id'] as int? ?? 0;
      _ownerName = info['owner_name'] as String? ?? '';
      _ownerAvatar = info['owner_avatar'] as String?;
      _permissions = List<String>.from(
        info['permissions'] as List? ?? const [],
      );
    } else {
      _reset();
    }
    notifyListeners();
  }

  /// Activate delegation from a /delegations/{id}/connect response.
  Future<void> enter(Map<String, dynamic> connectResponse) async {
    final owner = Map<String, dynamic>.from(connectResponse['owner'] ?? {});
    final perms = (connectResponse['permissions'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    await TokenStorage.enterDelegation(
      delegatedAccessToken: connectResponse['access_token'].toString(),
      ownerId: int.tryParse(owner['id']?.toString() ?? '0') ?? 0,
      ownerName: owner['name']?.toString() ?? 'Compte',
      ownerAvatar: owner['avatar']?.toString(),
      permissions: perms,
    );

    _active = true;
    _ownerId = int.tryParse(owner['id']?.toString() ?? '0') ?? 0;
    _ownerName = owner['name']?.toString() ?? 'Compte';
    _ownerAvatar = owner['avatar']?.toString();
    _permissions = perms;
    notifyListeners();
  }

  /// Restore the manager's own session locally and clear delegation state.
  Future<void> exitLocal() async {
    await TokenStorage.exitDelegation();
    _reset();
    notifyListeners();
  }

  void _reset() {
    _active = false;
    _ownerId = 0;
    _ownerName = '';
    _ownerAvatar = null;
    _permissions = const [];
  }
}
