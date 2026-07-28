import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Account-delegation (a manager acting as a managed account).
  static const String _delActiveKey = 'delegation_active';
  static const String _delOwnerIdKey = 'delegation_owner_id';
  static const String _delOwnerNameKey = 'delegation_owner_name';
  static const String _delOwnerAvatarKey = 'delegation_owner_avatar';
  static const String _delPermsKey = 'delegation_permissions';
  static const String _mgrAccessKey = 'manager_access_token';
  static const String _mgrRefreshKey = 'manager_refresh_token';

  // Biometric unlock (fingerprint / Face ID) preference.
  static const String _bioEnabledKey = 'biometric_enabled';
  static const String _bioEmailKey = 'biometric_email';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _clearDelegation();
    // Biometric unlock gates a persisted session; once the session is gone
    // there is nothing to unlock, so disable it too.
    await setBiometricEnabled(false);
  }

  // ─── Biometric unlock preference ────────────────────────────────────────────

  static Future<void> setBiometricEnabled(bool enabled, {String? email}) async {
    if (enabled) {
      await _storage.write(key: _bioEnabledKey, value: 'true');
      if (email != null && email.isNotEmpty) {
        await _storage.write(key: _bioEmailKey, value: email);
      }
    } else {
      await _storage.delete(key: _bioEnabledKey);
      await _storage.delete(key: _bioEmailKey);
    }
  }

  static Future<bool> isBiometricEnabled() async {
    return (await _storage.read(key: _bioEnabledKey)) == 'true';
  }

  static Future<String?> getBiometricEmail() async {
    return _storage.read(key: _bioEmailKey);
  }

  static Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  // ─── Account delegation ─────────────────────────────────────────────────────

  /// Stash the manager's own tokens and activate the delegated owner token.
  /// The delegated token is NOT refreshable, so the active refresh token is
  /// cleared while delegated (the refresh path is delegation-aware).
  static Future<void> enterDelegation({
    required String delegatedAccessToken,
    required int ownerId,
    required String ownerName,
    String? ownerAvatar,
    required List<String> permissions,
  }) async {
    final currentAccess = await getAccessToken();
    final currentRefresh = await getRefreshToken();
    if (currentAccess != null) {
      await _storage.write(key: _mgrAccessKey, value: currentAccess);
    }
    if (currentRefresh != null) {
      await _storage.write(key: _mgrRefreshKey, value: currentRefresh);
    }

    await _storage.write(key: _accessTokenKey, value: delegatedAccessToken);
    await _storage.delete(key: _refreshTokenKey);

    await _storage.write(key: _delActiveKey, value: 'true');
    await _storage.write(key: _delOwnerIdKey, value: ownerId.toString());
    await _storage.write(key: _delOwnerNameKey, value: ownerName);
    if (ownerAvatar != null) {
      await _storage.write(key: _delOwnerAvatarKey, value: ownerAvatar);
    } else {
      await _storage.delete(key: _delOwnerAvatarKey);
    }
    await _storage.write(key: _delPermsKey, value: permissions.join(','));
  }

  /// Restore the manager's own tokens and clear the delegation state.
  static Future<void> exitDelegation() async {
    final mgrAccess = await _storage.read(key: _mgrAccessKey);
    final mgrRefresh = await _storage.read(key: _mgrRefreshKey);

    if (mgrAccess != null) {
      await _storage.write(key: _accessTokenKey, value: mgrAccess);
    }
    if (mgrRefresh != null) {
      await _storage.write(key: _refreshTokenKey, value: mgrRefresh);
    }
    await _clearDelegation();
  }

  static Future<void> _clearDelegation() async {
    await _storage.delete(key: _delActiveKey);
    await _storage.delete(key: _delOwnerIdKey);
    await _storage.delete(key: _delOwnerNameKey);
    await _storage.delete(key: _delOwnerAvatarKey);
    await _storage.delete(key: _delPermsKey);
    await _storage.delete(key: _mgrAccessKey);
    await _storage.delete(key: _mgrRefreshKey);
  }

  static Future<bool> isDelegated() async {
    return (await _storage.read(key: _delActiveKey)) == 'true';
  }

  static Future<Map<String, dynamic>?> getDelegationInfo() async {
    if (!await isDelegated()) return null;
    final perms = await _storage.read(key: _delPermsKey);
    return {
      'owner_id':
          int.tryParse(await _storage.read(key: _delOwnerIdKey) ?? '0') ?? 0,
      'owner_name': await _storage.read(key: _delOwnerNameKey) ?? '',
      'owner_avatar': await _storage.read(key: _delOwnerAvatarKey),
      'permissions': (perms == null || perms.isEmpty)
          ? <String>[]
          : perms.split(','),
    };
  }
}
