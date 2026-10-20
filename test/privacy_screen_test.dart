import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/screens/privacy_screen.dart';
import 'package:myreklam/services/privacy_service.dart';

class FakePrivacyService extends PrivacyService {
  String age = '18_plus';
  final values = <String, dynamic>{
    'feed_personalization_enabled': true,
    'marketing_email': false,
    'marketing_push': false,
    'email_tracking': false,
  };
  Map<String, dynamic>? savedDirective;
  Map<String, dynamic>? savedPreferences;
  Map<String, dynamic>? rightsRequest;
  bool failRequests = false;
  @override
  Future<Map<String, dynamic>> requests({int page = 1}) async {
    if (failRequests) throw Exception('Offline');
    return {
      'data': {
        'data': rightsRequest == null
            ? []
            : [
                {
                  'id': 'test-reference',
                  'type': rightsRequest!['type'],
                  'status': 'received',
                  'due_at': '2026-11-10',
                },
              ],
        'current_page': 1,
        'last_page': 1,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> preferences() async => {
    'data': {'age_band': age, ...values},
  };
  @override
  Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> body,
  ) async {
    savedPreferences = body;
    values.addAll(body);
    return {};
  }

  @override
  Future<Map<String, dynamic>> postMortem() async => {'data': savedDirective};
  @override
  Future<Map<String, dynamic>> updatePostMortem(
    Map<String, dynamic> body,
  ) async {
    savedDirective = body;
    return {};
  }

  @override
  Future<Map<String, dynamic>> revokePostMortem() async {
    savedDirective = null;
    return {};
  }

  @override
  Future<Map<String, dynamic>> requestRights(Map<String, dynamic> body) async {
    rightsRequest = body;
    return {
      'data': {'id': 'test-reference', 'due_at': '2026-11-10'},
    };
  }
}

void main() {
  testWidgets('request history exposes reference and deadline with retry', (
    tester,
  ) async {
    final service = FakePrivacyService()..failRequests = true;
    await tester.pumpWidget(MaterialApp(home: PrivacyScreen(service: service)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Actualiser le suivi'), 300);
    expect(
      find.textContaining('Impossible de charger le suivi'),
      findsOneWidget,
    );
    service.failRequests = false;
    service.rightsRequest = {'type': 'access'};
    await tester.tap(find.text('Actualiser le suivi'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Référence : test-reference'),
      200,
    );
    expect(
      find.textContaining('Échéance de réponse : 10/11/2026'),
      findsOneWidget,
    );
    expect(find.textContaining('Impossible de charger le suivi'), findsNothing);
  });
  testWidgets('minor cannot enable marketing or individual email measurement', (
    tester,
  ) async {
    final service = FakePrivacyService()..age = '15_17';
    await tester.pumpWidget(MaterialApp(home: PrivacyScreen(service: service)));
    await tester.pumpAndSettle();
    for (final tile in tester.widgetList<SwitchListTile>(
      find.byType(SwitchListTile),
    )) {
      if ((tile.title as Text).data == 'Personnaliser mon fil') {
        expect(tile.onChanged, isNotNull);
        continue;
      }
      expect(tile.value, isFalse);
      expect(tile.onChanged, isNull);
    }
    expect(service.savedPreferences, isNull);
  });
  testWidgets('adult email optin is independent and includes policy version', (
    tester,
  ) async {
    final service = FakePrivacyService();
    await tester.pumpWidget(MaterialApp(home: PrivacyScreen(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Offres commerciales par e-mail'),
    );
    await tester.pumpAndSettle();
    expect(service.savedPreferences, {
      'marketing_email': true,
      'policy_version': '2026-10-10',
    });
    expect(service.values['marketing_push'], isFalse);
    expect(service.values['email_tracking'], isFalse);
  });
  testWidgets(
    'minor can refuse feed personalization independently of marketing',
    (tester) async {
      final service = FakePrivacyService()..age = '15_17';
      await tester.pumpWidget(
        MaterialApp(home: PrivacyScreen(service: service)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Personnaliser mon fil'),
      );
      await tester.pumpAndSettle();
      expect(service.savedPreferences, {
        'feed_personalization_enabled': false,
        'policy_version': '2026-10-10',
      });
      expect(service.values['marketing_email'], isFalse);
    },
  );
  testWidgets(
    'postmortem requires separate specific consent and can be revoked',
    (tester) async {
      final service = FakePrivacyService();
      await tester.pumpWidget(
        MaterialApp(home: PrivacyScreen(service: service)),
      );
      await tester.pumpAndSettle();
      final directives = find.text(
        'Directives relatives aux données après décès',
      );
      await tester.scrollUntilVisible(directives, 300);
      await tester.tap(directives);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Enregistrer'))
            .onPressed,
        isNull,
      );
      expect(service.savedDirective, isNull);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(service.savedDirective?['consent'], isTrue);
      expect(service.savedDirective?['choice'], 'no_share');
      expect(service.savedDirective?['policy_version'], '2026-10-10');
      await tester.ensureVisible(find.text('Révoquer mes directives'));
      await tester.tap(find.text('Révoquer mes directives'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Révoquer'));
      await tester.pumpAndSettle();
      expect(service.savedDirective, isNull);
    },
  );
  testWidgets('rights request only submitted after explicit send', (
    tester,
  ) async {
    final service = FakePrivacyService();
    await tester.pumpWidget(MaterialApp(home: PrivacyScreen(service: service)));
    await tester.pumpAndSettle();
    final rights = find.text('Exercer mes droits');
    await tester.scrollUntilVisible(rights, 300);
    await tester.tap(rights);
    await tester.pumpAndSettle();
    expect(service.rightsRequest, isNull);
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(service.rightsRequest?['type'], 'access');
    expect(service.rightsRequest?['details'], isNotEmpty);
  });
}
