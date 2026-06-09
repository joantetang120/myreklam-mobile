import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/utils/user_session.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final ApiClient _api = ApiClient();

  /// GET /api/subscriptions/plans
  Future<Map<String, dynamic>> getPlans() async {
    return await _api.get('/subscriptions/plans');
  }

  /// POST /api/subscriptions/subscribe
  Future<Map<String, dynamic>> subscribe({
    required String plan,
    String? billingCycle,
    String? paymentMethod,
  }) async {
    final body = <String, dynamic>{'plan': plan};
    if (billingCycle != null) {
      body['billing_cycle'] = billingCycle;
    }
    if (paymentMethod != null) {
      body['payment_method'] = paymentMethod;
    }
    final response = await _api.authenticatedPost(
      '/subscriptions/subscribe',
      body: body,
    );
    _updateSessionSubscription(response);
    return response;
  }

  /// GET /api/subscriptions/current
  Future<Map<String, dynamic>> getCurrentSubscription() async {
    final response = await _api.authenticatedGet('/subscriptions/current');
    _updateSessionSubscription(response);
    return response;
  }

  /// POST /api/subscriptions/cancel
  Future<Map<String, dynamic>> cancelSubscription() async {
    final response = await _api.authenticatedPost('/subscriptions/cancel');
    _updateSessionSubscription(response);
    return response;
  }

  void _updateSessionSubscription(Map<String, dynamic> response) {
    final subscription = response['subscription'];
    Map<String, dynamic>? normalized;
    if (subscription is Map) {
      normalized = Map<String, dynamic>.from(subscription);
    }

    if (normalized != null && response['permissions'] is Map) {
      normalized['permissions'] = Map<String, dynamic>.from(
        response['permissions'],
      );
    }
    UserSession().updateFromApi(subscription: normalized);
  }
}
