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
  static const Map<ProFeature, String> _permissionKeys = {
    ProFeature.viewAnnouncements: 'view_announcements',
    ProFeature.commentAndReact: 'comment_and_react',
    ProFeature.getContactInfo: 'get_contact_info',
    ProFeature.viewSharedDocuments: 'view_shared_documents',
    ProFeature.downloadTrainingPrograms: 'download_training_programs',
    ProFeature.postAnnouncement: 'post_announcement',
    ProFeature.shareCoordinatesOnAds: 'share_coordinates_on_ads',
    ProFeature.messaging: 'messaging',
    ProFeature.convertMysToRewards: 'convert_mys_to_rewards',
    ProFeature.premiumProfile: 'premium_profile',
    ProFeature.replyToReviews: 'reply_to_reviews',
  };

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

  /// Check if the current pro user can access a specific feature
  static bool canAccessFeature(ProFeature feature) {
    final session = UserSession();

    // Non-pro users: all features allowed (different rules apply)
    if (!session.isPro) return true;

    // Premium pro: all features allowed
    if (isProPremium) return true;

    // A legacy trial must not grant premium permissions.
    if (session.subscriptionStatus != 'trial') {
      final permissionKey = _permissionKeys[feature];
      final permissions = session.subscriptionPermissions;
      if (permissionKey != null && permissions.containsKey(permissionKey)) {
        return permissions[permissionKey] == true;
      }
    }

    // Free pro: check feature-specific rules
    switch (feature) {
      // Always available for free
      case ProFeature.viewAnnouncements:
        return true;

      case ProFeature.commentAndReact:
      case ProFeature.postAnnouncement:
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
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
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

    showPremiumRequiredDialog(context, featureName: featureName);
  }
}
