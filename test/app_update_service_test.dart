import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
