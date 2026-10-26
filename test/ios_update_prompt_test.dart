import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myreklam/services/app_update_service.dart';
import 'package:myreklam/services/update_reminder_store.dart';
import 'package:myreklam/widgets/force_update_gate.dart';

AppUpdateRequirement release([String version = '1.21']) => AppUpdateRequirement(
  platform: AppStorePlatform.ios,
  storeUri: Uri.parse('https://apps.apple.com/app/id6766224435'),
  currentBuildNumber: 25,
  minimumBuildNumber: 26,
  storeVersion: version,
  title: 'Mise à jour disponible',
  message: 'Une nouvelle version est disponible.',
);

Widget app(
  Future<AppUpdateRequirement?> Function() check, {
  UpdateReminderStore? reminders,
  Future<bool> Function(Uri)? open,
}) => MaterialApp(
  builder: (context, child) => ForceUpdateGate(
    checkForRequiredUpdate: check,
    reminderStore: reminders,
    openStore: open,
    child: child!,
  ),
  home: const Scaffold(body: Text('Fil Myreklam')),
);

void iosWidgets(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, body, variant: TargetPlatformVariant({TargetPlatform.iOS}));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  iosWidgets(
    'iOS enters the app while checking and shows no prompt when current',
    (tester) async {
      final pending = Completer<AppUpdateRequirement?>();
      await tester.pumpWidget(app(() => pending.future));
      expect(find.text('Fil Myreklam'), findsOneWidget);
      pending.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('Mettre à jour'), findsNothing);
    },
  );

  iosWidgets(
    'Later dismisses and persists a release-specific 24-hour reminder',
    (tester) async {
      var now = DateTime(2026, 10, 26, 10);
      await tester.pumpWidget(
        app(
          () async => release(),
          reminders: UpdateReminderStore(now: () => now),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mise à jour disponible'), findsOneWidget);
      await tester.tap(find.text('Plus tard'));
      await tester.pumpAndSettle();
      expect(find.text('Fil Myreklam'), findsOneWidget);
      expect(find.text('Mettre à jour'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      now = now.add(const Duration(hours: 23));
      await tester.pumpWidget(
        app(
          () async => release(),
          reminders: UpdateReminderStore(now: () => now),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mettre à jour'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      now = now.add(const Duration(hours: 1));
      await tester.pumpWidget(
        app(
          () async => release(),
          reminders: UpdateReminderStore(now: () => now),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mettre à jour'), findsOneWidget);
    },
  );

  iosWidgets(
    'opening store rechecks on resume without trapping a still outdated device',
    (tester) async {
      var checks = 0;
      Uri? opened;
      await tester.pumpWidget(
        app(
          () async {
            checks++;
            return release();
          },
          open: (uri) async {
            opened = uri;
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mettre à jour'));
      await tester.pumpAndSettle();
      expect(opened.toString(), 'https://apps.apple.com/app/id6766224435');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(checks, 2);
      expect(find.text('Mettre à jour'), findsNothing);
      expect(find.text('Fil Myreklam'), findsOneWidget);
    },
  );

  iosWidgets('installed update is accepted on return from the store', (
    tester,
  ) async {
    var updated = false;
    await tester.pumpWidget(
      app(() async => updated ? null : release(), open: (_) async => true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mettre à jour'));
    await tester.pumpAndSettle();
    updated = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  iosWidgets('a store launch failure still allows Later', (tester) async {
    await tester.pumpWidget(
      app(() async => release(), open: (_) async => false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mettre à jour'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Impossible d’ouvrir'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  iosWidgets('offline lookup never prevents using the app', (tester) async {
    await tester.pumpWidget(app(() async => throw Exception('offline')));
    await tester.pumpAndSettle();
    expect(find.text('Fil Myreklam'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  iosWidgets(
    'a slow lookup times out without blocking or showing a late result',
    (tester) async {
      final pending = Completer<AppUpdateRequirement?>();
      await tester.pumpWidget(app(() => pending.future));
      await tester.pump(const Duration(seconds: 13));
      pending.complete(release());
      await tester.pumpAndSettle();
      expect(find.text('Fil Myreklam'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  iosWidgets('replacing splash route cannot dispose the update check', (
    tester,
  ) async {
    final pending = Completer<AppUpdateRequirement?>();
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        builder: (context, child) => ForceUpdateGate(
          checkForRequiredUpdate: () => pending.future,
          child: child!,
        ),
        routes: {'/feed': (_) => const Scaffold(body: Text('Fil Myreklam'))},
        home: const Scaffold(body: Text('Splash')),
      ),
    );
    nav.currentState!.pushReplacementNamed('/feed');
    await tester.pumpAndSettle();
    pending.complete(release());
    await tester.pumpAndSettle();
    expect(find.text('Fil Myreklam'), findsOneWidget);
    expect(find.text('Plus tard'), findsOneWidget);
  });

  testWidgets(
    'Android retains mandatory immediate update and no Later option',
    (tester) async {
      var immediate = 0;
      await tester.pumpWidget(
        app(
          () async => AppUpdateRequirement(
            platform: AppStorePlatform.android,
            storeUri: Uri.parse(
              'https://play.google.com/store/apps/details?id=com.myreklam.app',
            ),
            currentBuildNumber: 25,
            minimumBuildNumber: 26,
            title: 'Mise à jour requise',
            message: 'Mise à jour Google Play',
            startImmediateUpdate: () async {
              immediate++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Plus tard'), findsNothing);
      await tester.tap(find.text('Mettre à jour sur Google Play'));
      await tester.pumpAndSettle();
      expect(immediate, 1);
    },
    variant: TargetPlatformVariant({TargetPlatform.android}),
  );

  test('postponing one release does not postpone the next one', () async {
    final reminders = UpdateReminderStore();
    await reminders.postpone('1.21');
    expect(await reminders.shouldPrompt('1.21'), isFalse);
    expect(await reminders.shouldPrompt('1.22'), isTrue);
  });
}
