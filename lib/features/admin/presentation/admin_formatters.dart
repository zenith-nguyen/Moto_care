import 'package:intl/intl.dart';

import '../../../core/money/money_amount.dart';

final _adminCurrency = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
  decimalDigits: 0,
);

final _adminDate = DateFormat('dd/MM/yyyy');

String formatAdminMoney(MoneyAmount amount) {
  final value = int.tryParse(amount.value.split('.').first) ?? 0;
  return _adminCurrency.format(value);
}

String formatAdminDate(DateTime value) => _adminDate.format(value.toLocal());
