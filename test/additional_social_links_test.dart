import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/widgets/additional_social_links.dart';

void main() {
  testWidgets('A profile can be shared without any social network', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body:
      AdditionalSocialLinks(links: {}, profileId: '123'))));
    expect(find.text('Partager ce profil'), findsOneWidget);
  });
  testWidgets('Additional networks display even without the old five networks', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AdditionalSocialLinks(links: {
      'website': 'myreklam.fr', 'x': 'myreklam', 'tiktok': '@myreklam', 'dribbble': 'myreklam',
    }))));
    for (final label in ['Site web', 'X', 'TikTok', 'Dribbble']) {
      expect(find.text(label), findsOneWidget);
    }
  });
  testWidgets('Empty or unsafe links have no button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AdditionalSocialLinks(links: {
      'website': 'javascript:alert(1)', 'x': '', 'tiktok': 'https://user:pass@example.com',
    }))));
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
