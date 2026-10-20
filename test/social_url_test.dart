import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/utils/social_url.dart';

void main() {
  test('Social handles and website domains become full links', () {
    expect(normalizeSocialUrl('instagram', '@myreklam'), 'https://www.instagram.com/myreklam');
    expect(normalizeSocialUrl('tiktok', '@myreklam'), 'https://www.tiktok.com/@myreklam');
    expect(normalizeSocialUrl('linkedin', 'myreklam'), 'https://www.linkedin.com/in/myreklam');
    expect(normalizeSocialUrl('website', 'myreklam.fr'), 'https://myreklam.fr');
    expect(normalizeSocialUrl('x', 'https://x.com/myreklam'), 'https://x.com/myreklam');
    expect(normalizeSocialUrl('facebook', ''), '');
  });
  test('Unsafe links and embedded credentials are rejected', () {
    expect(() => normalizeSocialUrl('website', 'javascript:alert(1)'), throwsFormatException);
    expect(() => normalizeSocialUrl('website', 'https://user:pass@example.com'), throwsFormatException);
  });
}
