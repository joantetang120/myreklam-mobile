import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
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
  });

  final AppStorePlatform platform;
  final Uri storeUri;
  final int currentBuildNumber;
  final int minimumBuildNumber;
  final String title;
  final String message;
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
  AppUpdateService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static const String _androidEnabledKey = 'force_update_android';
  static const String _iosEnabledKey = 'force_update_ios';
  static const String _androidMinimumBuildKey = 'minimum_android_build_number';
  static const String _iosMinimumBuildKey = 'minimum_ios_build_number';
  static const String _androidStoreUrlKey = 'android_store_url';
  static const String _iosStoreUrlKey = 'ios_store_url';
  static const String _titleKey = 'force_update_title';
  static const String _messageKey = 'force_update_message';

  static const String _defaultAndroidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.myreklam.app';
  static const String _defaultTitle = 'Mise à jour requise';
  static const String _defaultMessage =
      'Une nouvelle version de Myreklam est disponible. '
      'Mettez à jour l’application pour continuer.';

  final FirebaseRemoteConfig _remoteConfig;

  Future<AppUpdateRequirement?> checkForRequiredUpdate() async {
    final platform = _currentPlatform();
    if (platform == null) return null;

    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 4),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await _remoteConfig.setDefaults(const {
        _androidEnabledKey: false,
        _iosEnabledKey: false,
        _androidMinimumBuildKey: 0,
        _iosMinimumBuildKey: 0,
        _androidStoreUrlKey: _defaultAndroidStoreUrl,
        _iosStoreUrlKey: '',
        _titleKey: _defaultTitle,
        _messageKey: _defaultMessage,
      });

      try {
        await _remoteConfig.fetchAndActivate();
      } catch (error) {
        debugPrint(
          'Remote Config indisponible, utilisation des valeurs en cache: '
          '$error',
        );
      }

      final enabled = _remoteConfig.getBool(
        platform == AppStorePlatform.android
            ? _androidEnabledKey
            : _iosEnabledKey,
      );
      if (!enabled) return null;

      final minimumBuildNumber = _remoteConfig.getInt(
        platform == AppStorePlatform.android
            ? _androidMinimumBuildKey
            : _iosMinimumBuildKey,
      );
      final packageInfo = await PackageInfo.fromPlatform();

      if (!AppUpdatePolicy.isBuildOutdated(
        currentBuildNumber: packageInfo.buildNumber,
        minimumBuildNumber: minimumBuildNumber,
      )) {
        return null;
      }

      final storeUrl = _remoteConfig
          .getString(
            platform == AppStorePlatform.android
                ? _androidStoreUrlKey
                : _iosStoreUrlKey,
          )
          .trim();
      final storeUri = Uri.tryParse(storeUrl);
      if (storeUri == null || !storeUri.hasScheme) {
        debugPrint(
          'Mise à jour forcée ignorée: URL du store absente ou invalide.',
        );
        return null;
      }

      return AppUpdateRequirement(
        platform: platform,
        storeUri: storeUri,
        currentBuildNumber: int.parse(packageInfo.buildNumber.trim()),
        minimumBuildNumber: minimumBuildNumber,
        title: _remoteConfig.getString(_titleKey).trim().isEmpty
            ? _defaultTitle
            : _remoteConfig.getString(_titleKey).trim(),
        message: _remoteConfig.getString(_messageKey).trim().isEmpty
            ? _defaultMessage
            : _remoteConfig.getString(_messageKey).trim(),
      );
    } catch (error, stackTrace) {
      debugPrint('Vérification de mise à jour impossible: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  AppStorePlatform? _currentPlatform() {
    if (kIsWeb) return null;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AppStorePlatform.android,
      TargetPlatform.iOS => AppStorePlatform.ios,
      _ => null,
    };
  }
}
