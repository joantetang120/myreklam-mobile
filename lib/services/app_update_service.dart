import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum AppStorePlatform { android, ios }

class AppUpdateRequirement {
  const AppUpdateRequirement({
    required this.platform,
    required this.storeUri,
    required this.currentBuildNumber,
    required this.minimumBuildNumber,
    required this.title,
    required this.message,
    this.startImmediateUpdate,
  });

  final AppStorePlatform platform;
  final Uri storeUri;
  final int currentBuildNumber;
  final int minimumBuildNumber;
  final String title;
  final String message;
  final Future<void> Function()? startImmediateUpdate;
}

class AppUpdatePolicy {
  const AppUpdatePolicy._();

  static bool isBuildOutdated({
    required String currentBuildNumber,
    required int minimumBuildNumber,
  }) {
    final currentBuild = int.tryParse(currentBuildNumber.trim());
    return currentBuild != null &&
        minimumBuildNumber > 0 &&
        currentBuild < minimumBuildNumber;
  }
}

class AppUpdateService {
  static const _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.myreklam.app';

  Future<AppUpdateRequirement?> checkForRequiredUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        return null;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber.trim()) ?? 0;
      final availableBuild =
          updateInfo.availableVersionCode ?? currentBuild + 1;

      return AppUpdateRequirement(
        platform: AppStorePlatform.android,
        storeUri: Uri.parse(_androidStoreUrl),
        currentBuildNumber: currentBuild,
        minimumBuildNumber: availableBuild,
        title: 'Mise à jour requise',
        message:
            'Une nouvelle version de Myreklam est disponible sur Google Play. '
            'Installez-la pour continuer à utiliser l’application.',
        startImmediateUpdate: updateInfo.immediateUpdateAllowed
            ? () async {
                await InAppUpdate.performImmediateUpdate();
              }
            : null,
      );
    } catch (error, stackTrace) {
      // Google Play ne fournit pas ce service aux APK installés par câble.
      // La version distribuée par le Play Store est, elle, vérifiable.
      debugPrint('Vérification Google Play indisponible: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}
