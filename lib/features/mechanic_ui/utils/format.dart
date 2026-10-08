/// 350000 -> "350.000đ" (luôn dùng giá trị tuyệt đối, dấu +/- xử lý riêng).
String formatVnd(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${buffer.toString()}đ';
}

/// 120000 -> "+120.000đ", -6000 -> "-6.000đ".
String formatSignedVnd(int amount) =>
    '${amount < 0 ? '-' : '+'}${formatVnd(amount)}';

String formatKm(double km) => '${km.toStringAsFixed(1)} km';

String _two(int n) => n.toString().padLeft(2, '0');

/// "Hôm nay, 14:32" / "Hôm qua, 20:15" / "05/10, 09:00".
String formatTxTime(DateTime t, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  final hm = '${_two(t.hour)}:${_two(t.minute)}';
  if (diff == 0) return 'Hôm nay, $hm';
  if (diff == 1) return 'Hôm qua, $hm';
  return '${_two(t.day)}/${_two(t.month)}, $hm';
}
