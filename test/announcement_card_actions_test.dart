import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/widgets/demande_card.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';

void main() {
  Widget narrowScreen(Widget child) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(320, 800)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  testWidgets('demande actions remain visible on a narrow screen', (
    tester,
  ) async {
    var favoriteTaps = 0;
    var reportTaps = 0;

    await tester.pumpWidget(
      narrowScreen(
        DemandeCard(
          profileImage: '',
          username: 'Une entreprise avec un nom très long',
          categoryLabel: 'Service',
          title: 'Recherche urgente',
          description: 'Description de la demande',
          location: 'Paris',
          likesCount: 0,
          commentsCount: 0,
          timeAgo: 'Maintenant',
          onFavoriteToggle: () => favoriteTaps++,
          onReport: () => reportTaps++,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Demande'), findsOneWidget);
    await tester.tap(find.byTooltip('Signaler'));
    await tester.tap(find.byIcon(Icons.favorite_border));
    expect(reportTaps, 1);
    expect(favoriteTaps, 1);
  });

  testWidgets('job actions remain visible on a narrow screen', (tester) async {
    var favoriteTaps = 0;
    var reportTaps = 0;

    await tester.pumpWidget(
      narrowScreen(
        JobAnnouncementCard(
          companyLogo: '',
          companyName: 'Une entreprise avec un nom très long',
          jobTitle: 'Développeur',
          description: 'Description du poste',
          tags: const [],
          timeAgo: 'Maintenant',
          onFavoriteToggle: () => favoriteTaps++,
          onReport: () => reportTaps++,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text("Offre d'emploi"), findsOneWidget);
    await tester.tap(find.byTooltip('Signaler'));
    await tester.tap(find.byIcon(Icons.favorite_border));
    expect(reportTaps, 1);
    expect(favoriteTaps, 1);
  });
}
