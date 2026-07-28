// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myreklam/widgets/force_update_gate.dart';

void main() {
  testWidgets('shows the application when no update is required', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ForceUpdateGate(
          checkForRequiredUpdate: () async => null,
          child: const Scaffold(body: Text('Application Myreklam')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Application Myreklam'), findsOneWidget);
  });
}
