import 'package:myreklam/services/api_client.dart';

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
    final body = <String, dynamic>{
      'plan': plan,
    };
    if (billingCycle != null) {
      body['billing_cycle'] = billingCycle;
    }
    if (paymentMethod != null) {
      body['payment_method'] = paymentMethod;
    }
    return await _api.authenticatedPost('/subscriptions/subscribe', body: body);
  }

  /// GET /api/subscriptions/current
  Future<Map<String, dynamic>> getCurrentSubscription() async {
    return await _api.authenticatedGet('/subscriptions/current');
  }

  /// POST /api/subscriptions/cancel
  Future<Map<String, dynamic>> cancelSubscription() async {
    return await _api.authenticatedPost('/subscriptions/cancel');
  }
}
