import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/widgets/my_space_menu.dart';

void main() {
  Widget wrap(bool pro) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: MySpaceMenu(isPro: pro)),
    ),
  );
  testWidgets('Particulier menu contains every web sidebar section in order', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(false));
    final labels = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();
    expect(labels, [
      'PILOTAGE',
      'Tableau de bord',
      'Mes annonces',
      'Mes publications',
      'Mes stories',
      'Mes favoris',
      'Recherches enregistrées',
      'AVANTAGES',
      'Mes My’s',
      'Parrainage',
      'COMPTE',
      'Mon profil',
      'Paramètres',
      'Comptes gérés',
      'Espace candidat',
    ]);
  });
  testWidgets(
    'Pro menu retains professional space and subscription, not candidate space',
    (tester) async {
      await tester.pumpWidget(wrap(true));
      expect(find.text('Espace professionnel'), findsOneWidget);
      expect(find.text('Abonnement'), findsOneWidget);
      expect(find.text('Espace candidat'), findsNothing);
      expect(find.text('Mes stories'), findsOneWidget);
      expect(find.text('Comptes gérés'), findsOneWidget);
    },
  );
}
