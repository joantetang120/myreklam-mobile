import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/widgets/social_video_preview.dart';

void main() {
  testWidgets(
    'metadata starts only after activation and ignores a withdrawn response',
    (tester) async {
      var calls = 0;
      final pending = Completer<Map<String, dynamic>?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialVideoPreview(
              text: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
              metadataLoader: (_) {
                calls++;
                return pending.future;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.byType(Image), findsNothing);
      await tester.tap(find.text('Afficher'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      await tester.tap(find.byTooltip('Masquer le contenu externe'));
      await tester.pumpAndSettle();
      pending.complete({
        'title': 'Late response after withdrawal',
        'thumbnail': 'https://example.com/late.jpg',
      });
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text('Late response after withdrawal'), findsNothing);
      expect(find.text('Afficher'), findsOneWidget);
    },
  );
  testWidgets(
    'third-party thumbnail requires activation and resets for another link',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SocialVideoPreview(
              text: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text('Afficher'), findsOneWidget);
      await tester.tap(find.text('Afficher'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.byTooltip('Masquer le contenu externe'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      await tester.tap(find.text('Afficher'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SocialVideoPreview(
              text: 'https://www.youtube.com/watch?v=FODbuCKSKNU',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text('Afficher'), findsOneWidget);
    },
  );
}
