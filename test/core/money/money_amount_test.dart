import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/money/money_amount.dart';

void main() {
  test('accepts canonical non-negative decimal strings', () {
    expect(MoneyAmount.parse('0.00').value, '0.00');
    expect(MoneyAmount.parse('100000.00').value, '100000.00');
  });

  test('rejects floating point, negative, and non-canonical money', () {
    for (final value in <Object?>[100000.0, '-1.00', '01.00', '100000']) {
      expect(() => MoneyAmount.parse(value), throwsFormatException);
    }
  });
}
