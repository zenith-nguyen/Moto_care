import 'package:flutter/services.dart';
import 'format.dart';

int parseAmount(String value) =>
    int.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 0;

class AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) return oldValue;
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = formatNumber(int.parse(digits));
    final cursor =
        newValue.selection.extentOffset.clamp(0, newValue.text.length);
    final before =
        newValue.text.substring(0, cursor).replaceAll(RegExp(r'\D'), '').length;
    var consumed = 0;
    var offset = 0;
    while (offset < formatted.length && consumed < before) {
      if (RegExp(r'\d').hasMatch(formatted[offset])) consumed++;
      offset++;
    }
    return TextEditingValue(
        text: formatted, selection: TextSelection.collapsed(offset: offset));
  }
}
