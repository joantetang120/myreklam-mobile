import 'package:flutter/material.dart';
import 'package:myreklam/screens/account_type_screen.dart';
import 'package:myreklam/screens/particulier_info_screen.dart';
import 'package:myreklam/screens/pro_info_screen.dart';
import 'package:myreklam/screens/pro_info_step2_screen.dart';
import 'package:myreklam/screens/pro_subscription_screen.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/otp_screen.dart';

enum PostAuthDestination {
  emailVerification,
  accountType,
  particulierProfile,
  proProfileStep1,
  proProfileStep2,
  proSubscription,
  main,
}

class AuthNavigator {
  static PostAuthDestination resolveDestination(Map<String, dynamic> user) {
    if (user['is_email_verified'] == false) {
      return PostAuthDestination.emailVerification;
    }

    final accountType = user['account_type']?.toString();
    final profileCompleted = user['profile_completed'] == true;
    final subscription = user['subscription'];
    final hasSubscription = subscription is Map && subscription.isNotEmpty;

    if (accountType == null || accountType.isEmpty) {
      return PostAuthDestination.accountType;
    }
    if (!profileCompleted) {
      if (accountType == 'particulier') {
        return PostAuthDestination.particulierProfile;
      }
      final profile = user['pro_profile'] is Map
          ? user['pro_profile'] as Map
          : user['profile'] is Map
          ? user['profile'] as Map
          : const {};
      final step1Completed = [
        'company_name',
        'siret',
        'address',
      ].every((field) => profile[field]?.toString().trim().isNotEmpty == true);
      return step1Completed
          ? PostAuthDestination.proProfileStep2
          : PostAuthDestination.proProfileStep1;
    }
    if (accountType == 'pro' && !hasSubscription) {
      return PostAuthDestination.proSubscription;
    }
    return PostAuthDestination.main;
  }

  static void navigateAfterAuth(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    final destination = switch (resolveDestination(user)) {
      PostAuthDestination.emailVerification => OtpScreen(
        email: user['email']?.toString(),
        purpose: 'email_verification',
      ),
      PostAuthDestination.accountType => const AccountTypeScreen(),
      PostAuthDestination.particulierProfile => const ParticulierInfoScreen(),
      PostAuthDestination.proProfileStep1 => const ProInfoScreen(),
      PostAuthDestination.proProfileStep2 => const ProInfoStep2Screen(),
      PostAuthDestination.proSubscription => const ProSubscriptionScreen(
        forceChoice: true,
      ),
      PostAuthDestination.main => const ParticulierMainScreen(),
    };

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
