import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef SessionExpiredCallback = void Function();

abstract class SecureKeyValueStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll(Iterable<String> keys);
}

class FlutterSecureStorageAdapter implements SecureKeyValueStore {
  FlutterSecureStorageAdapter()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll(Iterable<String> keys) async {
    for (final key in keys) {
      await _storage.delete(key: key);
    }
  }

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class SessionManager {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'access_token_expiry';
  static const String _userDataKey = 'user_data';

  static SecureKeyValueStore? _secureStoreOverride;
  static SessionExpiredCallback? _onSessionExpired;

  static void configure({SecureKeyValueStore? secureStore}) {
    _secureStoreOverride = secureStore;
  }

  static SecureKeyValueStore get _secureStore =>
      _secureStoreOverride ?? FlutterSecureStorageAdapter();

  static void registerSessionExpiredCallback(SessionExpiredCallback callback) {
    _onSessionExpired = callback;
  }

  static Future<bool> saveSession({
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? userData,
  }) async {
    final tokenSaved = await saveToken(accessToken);
    if (!tokenSaved) {
      return false;
    }

    final refreshSaved = await saveRefreshToken(refreshToken);
    if (!refreshSaved) {
      return false;
    }

    if (userData != null) {
      final userSaved = await saveUserData(userData);
      if (!userSaved) {
        await logout();
        return false;
      }
    }

    return true;
  }

  static Future<bool> saveToken(String token) async {
    try {
      await _secureStore.write(_tokenKey, token);
      await _persistExpiryFromToken(token);
      return true;
    } catch (e) {
      print('Error saving token: $e');
      return false;
    }
  }

  static Future<bool> saveRefreshToken(String? token) async {
    try {
      if (token == null || token.isEmpty) {
        await _secureStore.delete(_refreshTokenKey);
        return true;
      }
      await _secureStore.write(_refreshTokenKey, token);
      return true;
    } catch (e) {
      print('Error saving refresh token: $e');
      return false;
    }
  }

  static Future<String?> getToken() async {
    try {
      return _secureStore.read(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return _secureStore.read(_refreshTokenKey);
    } catch (e) {
      print('Error getting refresh token: $e');
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    return !isTokenExpired(token);
  }

  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userDataKey, json.encode(userData));
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        return json.decode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _secureStore
          .deleteAll({_tokenKey, _refreshTokenKey, _tokenExpiryKey});
      await prefs.remove(_userDataKey);
      return true;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  static Future<bool> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _secureStore
          .deleteAll({_tokenKey, _refreshTokenKey, _tokenExpiryKey});
      return await prefs.clear();
    } catch (e) {
      print('Error clearing session: $e');
      return false;
    }
  }

  static Future<void> handleExpiredSession() async {
    await logout();
    _onSessionExpired?.call();
  }

  static Future<DateTime?> getAccessTokenExpiry() async {
    try {
      final raw = await _secureStore.read(_tokenExpiryKey);
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    } catch (e) {
      print('Error reading token expiry: $e');
      return null;
    }
  }

  static bool isTokenExpired(
    String token, {
    Duration tolerance = const Duration(minutes: 1),
  }) {
    final expiry = _extractExpiry(token);
    if (expiry == null) return false;
    final now = DateTime.now().toUtc();
    return now.isAfter(expiry.subtract(tolerance));
  }

  static Future<bool> isStoredTokenExpired({
    Duration tolerance = const Duration(minutes: 1),
  }) async {
    final token = await getToken();
    if (token == null) return true;
    return isTokenExpired(token, tolerance: tolerance);
  }

  static Future<void> _persistExpiryFromToken(String token) async {
    try {
      final expiry = _extractExpiry(token);
      if (expiry == null) {
        await _secureStore.delete(_tokenExpiryKey);
      } else {
        await _secureStore.write(
          _tokenExpiryKey,
          expiry.toIso8601String(),
        );
      }
    } catch (e) {
      print('Error saving token expiry: $e');
    }
  }

  static DateTime? _extractExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = json.decode(
        utf8.decode(base64Url.decode(normalized)),
      ) as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      } else if (exp is double) {
        return DateTime.fromMillisecondsSinceEpoch(
          (exp * 1000).round(),
          isUtc: true,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
