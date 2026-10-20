import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/device/location_fix_validation.dart';

void main() {
  test('rejects stale GPS fixes and locations outside the service area', () {
    final now = DateTime.utc(2026, 10, 21, 1, 48);
    expect(
      isRecentLocationFix(now.subtract(const Duration(seconds: 30)), now),
      isTrue,
    );
    expect(
      isRecentLocationFix(now.subtract(const Duration(minutes: 3)), now),
      isFalse,
    );
    expect(isInHoChiMinhCity(10.7638, 106.6663), isTrue);
    expect(isInHoChiMinhCity(37.7749, -122.4194), isFalse);
  });
}
