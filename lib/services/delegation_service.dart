import 'package:myreklam/models/delegation.dart';
import 'package:myreklam/services/api_client.dart';

class ManagersResult {
  final List<Delegation> managers;
  final bool nextSeatIsPaid;
  final double seatPrice;

  ManagersResult({
    required this.managers,
    required this.nextSeatIsPaid,
    required this.seatPrice,
  });
}

class UserSearchResult {
  final DelegationUser user;
  final bool alreadyAdded;

  UserSearchResult({required this.user, required this.alreadyAdded});
}

class DelegationService {
  static final DelegationService _instance = DelegationService._internal();
  factory DelegationService() => _instance;
  DelegationService._internal();

  final ApiClient _api = ApiClient();

  /// Managers the current user (owner) has granted access to.
  Future<ManagersResult> getMyManagers() async {
    final res = await _api.authenticatedGet('/delegations');
    final list = (res['data'] as List? ?? [])
        .map((e) => Delegation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return ManagersResult(
      managers: list,
      nextSeatIsPaid: res['next_seat_is_paid'] == true,
      seatPrice: (res['seat_price'] as num?)?.toDouble() ?? 5.0,
    );
  }

  /// Accounts the current user can manage.
  Future<List<Delegation>> getManagedAccounts() async {
    final res = await _api.authenticatedGet('/delegations/received');
    return (res['data'] as List? ?? [])
        .map((e) => Delegation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Look up an existing user by email to add as a manager.
  Future<UserSearchResult> searchUser(String email) async {
    final res = await _api
        .authenticatedGet('/delegations/search-user?email=${Uri.encodeComponent(email)}');
    return UserSearchResult(
      user: DelegationUser.fromJson(Map<String, dynamic>.from(res['data'])),
      alreadyAdded: res['already_added'] == true,
    );
  }

  /// Add a manager. [paymentIntentId] is required for paid (2nd+) seats.
  Future<Delegation> addManager({
    required int managerId,
    required List<String> permissions,
    String? paymentIntentId,
  }) async {
    final res = await _api.authenticatedPost('/delegations', body: {
      'manager_id': managerId,
      'permissions': permissions,
      if (paymentIntentId != null) 'payment_intent_id': paymentIntentId,
    });
    return Delegation.fromJson(Map<String, dynamic>.from(res['data']));
  }

  Future<Delegation> updatePermissions(
    int delegationId,
    List<String> permissions,
  ) async {
    final res = await _api.authenticatedPut(
      '/delegations/$delegationId',
      body: {'permissions': permissions},
    );
    return Delegation.fromJson(Map<String, dynamic>.from(res['data']));
  }

  Future<void> removeManager(int delegationId) async {
    await _api.authenticatedDelete('/delegations/$delegationId');
  }

  /// Connect to a managed account. Returns the delegated session payload
  /// ({access_token, permissions, owner}).
  Future<Map<String, dynamic>> connect(int delegationId) async {
    return await _api.authenticatedPost('/delegations/$delegationId/connect');
  }

  /// Revoke the active delegated token on the server (best-effort).
  Future<void> disconnect() async {
    try {
      await _api.authenticatedPost('/delegations/disconnect');
    } catch (_) {
      // Ignore — local session restore handles the client side.
    }
  }
}
