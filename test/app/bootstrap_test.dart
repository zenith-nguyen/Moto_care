import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/bootstrap.dart';

void main() {
  group('resolveRuntimeRole', () {
    test('uses the Android flavor instead of a mismatched Dart entrypoint', () {
      expect(
        resolveRuntimeRole(
          fallback: AppRuntimeRole.customer,
          flavor: 'provider',
        ),
        AppRuntimeRole.provider,
      );
      expect(
        resolveRuntimeRole(
          fallback: AppRuntimeRole.provider,
          flavor: 'customer',
        ),
        AppRuntimeRole.customer,
      );
    });

    test('uses the entrypoint fallback when no flavor exists', () {
      expect(
        resolveRuntimeRole(fallback: AppRuntimeRole.provider),
        AppRuntimeRole.provider,
      );
    });
  });
}
