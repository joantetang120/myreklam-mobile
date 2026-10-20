import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/widgets/feed_photo_gallery.dart';

void main() {
  final pixel = MemoryImage(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j1XkAAAAASUVORK5CYII='));
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 360, child: child))));

  testWidgets('Three photos remain uncropped and open the selected photo', (tester) async {
    int? opened;
    await tester.pumpWidget(wrap(FeedPhotoGallery(
      urls: const ['portrait', 'landscape', 'square'],
      imageProviderFor: (_) => pixel,
      onOpen: (index) => opened = index,
    )));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      expect(image.fit, BoxFit.contain);
    }
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byType(PageView));
    expect(opened, 1);
  });

  testWidgets('A single photo has no counter and no gallery is shown when empty', (tester) async {
    await tester.pumpWidget(wrap(FeedPhotoGallery(urls: const ['portrait'], onOpen: (_) {}, imageProviderFor: (_) => pixel)));
    await tester.pumpAndSettle();
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
    expect(find.text('1 / 1'), findsNothing);
    await tester.pumpWidget(wrap(FeedPhotoGallery(urls: const [], onOpen: (_) {})));
    expect(find.byType(PageView), findsNothing);
  });
}
