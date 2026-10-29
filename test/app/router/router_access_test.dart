import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/router/app_router.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';

void main() {
  group('isAllowedForRole', () {
    test('admin can reach the dashboard and every /admin/ sub-route', () {
      expect(isAllowedForRole('/admin', AppRole.admin), isTrue);
      expect(isAllowedForRole('/admin/providers', AppRole.admin), isTrue);
      expect(isAllowedForRole('/admin/orders', AppRole.admin), isTrue);
      expect(isAllowedForRole('/admin/finance', AppRole.admin), isTrue);
    });

    test('admin cannot reach customer or provider areas', () {
      expect(isAllowedForRole('/customer', AppRole.admin), isFalse);
      expect(isAllowedForRole('/provider', AppRole.admin), isFalse);
    });

    test('provider keeps access to its own sub-routes only', () {
      expect(isAllowedForRole('/provider', AppRole.provider), isTrue);
      expect(isAllowedForRole('/provider/stats', AppRole.provider), isTrue);
      expect(isAllowedForRole('/admin/finance', AppRole.provider), isFalse);
    });
  });
}
