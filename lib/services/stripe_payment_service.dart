import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:myreklam/utils/user_session.dart';
import 'api_client.dart';

/// Service for handling Stripe payments
class StripePaymentService {
  final ApiClient _api = ApiClient();

  /// Initialize Stripe with publishable key
  static Future<void> initialize() async {
    // Stripe LIVE publishable key
    Stripe.publishableKey =
        'pk_live_51KEdn8LjQlGQsbAn8FktZTnAdzff9sURGFoMVhDKOvPrwYqvdO2yD6PTxWg0Vleopg0CIgXq9wYezK5SmQ0mj9qZ00yklzhRrP';

    // Set merchant identifier (required for Apple Pay, recommended for test mode)
    Stripe.merchantIdentifier = 'merchant.myreklam.app';

    // Apply settings with error handling
    try {
      await Stripe.instance.applySettings();
      debugPrint('✅ Stripe initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Stripe initialization warning: $e');
      // Continue anyway - sometimes this fails on first run
    }
  }

  /// Create a payment intent and present payment sheet
  /// Returns true if payment was successful, false otherwise
  Future<bool> processPayment({
    required String billingCycle,
    required BuildContext context,
    String? promoCode,
  }) async {
    try {
      // Ensure Stripe is initialized
      if (Stripe.publishableKey.isEmpty) {
        await initialize();
      }

      // Step 1: Create payment intent on backend
      final paymentData = await _createPaymentIntent(billingCycle, promoCode);

      if (paymentData == null) {
        _showError(context, 'Failed to initialize payment');
        return false;
      }

      final clientSecret = paymentData['client_secret'] as String;
      final paymentIntentId = paymentData['payment_intent_id'] as String;

      // Step 2: Configure and present payment sheet
      final paymentSuccessful = await _presentPaymentSheet(
        clientSecret: clientSecret,
        billingCycle: billingCycle,
      );

      if (!paymentSuccessful) {
        return false;
      }

      // Step 3: Confirm payment and create subscription on backend
      final subscriptionData = await _confirmPayment(
        paymentIntentId: paymentIntentId,
        billingCycle: billingCycle,
      );

      if (subscriptionData == null) {
        _showError(
          context,
          'Payment succeeded but failed to create subscription',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Stripe payment error: $e');
      _showError(context, 'Payment failed: $e');
      return false;
    }
  }

  /// Create payment intent on backend
  Future<Map<String, dynamic>?> _createPaymentIntent(
    String billingCycle, [
    String? promoCode,
  ]) async {
    try {
      final response = await _api.authenticatedPost(
        '/payments/intent',
        body: {
          'billing_cycle': billingCycle,
          if (promoCode != null && promoCode.trim().isNotEmpty)
            'promotion_code': promoCode.trim(),
        },
      );

      if (response['success'] == true) {
        return {
          'client_secret': response['client_secret'],
          'payment_intent_id': response['payment_intent_id'],
          'amount': response['amount'],
        };
      }

      return null;
    } catch (e) {
      debugPrint('Create payment intent error: $e');
      return null;
    }
  }

  /// Validate a promotion code and preview the discounted price.
  /// Returns {discounted_amount, original_amount, discount:{label,...}} on
  /// success, or {error: message} if invalid.
  Future<Map<String, dynamic>> validatePromo({
    required String billingCycle,
    required String code,
  }) async {
    try {
      final response = await _api.authenticatedPost(
        '/payments/promo',
        body: {'billing_cycle': billingCycle, 'promotion_code': code.trim()},
      );
      if (response['success'] == true) {
        return {
          'valid': true,
          'discounted_amount': response['discounted_amount'],
          'original_amount': response['original_amount'],
          'discount': response['discount'],
        };
      }
      return {'valid': false, 'error': response['message'] ?? 'Code invalide'};
    } on ApiException catch (e) {
      return {'valid': false, 'error': e.message};
    } catch (e) {
      return {'valid': false, 'error': 'Impossible de vérifier le code promo'};
    }
  }

  /// Present Stripe payment sheet
  Future<bool> _presentPaymentSheet({
    required String clientSecret,
    required String billingCycle,
  }) async {
    try {
      // Setup payment sheet - basic configuration for v10.2.0
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Myreklam',
          style: ThemeMode.light,
          allowsDelayedPaymentMethods: false,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // If we get here, payment was successful
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // User canceled the payment
        debugPrint('Payment canceled by user');
        return false;
      }
      debugPrint('Stripe exception: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      debugPrint('Present payment sheet error: $e');
      return false;
    }
  }

  /// Confirm payment and create subscription
  Future<Map<String, dynamic>?> _confirmPayment({
    required String paymentIntentId,
    required String billingCycle,
  }) async {
    try {
      final response = await _api.authenticatedPost(
        '/payments/confirm',
        body: {
          'payment_intent_id': paymentIntentId,
          'plan': 'premium',
          'billing_cycle': billingCycle,
        },
      );

      if (response['success'] == true) {
        final subscription = response['subscription'] as Map<String, dynamic>?;
        if (subscription != null) {
          UserSession().updateFromApi(
            subscription: Map<String, dynamic>.from(subscription),
          );
        }
        return subscription;
      }

      return null;
    } catch (e) {
      debugPrint('Confirm payment error: $e');
      return null;
    }
  }

  /// Process the €5 payment for an additional manager seat.
  /// Returns the payment_intent_id on success, or null if cancelled/failed.
  Future<String?> processSeatPayment({required BuildContext context}) async {
    try {
      if (Stripe.publishableKey.isEmpty) {
        await initialize();
      }

      // 1. Create the seat PaymentIntent on the backend.
      final response = await _api.authenticatedPost('/delegations/seat-intent');
      if (response['success'] != true) {
        _showError(
          context,
          response['message']?.toString() ?? 'Échec du paiement',
        );
        return null;
      }
      final clientSecret = response['client_secret'] as String;
      final paymentIntentId = response['payment_intent_id'] as String;

      // 2. Present the payment sheet.
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Myreklam',
          style: ThemeMode.light,
          allowsDelayedPaymentMethods: false,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // 3. Payment succeeded — the delegation endpoint verifies the intent.
      return paymentIntentId;
    } on StripeException catch (e) {
      if (e.error.code != FailureCode.Canceled) {
        _showError(context, e.error.localizedMessage ?? 'Paiement échoué');
      }
      return null;
    } catch (e) {
      debugPrint('Seat payment error: $e');
      _showError(context, 'Paiement échoué: $e');
      return null;
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
