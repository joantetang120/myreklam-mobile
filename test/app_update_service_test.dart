import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myreklam/services/app_update_service.dart';
import 'package:myreklam/widgets/force_update_gate.dart';

void main() {
  test('the force update gate can wrap the application', () {
    const gate = ForceUpdateGate(child: SizedBox());
    expect(gate.child, isA<SizedBox>());
  });

  group('AppUpdatePolicy', () {
    test('requires an update when the installed build is lower', () {
      expect(
        AppUpdatePolicy.isBuildOutdated(
          currentBuildNumber: '11',
          minimumBuildNumber: 12,
        ),
        isTrue,
      );
    });

    test('accepts the minimum build and newer builds', () {
      expect(
        AppUpdatePolicy.isBuildOutdated(
          currentBuildNumber: '12',
          minimumBuildNumber: 12,
        ),
        isFalse,
      );
      expect(
        AppUpdatePolicy.isBuildOutdated(
          currentBuildNumber: '13',
          minimumBuildNumber: 12,
        ),
        isFalse,
      );
    });

    test('fails open for an invalid installed build number', () {
      expect(
        AppUpdatePolicy.isBuildOutdated(
          currentBuildNumber: 'unknown',
          minimumBuildNumber: 12,
        ),
        isFalse,
      );
    });
  });

  group('AppUpdatePolicy.isVersionOutdated', () {
    // iOS compares marketing versions: the App Store never exposes the build.
    test('requires an update when the store publishes a newer version', () {
      expect(
        AppUpdatePolicy.isVersionOutdated(
          currentVersion: '1.1.4',
          storeVersion: '1.1.5',
        ),
        isTrue,
      );
      expect(
        AppUpdatePolicy.isVersionOutdated(
          currentVersion: '1.9.0',
          storeVersion: '1.10.0',
        ),
        isTrue,
      );
    });

    test('accepts equal and newer installed versions', () {
      expect(
        AppUpdatePolicy.isVersionOutdated(
          currentVersion: '1.1.5',
          storeVersion: '1.1.5',
        ),
        isFalse,
      );
      expect(
        AppUpdatePolicy.isVersionOutdated(
          currentVersion: '1.2.0',
          storeVersion: '1.1.5',
        ),
        isFalse,
      );
    });

    test('handles versions of differing depth', () {
      expect(
        AppUpdatePolicy.isVersionOutdated(
          currentVersion: '1.1',
          storeVersion: '1.1.1',
        ),
        isTrue,
      );
      expect(
        AppUpdatePolicy.isVersionOutdated(
          currentVersion: '1.1.0',
          storeVersion: '1.1',
        ),
        isFalse,
      );
    });

    test('ignores the build suffix packaged with the version', () {
      expect(
        AppUpdatePolicy.isVersionOutdated(
          currentVersion: '1.1.5+22',
          storeVersion: '1.1.5',
        ),
        isFalse,
      );
    });

    test('fails open on anything it cannot parse', () {
      // A malformed store answer must never lock users out of the app.
      for (final pair in [
        ('1.1.5', 'latest'),
        ('unknown', '1.1.5'),
        ('1.1.5', ''),
      ]) {
        expect(
          AppUpdatePolicy.isVersionOutdated(
            currentVersion: pair.$1,
            storeVersion: pair.$2,
          ),
          isFalse,
          reason: 'currentVersion=${pair.$1} storeVersion=${pair.$2}',
        );
      }
    });
  });

  group('AppUpdateService.fetchAppStoreRelease', () {
    AppUpdateService serviceReturning(int status, String body) {
      return AppUpdateService(
        httpClient: MockClient(
          (_) async => http.Response(
            body,
            status,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
    }

    test('reads the version and the store link from the lookup payload', () async {
      final service = serviceReturning(
        200,
        jsonEncode({
          'resultCount': 1,
          'results': [
            {
              'version': '1.1.5',
              'trackViewUrl': 'https://apps.apple.com/fr/app/myreklam/id123456789',
            },
          ],
        }),
      );

      final release = await service.fetchAppStoreRelease('com.myreklam.app');

      expect(release, isNotNull);
      expect(release!.version, '1.1.5');
      expect(release.storeUri.host, 'apps.apple.com');
    });

    test('returns null when the app is not published in that store front', () async {
      // Apple answers 200 with an empty result set, not an error status.
      final service = serviceReturning(
        200,
        jsonEncode({'resultCount': 0, 'results': <dynamic>[]}),
      );

      expect(await service.fetchAppStoreRelease('com.myreklam.app'), isNull);
    });

    test('returns null on an error status or an unusable payload', () async {
      expect(
        await serviceReturning(503, '').fetchAppStoreRelease('com.myreklam.app'),
        isNull,
      );
      expect(
        await serviceReturning(200, jsonEncode({'results': [{}]}))
            .fetchAppStoreRelease('com.myreklam.app'),
        isNull,
      );
    });
  });
}
