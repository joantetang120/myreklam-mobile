import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  /// Compares two marketing versions (`1.1.5`), used on iOS where the App Store
  /// exposes the version name rather than a build number.
  ///
  /// Fails open, like [isBuildOutdated]: anything unparseable returns false, so
  /// a malformed store answer never locks users out of the app.
  static bool isVersionOutdated({
    required String currentVersion,
    required String storeVersion,
  }) {
    final current = _parseVersion(currentVersion);
    final store = _parseVersion(storeVersion);
    if (current.isEmpty || store.isEmpty) return false;

    for (var i = 0; i < (current.length > store.length ? current.length : store.length); i++) {
      final a = i < current.length ? current[i] : 0;
      final b = i < store.length ? store[i] : 0;
      if (a != b) return a < b;
    }
    return false;
  }

  /// `1.1.5+22` and `1.1.5 (22)` both reduce to `[1, 1, 5]`.
  static List<int> _parseVersion(String value) {
    final numeric = value.trim().split(RegExp(r'[+\s(]')).first;
    if (numeric.isEmpty) return const [];
    final parts = <int>[];
    for (final segment in numeric.split('.')) {
      final parsed = int.tryParse(segment.trim());
      if (parsed == null) return const [];
      parts.add(parsed);
    }
    return parts;
  }
}

/// What the App Store reports for a bundle identifier.
class AppStoreRelease {
  const AppStoreRelease({required this.version, required this.storeUri});

  final String version;
  final Uri storeUri;
}

class AppUpdateService {
  AppUpdateService({http.Client? httpClient}) : _httpClient = httpClient;

  /// Injected in tests; a one-shot client is created per call otherwise.
  final http.Client? _httpClient;

  static const _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.myreklam.app';

  /// Store front used for the lookup. The App Store is regional: querying the
  /// wrong country can return no result even for a published app.
  static const _iosStoreCountry = 'fr';

  static const _lookupTimeout = Duration(seconds: 8);

  Future<AppUpdateRequirement?> checkForRequiredUpdate() async {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _checkGooglePlay();
      case TargetPlatform.iOS:
        return _checkAppStore();
      default:
        return null;
    }
  }

  Future<AppUpdateRequirement?> _checkGooglePlay() async {
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

  Future<AppUpdateRequirement?> _checkAppStore() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final release = await fetchAppStoreRelease(packageInfo.packageName);
      if (release == null) return null;

      final outdated = AppUpdatePolicy.isVersionOutdated(
        currentVersion: packageInfo.version,
        storeVersion: release.version,
      );
      if (!outdated) return null;

      final currentBuild = int.tryParse(packageInfo.buildNumber.trim()) ?? 0;

      return AppUpdateRequirement(
        platform: AppStorePlatform.ios,
        storeUri: release.storeUri,
        currentBuildNumber: currentBuild,
        minimumBuildNumber: currentBuild + 1,
        title: 'Mise à jour requise',
        message:
            'Une nouvelle version de Myreklam est disponible sur l’App Store. '
            'Installez-la pour continuer à utiliser l’application.',
        // Apple n'expose aucun équivalent des mises à jour intégrées de Google
        // Play : on ne peut qu'ouvrir la fiche du store.
        startImmediateUpdate: null,
      );
    } catch (error, stackTrace) {
      debugPrint('Vérification App Store indisponible: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Reads the published version from Apple's public lookup endpoint.
  ///
  /// Returns null whenever the answer is unusable — offline, app not published
  /// in [_iosStoreCountry], unexpected payload — so the gate lets the user in.
  @visibleForTesting
  Future<AppStoreRelease?> fetchAppStoreRelease(String bundleId) async {
    final client = _httpClient ?? http.Client();
    try {
      final uri = Uri.https('itunes.apple.com', '/lookup', {
        'bundleId': bundleId,
        'country': _iosStoreCountry,
        // Apple caches lookups aggressively; this keeps the answer fresh enough
        // to matter on release day.
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final response = await client.get(uri).timeout(_lookupTimeout);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final results = body['results'];
      if (results is! List || results.isEmpty) return null;
      final first = results.first;
      if (first is! Map<String, dynamic>) return null;

      final version = first['version']?.toString().trim();
      if (version == null || version.isEmpty) return null;

      final trackViewUrl = first['trackViewUrl']?.toString();
      final storeUri = Uri.tryParse(trackViewUrl ?? '');

      return AppStoreRelease(
        version: version,
        storeUri: storeUri ?? Uri.parse('https://apps.apple.com/app/$bundleId'),
      );
    } finally {
      if (_httpClient == null) client.close();
    }
  }
}
