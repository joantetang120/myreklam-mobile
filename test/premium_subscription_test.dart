import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/utils/subscription_helper.dart';
import 'package:myreklam/utils/user_session.dart';

void main() {
  final session = UserSession();

  tearDown(session.clear);

  test('a trial subscription is not active or premium', () {
    session.updateFromApi(
      accountType: 'pro',
      subscription: {
        'plan': 'premium',
        'status': 'trial',
        'permissions': {'messaging': true},
      },
    );

    expect(session.hasActiveSubscription, isFalse);
    expect(SubscriptionHelper.isProPremium, isFalse);
    expect(SubscriptionHelper.canAccessFeature(ProFeature.messaging), isFalse);
  });

  test('an active premium subscription remains premium', () {
    session.updateFromApi(
      accountType: 'pro',
      subscription: {'plan': 'premium', 'status': 'active'},
    );

    expect(session.hasActiveSubscription, isTrue);
    expect(SubscriptionHelper.isProPremium, isTrue);
    expect(SubscriptionHelper.canAccessFeature(ProFeature.messaging), isTrue);
  });

  test('legacy active plans unlock the same actions as premium', () {
    for (final plan in ['monthly', 'annual', 'yearly']) {
      session.updateFromApi(
        accountType: 'pro',
        subscription: {'plan': plan, 'status': 'active'},
      );
      expect(SubscriptionHelper.isProPremium, isTrue, reason: plan);
      expect(
        SubscriptionHelper.canAccessFeature(ProFeature.postAnnouncement),
        isTrue,
      );
      expect(SubscriptionHelper.canAccessFeature(ProFeature.messaging), isTrue);
    }
  });

  test('expired or cancelled paid plans reject stale allowed permissions', () {
    for (final plan in ['premium', 'annual', 'monthly', 'yearly']) {
      for (final values in [
        {'status': 'cancelled'},
        {'status': 'active', 'end_date': '2000-01-01T00:00:00Z'},
        {'status': 'active', 'end_date': 'invalid-date'},
      ]) {
        session.updateFromApi(
          accountType: 'pro',
          subscription: {
            'plan': plan,
            ...values,
            'permissions': {'post_announcement': true, 'messaging': true},
          },
        );
        expect(SubscriptionHelper.isProPremium, isFalse);
        expect(
          SubscriptionHelper.canAccessFeature(ProFeature.postAnnouncement),
          isFalse,
        );
        expect(
          SubscriptionHelper.canAccessFeature(ProFeature.messaging),
          isFalse,
        );
      }
    }
  });
}
