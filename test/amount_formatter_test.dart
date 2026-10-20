import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/utils/amount_formatter.dart';
import 'package:motocare_mechanic/utils/format.dart';

void main() {
  test('Grouped amount preserves its numeric value', () {
    final formatter = AmountInputFormatter();
    final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(
            text: '1000000', selection: TextSelection.collapsed(offset: 7)));
    expect(result.text, '1.000.000');
    expect(parseAmount(result.text), 1000000);
    expect(result.selection.extentOffset, result.text.length);
  });
  test(
      'Amount input handles clearing and rejects amounts above the digit limit',
      () {
    final formatter = AmountInputFormatter();
    const previous = TextEditingValue(
        text: '1.000.000', selection: TextSelection.collapsed(offset: 9));
    expect(formatter.formatEditUpdate(previous, const TextEditingValue()).text,
        '');
    expect(
        formatter.formatEditUpdate(
            previous, const TextEditingValue(text: '12345678901')),
        previous);
    expect(parseAmount(''), 0);
  });
  test('Repair time correctly rolls over an hour', () {
    expect(formatHms(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03');
    expect(formatHms(const Duration(seconds: -1)), '00:00:00');
  });
}
