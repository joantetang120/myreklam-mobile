import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/utils/avatar_resolver.dart';

void main() {
  group('AvatarResolver', () {
    test('finds particulier and professional nested avatars', () {
      expect(
        AvatarResolver.resolve({
          'user': {
            'particulier_profile': {'avatar_url': 'avatars/person.jpg'},
          },
        }),
        'avatars/person.jpg',
      );
      expect(
        AvatarResolver.resolve({
          'author': {
            'pro_profile': {'logo_url': 'img/company.png'},
          },
        }),
        'img/company.png',
      );
    });

    test('ignores empty and placeholder values', () {
      expect(AvatarResolver.resolve({'avatar_url': 'null'}), isNull);
      expect(AvatarResolver.resolve({'avatar_url': '  '}), isNull);
    });
  });

  group('ApiConfig.resolveMediaUrl', () {
    test('keeps absolute URLs', () {
      expect(
        ApiConfig.resolveMediaUrl('https://cdn.example.test/avatar.jpg'),
        'https://cdn.example.test/avatar.jpg',
      );
    });

    test('resolves generic relative backend media paths', () {
      expect(
        ApiConfig.resolveMediaUrl('img/company.png'),
        'https://myreklam-admin.maisoft-group.com/img/company.png',
      );
    });
  });
}
