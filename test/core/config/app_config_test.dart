import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('uses Android emulator fallback only outside release', () {
      final config = AppConfig.fromRaw('', isRelease: false);

      expect(config.apiBaseUrl, 'http://10.0.2.2:3000');
    });

    test('requires an explicitly configured HTTPS origin in release', () {
      expect(
        () => AppConfig.fromRaw('', isRelease: true),
        throwsFormatException,
      );
      expect(
        () => AppConfig.fromRaw('http://api.example.test', isRelease: true),
        throwsFormatException,
      );

      final config = AppConfig.fromRaw(
        'https://api.example.test/',
        isRelease: true,
      );
      expect(config.apiBaseUrl, 'https://api.example.test');
    });

    test('rejects credentials, path, query, and fragment', () {
      for (final value in [
        'https://user:pass@api.example.test',
        'https://api.example.test/v1',
        'https://api.example.test?token=secret',
        'https://api.example.test#fragment',
      ]) {
        expect(
          () => AppConfig.fromRaw(value, isRelease: false),
          throwsFormatException,
          reason: value,
        );
      }
    });
  });
}
