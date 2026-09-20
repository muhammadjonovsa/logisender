import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logisender/core/constants/app_constants.dart';

/// API configuration stored securely.
class ApiConfig {
  final int apiId;
  final String apiHash;

  const ApiConfig({required this.apiId, required this.apiHash});

  Map<String, dynamic> toJson() => {'apiId': apiId, 'apiHash': apiHash};

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    try {
      return ApiConfig(
          apiId: json['apiId'] as int, apiHash: json['apiHash'] as String);
    } catch (_) {
      return ApiConfig.empty();
    }
  }

  factory ApiConfig.empty() => const ApiConfig(apiId: 0, apiHash: '');

  bool get isEmpty => apiId == 0 || apiHash.isEmpty;
}

/// Session data stored securely.
class SessionData {
  final String authorizationKey;
  final String phoneNumber;
  final int userId;
  final String firstName;

  const SessionData({
    required this.authorizationKey,
    required this.phoneNumber,
    this.userId = 0,
    this.firstName = '',
  });

  Map<String, dynamic> toJson() => {
        'authorizationKey': authorizationKey,
        'phoneNumber': phoneNumber,
        'userId': userId,
        'firstName': firstName,
      };

  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
        authorizationKey: json['authorizationKey'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
        userId: json['userId'] as int? ?? 0,
        firstName: json['firstName'] as String? ?? '',
      );

  factory SessionData.empty() => const SessionData(authorizationKey: '', phoneNumber: '');

  bool get isEmpty => authorizationKey.isEmpty;
}

/// Secure storage wrapper for sensitive data (API keys, session tokens).
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveApiConfig(ApiConfig config) async {
    await _storage.write(key: AppConstants.apiKeyKey, value: config.apiId.toString());
    await _storage.write(key: AppConstants.apiHashKey, value: config.apiHash);
  }

  Future<ApiConfig> getApiConfig() async {
    final idStr = await _storage.read(key: AppConstants.apiKeyKey);
    final hash = await _storage.read(key: AppConstants.apiHashKey);
    if (idStr == null || hash == null) return ApiConfig.empty();
    final id = int.tryParse(idStr) ?? 0;
    return ApiConfig(apiId: id, apiHash: hash);
  }

  Future<void> saveSession(SessionData session) async {
    await _storage.write(key: AppConstants.sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<SessionData> getSession() async {
    final data = await _storage.read(key: AppConstants.sessionKey);
    if (data == null) return SessionData.empty();
    return SessionData.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  Future<void> deleteSession() async {
    await _storage.delete(key: AppConstants.sessionKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> setAutomationRunning(bool running) async {
    if (running) {
      await _storage.write(key: AppConstants.automationRunningKey, value: '1');
    } else {
      await _storage.delete(key: AppConstants.automationRunningKey);
    }
  }

  Future<bool> isAutomationRunning() async {
    final val = await _storage.read(key: AppConstants.automationRunningKey);
    return val == '1';
  }
}
