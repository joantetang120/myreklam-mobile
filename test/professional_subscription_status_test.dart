import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/utils/professional_subscription_status.dart';

void main() {
  final now = DateTime.utc(2026, 7, 20);

  test('marks an active premium subscription as premium', () {
    final status = resolveProfessionalSubscriptionStatus({
      'subscription': {
        'plan': 'premium',
        'status': 'active',
        'end_date': '2026-08-20T00:00:00Z',
      },
    }, now: now);

    expect(status.isPremium, isTrue);
    expect(status.label, 'Premium ⭐️');
  });

  test('supports active legacy monthly and annual paid plans', () {
    for (final plan in ['monthly', 'annual']) {
      final status = resolveProfessionalSubscriptionStatus({
        'user': {
          'subscription': {'plan': plan, 'status': 'active'},
        },
      }, now: now);

      expect(status.isPremium, isTrue, reason: 'plan=$plan');
    }
  });

  test('supports flattened public profile subscription fields', () {
    final status = resolveProfessionalSubscriptionStatus({
      'profile': {
        'subscription_plan': 'premium',
        'subscription_status': 'active',
        'subscription_end_date': '2026-12-31T00:00:00Z',
      },
    }, now: now);

    expect(status.isPremium, isTrue);
  });

  test(
    'does not mark free, trial, expired or missing subscriptions premium',
    () {
      final responses = <Map<String, dynamic>?>[
        null,
        {'subscription': null},
        {
          'subscription': {'plan': 'free', 'status': 'active'},
        },
        {
          'subscription': {'plan': 'premium', 'status': 'trial'},
        },
        {
          'subscription': {'plan': 'premium', 'status': 'cancelled'},
        },
        {
          'subscription': {
            'plan': 'premium',
            'status': 'active',
            'end_date': '2026-07-19T00:00:00Z',
          },
        },
      ];

      for (final response in responses) {
        final status = resolveProfessionalSubscriptionStatus(
          response,
          now: now,
        );
        expect(status.isPremium, isFalse, reason: '$response');
        expect(status.label, 'Basic');
      }
    },
  );
}
