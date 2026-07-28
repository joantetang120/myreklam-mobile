import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/utils/auth_navigator.dart';

void main() {
  group('post-auth navigation', () {
    test('requires email verification first', () {
      expect(
        AuthNavigator.resolveDestination({
          'is_email_verified': false,
          'account_type': 'particulier',
          'profile_completed': true,
        }),
        PostAuthDestination.emailVerification,
      );
    });

    test('requires an account type when none has been selected', () {
      expect(
        AuthNavigator.resolveDestination({
          'is_email_verified': true,
          'account_type': null,
        }),
        PostAuthDestination.accountType,
      );
    });

    test('routes an incomplete particulier to profile completion', () {
      expect(
        AuthNavigator.resolveDestination({
          'is_email_verified': true,
          'account_type': 'particulier',
          'profile_completed': false,
        }),
        PostAuthDestination.particulierProfile,
      );
    });

    test('routes a new pro to company information', () {
      expect(
        AuthNavigator.resolveDestination({
          'is_email_verified': true,
          'account_type': 'pro',
          'profile_completed': false,
          'pro_profile': const {},
        }),
        PostAuthDestination.proProfileStep1,
      );
    });

    test('resumes a pro after company information at step two', () {
      expect(
        AuthNavigator.resolveDestination({
          'is_email_verified': true,
          'account_type': 'pro',
          'profile_completed': false,
          'pro_profile': const {
            'company_name': 'Myreklam',
            'siret': '12345678901234',
            'address': 'Paris',
          },
        }),
        PostAuthDestination.proProfileStep2,
      );
    });

    test('requires a subscription after completing a pro profile', () {
      expect(
        AuthNavigator.resolveDestination({
          'is_email_verified': true,
          'account_type': 'pro',
          'profile_completed': true,
          'subscription': null,
        }),
        PostAuthDestination.proSubscription,
      );
    });

    test('opens the application for a completed account', () {
      expect(
        AuthNavigator.resolveDestination({
          'is_email_verified': true,
          'account_type': 'pro',
          'profile_completed': true,
          'subscription': const {'plan': 'free', 'status': 'active'},
        }),
        PostAuthDestination.main,
      );
    });
  });
}
