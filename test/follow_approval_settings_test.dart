import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/widgets/follow_approval_settings.dart';

void main() {
  testWidgets('Loads server setting and restores it after a failed save', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FollowApprovalSettings(
            load: () async => false,
            save: (_) async => throw StateError('offline'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      false,
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      false,
    );
    expect(find.text('Le réglage n’a pas pu être enregistré.'), findsOneWidget);
  });
  testWidgets('A failed load does not invent a stored preference', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FollowApprovalSettings(
            load: () async => throw StateError('offline'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNull,
    );
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
