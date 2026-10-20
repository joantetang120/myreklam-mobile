import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/screens/privacy_screen.dart';

void main() {
  testWidgets('terms acceptance is unchecked and separate from marketing', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await confirmNewAccountTerms(context);
            },
            child: const Text('Conditions'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Conditions'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Créer mon compte'),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.textContaining('ne vaut pas consentement commercial'),
      findsOneWidget,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
  testWidgets('age confirmation stores only the selected band', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await confirmAgeBand(context);
            },
            child: const Text('Confirmer'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('15 ans et plus'), findsOneWidget);
    await tester.tap(find.text('15 à 17 ans'));
    await tester.pumpAndSettle();
    expect(result, '15_17');
  });
  testWidgets('cancelling does not assert adult status', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await confirmAgeBand(context);
            },
            child: const Text('Confirmer'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
