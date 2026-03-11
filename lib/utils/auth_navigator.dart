import 'package:flutter/material.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/screens/account_type_screen.dart';
import 'package:myreklam/screens/particulier_info_screen.dart';
import 'package:myreklam/screens/pro_info_screen.dart';
import 'package:myreklam/screens/pro_subscription_screen.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';

class AuthNavigator {
  static void navigateAfterAuth(BuildContext context, Map<String, dynamic> user) {
    final accountType = user['account_type'] as String?;
    final profileCompleted = user['profile_completed'] as bool? ?? false;
    final subscription = user['subscription']; // Can be Map or null

    final bool hasSubscription =
        subscription != null && subscription is Map && subscription.isNotEmpty;

    Widget destination;

    if (accountType == null || accountType.isEmpty) {
      destination = const AccountTypeScreen();
    } else if (!profileCompleted) {
      if (accountType == 'particulier') {
        destination = const ParticulierInfoScreen();
      } else {
        destination = const ProInfoScreen();
      }
    } else if (accountType == 'pro' && !hasSubscription) {
      destination = const ProSubscriptionScreen();
    } else {
      destination = const ParticulierMainScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => destination),
      (route) => false,
    );
  }

  static void navigateToMain(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ParticulierMainScreen()),
      (route) => false,
    );
  }
}
