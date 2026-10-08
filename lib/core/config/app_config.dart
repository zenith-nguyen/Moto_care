import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._(this.apiBaseUri);

  static const _definedApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _debugFallback = 'http://10.0.2.2:3000';

  final Uri apiBaseUri;

  String get apiBaseUrl => apiBaseUri.toString();

  factory AppConfig.fromEnvironment() {
    return AppConfig.fromRaw(_definedApiBaseUrl, isRelease: kReleaseMode);
  }

  @visibleForTesting
  factory AppConfig.fromRaw(String rawValue, {required bool isRelease}) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      if (isRelease) {
        throw const FormatException(
          'API_BASE_URL is required for release builds.',
        );
      }
      return AppConfig._(Uri.parse(_debugFallback));
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

    return AppConfig._(uri.replace(path: ''));
  }
}
