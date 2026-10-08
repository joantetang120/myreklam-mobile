import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/widgets/announcement_ai_panel.dart';
import 'package:myreklam/services/announcement_ai_service.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/utils/gallery_picker.dart';

class FakeAnnouncementAiService extends AnnouncementAiService {
  bool fail = false;
  int calls = 0;
  @override
  Future<AnnouncementAiResult> extract({
    required String kind,
    String? url,
    GalleryMedia? image,
    Map<String, List<String>> categories = const {},
  }) async {
    calls++;
    if (fail)
      throw ApiException(
        statusCode: 422,
        message: 'Photo illisible. Réessayez.',
      );
    return AnnouncementAiResult(
      fields: {'title': 'Formation test'},
      media: [],
      warnings: ['Prix absent'],
      missingFields: ['price'],
    );
  }
}

void main() {
  testWidgets(
    'link result requires confirmation and exposes partial warnings',
    (tester) async {
      final service = FakeAnnouncementAiService();
      final controller = TextEditingController(
        text: 'https://example.com/formation',
      );
      Map<String, dynamic>? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementAiPanel(
              kind: 'trainings',
              service: service,
              linkController: controller,
              onResult: (f, _) => applied = f,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Analyser le lien'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(applied, isNull);
      expect(find.text('Appliquer les informations ?'), findsOneWidget);
      await tester.tap(find.text('Appliquer'));
      await tester.pumpAndSettle();
      expect(applied?['title'], 'Formation test');
      expect(find.textContaining('Prix absent'), findsOneWidget);
      expect(service.calls, 1);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  testWidgets(
    'failed extraction allows retry and cancel leaves form untouched',
    (tester) async {
      final service = FakeAnnouncementAiService()..fail = true;
      final controller = TextEditingController(
        text: 'https://example.com/event',
      );
      var applied = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementAiPanel(
              kind: 'events',
              service: service,
              linkController: controller,
              onResult: (_, __) => applied = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Analyser le lien'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Photo illisible. Réessayez.'), findsOneWidget);
      service.fail = false;
      await tester.tap(find.text('Analyser le lien'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(applied, isFalse);
      expect(service.calls, 2);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  test(
    'location keeps observed city and postcode without inventing coordinates',
    () {
      final location = announcementAiLocation({
        'locationCity': 'Nice',
        'locationPostalCode': '06000',
      });
      expect(location!.city, 'Nice');
      expect(location.postalCode, '06000');
      expect(location.latitude, isNull);
      expect(announcementAiLocation({}), isNull);
    },
  );
  testWidgets('four announcement kinds expose the AI image picker', (
    tester,
  ) async {
    for (final kind in ['bonplans', 'job-offers', 'events', 'trainings']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementAiPanel(kind: kind, onResult: (_, __) {}),
          ),
        ),
      );
      expect(find.text('Préremplir avec l’IA'), findsOneWidget);
      expect(find.text('Choisir une image et analyser'), findsOneWidget);
    }
  });
}
