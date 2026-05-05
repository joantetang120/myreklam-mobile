import 'package:flutter/material.dart';
import 'package:myreklam/screens/pro_subscription_screen.dart';
import 'package:myreklam/utils/user_session.dart';

/// Features available for pro users based on subscription plan
enum ProFeature {
  /// TROUVER category
  viewAnnouncements,
  commentAndReact,
  getContactInfo,
  viewSharedDocuments,
  downloadTrainingPrograms,

  /// PROMOUVOIR category
  postAnnouncement,
  shareCoordinatesOnAds,

  /// COMMUNIQUER category
  messaging,
  convertMysToRewards,

  /// DIFFUSER category
  premiumProfile,
  replyToReviews,
}

class SubscriptionHelper {
  /// Check if the current user is a pro with an active premium subscription
  static bool get isProPremium {
    final session = UserSession();
    if (!session.isPro) return false;
    return session.hasActiveSubscription &&
        session.subscriptionPlan == 'premium';
  }

  /// Check if the current user is a pro with free plan (no active premium)
  static bool get isProFree {
    final session = UserSession();
    if (!session.isPro) return false;
    return !isProPremium;
  }

  /// Check if the free pro trial period (1 month from account creation) is still active
  static bool get isWithinFreeTrialPeriod {
    final session = UserSession();
    final createdAt =
        session.subscription?['start_date'] ??
        session.subscription?['created_at'];
    if (createdAt == null) return true; // Default to allowed if unknown

    final created = DateTime.tryParse(createdAt.toString());
    if (created == null) return true;

    final oneMonthLater = created.add(const Duration(days: 30));
    return DateTime.now().isBefore(oneMonthLater);
  }

  /// Check if the current pro user can access a specific feature
  static bool canAccessFeature(ProFeature feature) {
    final session = UserSession();

    // Non-pro users: all features allowed (different rules apply)
    if (!session.isPro) return true;

    // Premium pro: all features allowed
    if (isProPremium) return true;

    // Free pro: check feature-specific rules
    switch (feature) {
      // Always available for free
      case ProFeature.viewAnnouncements:
        return true;

      // Limited to 1 month trial period
      case ProFeature.commentAndReact:
      case ProFeature.postAnnouncement:
        return isWithinFreeTrialPeriod;

      // Premium only
      case ProFeature.getContactInfo:
      case ProFeature.viewSharedDocuments:
      case ProFeature.downloadTrainingPrograms:
      case ProFeature.shareCoordinatesOnAds:
      case ProFeature.messaging:
      case ProFeature.convertMysToRewards:
      case ProFeature.premiumProfile:
      case ProFeature.replyToReviews:
        return false;
    }
  }

  /// Show a dialog prompting the user to upgrade to premium
  static void showPremiumRequiredDialog(
    BuildContext context, {
    String? featureName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Color(0xFFFF9800),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Fonctionnalité Premium',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          featureName != null
              ? 'La fonctionnalité "$featureName" est réservée aux comptes Premium. Passez à la version Premium pour y accéder.'
              : 'Cette fonctionnalité est réservée aux comptes Premium. Passez à la version Premium pour y accéder.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF616161)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProSubscriptionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E9B5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Passer Premium'),
          ),
        ],
      ),
    );
  }

  /// Show a dialog for free trial expired features
  static void showTrialExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.access_time,
                color: Color(0xFFFF9800),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Période d\'essai expirée',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Votre période d\'essai gratuite de 1 mois est terminée. Passez à la version Premium pour continuer à utiliser cette fonctionnalité.',
          style: TextStyle(fontSize: 14, color: Color(0xFF616161)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProSubscriptionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E9B5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Passer Premium'),
          ),
        ],
      ),
    );
  }

  /// Guard a feature action: if allowed, execute the callback;
  /// otherwise show the appropriate blocking dialog
  static void guardFeature(
    BuildContext context,
    ProFeature feature,
    VoidCallback onAllowed, {
    String? featureName,
  }) {
    if (canAccessFeature(feature)) {
      onAllowed();
      return;
    }

    // Free pro, check if it's a time-limited feature
    if (isProFree) {
      switch (feature) {
        case ProFeature.commentAndReact:
        case ProFeature.postAnnouncement:
          showTrialExpiredDialog(context);
          return;
        default:
          break;
      }
    }

    showPremiumRequiredDialog(context, featureName: featureName);
  }
}
