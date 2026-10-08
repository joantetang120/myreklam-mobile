import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/widgets/feed_section_header.dart';

void main() {
  for (final width in [320.0, 390.0, 600.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Reels stays aligned at width $width and scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var opened = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: FeedSectionHeader(onOpenReels: () => opened++),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final button = find.byWidgetPredicate((widget) => widget is TextButton);
        final rect = tester.getRect(button);
        expect(rect.right, closeTo(width - 20, 1));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(
          rect.left,
          greaterThan(tester.getRect(find.text("Fil d'actualités")).left),
        );
        await tester.tap(button);
        expect(opened, 1);
      });
    }
  }
}
