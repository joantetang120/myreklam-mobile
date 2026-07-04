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
}
