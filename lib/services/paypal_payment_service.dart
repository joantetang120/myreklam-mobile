import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_client.dart';

class PayPalPaymentService {
  static final PayPalPaymentService _instance = PayPalPaymentService._internal();
  factory PayPalPaymentService() => _instance;
  PayPalPaymentService._internal();

  final ApiClient _api = ApiClient();

  /// Create PayPal order and return approval URL
  Future<Map<String, dynamic>> createOrder({
    required String billingCycle,
  }) async {
    final response = await _api.authenticatedPost(
      '/payments/paypal/order',
      body: {'billing_cycle': billingCycle},
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to create PayPal order');
    }

    return {
      'orderId': response['order_id'],
      'approvalUrl': response['approval_url'],
      'amount': response['amount'],
      'currency': response['currency'],
    };
  }

  /// Launch PayPal checkout in external browser/app
  Future<bool> launchPayPalCheckout(String approvalUrl) async {
    final uri = Uri.parse(approvalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return true;
    }
    throw Exception('Could not launch PayPal checkout');
  }

  /// Capture PayPal payment after user returns
  Future<Map<String, dynamic>> capturePayment(String orderId) async {
    final response = await _api.authenticatedPost(
      '/payments/paypal/capture',
      body: {'order_id': orderId},
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to capture PayPal payment');
    }

    return response['subscription'];
  }

  /// Process full PayPal payment flow
  Future<bool> processPayment({
    required String billingCycle,
    required BuildContext context,
  }) async {
    try {
      // Step 1: Create order
      final orderData = await createOrder(billingCycle: billingCycle);
      final orderId = orderData['orderId'] as String;
      final approvalUrl = orderData['approvalUrl'] as String;

      // Step 2: Launch PayPal checkout
      await launchPayPalCheckout(approvalUrl);

      // Note: After PayPal payment, user will be redirected to the return URL
      // The Flutter app should detect this via deep linking or
      // the user manually returns to the app

      // For now, show a dialog to confirm payment completion
      if (context.mounted) {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Paiement PayPal'),
            content: const Text(
              'Avez-vous terminé votre paiement sur PayPal ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0070BA),
                  foregroundColor: Colors.white,
                ),
                child: const Text('J\'ai payé'),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          return false;
        }
      }

      // Step 3: Capture the payment
      await capturePayment(orderId);

      return true;
    } catch (e) {
      debugPrint('PayPal payment error: $e');
      rethrow;
    }
  }
}
