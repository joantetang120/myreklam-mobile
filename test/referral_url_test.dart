import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/share_service.dart';

void main() {
  test('Announcement share links use public preview routes', () {
    expect(ShareService.buildUrl('bon-plans', '123'), 'https://www.myreklam.fr/s/bons-plans/123');
    expect(ShareService.buildUrl('job-offers', '123'), 'https://www.myreklam.fr/s/emplois/123');
    expect(ShareService.buildUrl('posts', '123'), 'https://www.myreklam.fr/s/posts/123');
    expect(ShareService.buildUrl('events', '123'), 'https://www.myreklam.fr/s/evenements/123');
    expect(ShareService.buildUrl('trainings', '123'), 'https://www.myreklam.fr/s/formations/123');
  });
  test('Referral link points to the public website, not the API', () {
    final uri = Uri.parse(ApiConfig.referralUrl(' ABC123 '));
    expect(uri.origin, 'https://www.myreklam.fr');
    expect(uri.path, '/');
    expect(uri.queryParameters['ref-parrain'], 'ABC123');
    expect(uri.toString(), isNot(contains('myadmin')));
  });

  test('Referral codes cannot inject extra query parameters', () {
    final uri = Uri.parse(ApiConfig.referralUrl('CODE&other=value'));
    expect(uri.queryParameters, {'ref-parrain': 'CODE&other=value'});
  });
}
