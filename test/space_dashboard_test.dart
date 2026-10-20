import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/services/space_dashboard_service.dart';
import 'package:myreklam/screens/space_dashboard_screen.dart';

Map<String, dynamic> fixture(String path) {
  if (path == '/profile/me')
    return {
      'user': {
        'account_type': 'particulier',
        'mys': 12.5,
        'is_email_verified': true,
      },
      'profile': {
        'avatar_url': 'avatar.jpg',
        'phone': 'test',
        'bio': 'Présentation',
      },
    };
  if (path == '/mys/history')
    return {
      'earnings': {'data': []},
    };
  if (path == '/referral/stats')
    return {
      'stats': {'total_referred': 3},
    };
  if (path == '/saved-searches')
    return {
      'data': [
        {'id': 1},
        {'id': 2},
      ],
    };
  if (path.endsWith('my-favorites'))
    return {
      'data': [],
      'meta': {'total': 2},
    };
  return {
    'data': {'data': [], 'total': 7, 'last_page': 2},
  };
}

void main() {
  test(
    'Counts use server totals across all five verticals, not page length',
    () async {
      final data = await SpaceDashboardService(
        get: (path) async => fixture(path),
      ).load();
      expect(data.totalAcross(false), 35);
      expect(data.totalAcross(true), 10);
      expect(data.searches, 2);
      expect(data.balance, 12.5);
      expect(data.referred, 3);
      expect(data.completion, [true, true, true, true, true, true]);
    },
  );
  test('A failed vertical is unknown, not a zero or a partial total', () async {
    final data = await SpaceDashboardService(
      get: (path) async {
        if (path == '/events') throw StateError('offline');
        return fixture(path);
      },
    ).load();
    expect(data.totalAcross(false), isNull);
    expect(data.totalAcross(true), 10);
    expect(data.completion[4], isNull);
    expect(data.balance, 12.5);
  });
  test('Incomplete pagination cannot be mistaken for a total', () {
    expect(
      SpaceDashboardData.listTotal({
        'data': {
          'data': [1],
          'last_page': 3,
        },
      }),
      isNull,
    );
    expect(SpaceDashboardData.listTotal({'data': []}), 0);
    expect(SpaceDashboardData.listTotal(null), isNull);
  });
  testWidgets(
    'Dashboard renders summary and completion without a live server',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SpaceDashboardScreen(
            service: SpaceDashboardService(get: (path) async => fixture(path)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mes annonces'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
    expect(find.text('12,5'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Compléter mon profil · 6 / 6'),
        250,
      );
      expect(find.text('Compléter mon profil · 6 / 6'), findsOneWidget);
    },
  );
}
