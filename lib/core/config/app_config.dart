import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._(
    this.apiBaseUri, {
    required this.pushNotificationsEnabled,
    required this.firebaseApiKey,
    required this.firebaseAppId,
    required this.firebaseMessagingSenderId,
    required this.firebaseProjectId,
  });

  static const _definedApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _debugFallback = 'http://10.0.2.2:3000';
  static const _pushEnabled = bool.fromEnvironment(
    'PUSH_NOTIFICATIONS_ENABLED',
  );
  static const _firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  final Uri apiBaseUri;
  final bool pushNotificationsEnabled;
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseMessagingSenderId;
  final String firebaseProjectId;

  String get apiBaseUrl => apiBaseUri.toString();

  factory AppConfig.fromEnvironment() {
    return AppConfig.fromRaw(
      _definedApiBaseUrl,
      isRelease: kReleaseMode,
      pushNotificationsEnabled: _pushEnabled,
      firebaseApiKey: _firebaseApiKey,
      firebaseAppId: _firebaseAppId,
      firebaseMessagingSenderId: _firebaseMessagingSenderId,
      firebaseProjectId: _firebaseProjectId,
    );
  }

  @visibleForTesting
  factory AppConfig.fromRaw(
    String rawValue, {
    required bool isRelease,
    bool pushNotificationsEnabled = false,
    String firebaseApiKey = '',
    String firebaseAppId = '',
    String firebaseMessagingSenderId = '',
    String firebaseProjectId = '',
  }) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      if (isRelease) {
        throw const FormatException(
          'API_BASE_URL is required for release builds.',
        );
      }
      return AppConfig._(
        Uri.parse(_debugFallback),
        pushNotificationsEnabled: pushNotificationsEnabled,
        firebaseApiKey: firebaseApiKey,
        firebaseAppId: firebaseAppId,
        firebaseMessagingSenderId: firebaseMessagingSenderId,
        firebaseProjectId: firebaseProjectId,
      ).._validatePush();
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('API_BASE_URL must be an absolute URL.');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const FormatException('API_BASE_URL must use HTTP or HTTPS.');
    }
    if (isRelease && uri.scheme != 'https') {
      throw const FormatException('Release API_BASE_URL must use HTTPS.');
    }
    if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) {
      throw const FormatException(
        'API_BASE_URL cannot contain credentials, a query, or a fragment.',
      );
    }
    if (uri.path.isNotEmpty && uri.path != '/') {
      throw const FormatException('API_BASE_URL cannot contain a path.');
    }

    return AppConfig._(
      uri.replace(path: ''),
      pushNotificationsEnabled: pushNotificationsEnabled,
      firebaseApiKey: firebaseApiKey,
      firebaseAppId: firebaseAppId,
      firebaseMessagingSenderId: firebaseMessagingSenderId,
      firebaseProjectId: firebaseProjectId,
    ).._validatePush();
  }

  void _validatePush() {
    if (!pushNotificationsEnabled) return;
    if ([
      firebaseApiKey,
      firebaseAppId,
      firebaseMessagingSenderId,
      firebaseProjectId,
    ].any((value) => value.trim().isEmpty)) {
      throw const FormatException(
        'Firebase build configuration is required when push notifications are enabled.',
      );
    }
  }
}
