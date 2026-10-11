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

/// 2450000 -> "2.45tr", 1800000 -> "1.8tr", 350000 -> "350k".
String formatShortVnd(int amount) {
  if (amount >= 1000000) {
    var s = (amount / 1000000).toStringAsFixed(2);
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return '${s}tr';
  }
  return '${(amount / 1000).round()}k';
}

String _two(int n) => n.toString().padLeft(2, '0');

const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// Nhãn thứ trong tuần: DateTime.monday -> "T2", DateTime.sunday -> "CN".
String weekdayLabel(DateTime t) => _weekdays[t.weekday - 1];

String formatHm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// "Hôm nay, 16:42" / "Hôm qua, 20:05" / "T3, 09:12" (trong tuần) / "05/10, 09:00".
String formatDayTime(DateTime t, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final diff = DateTime(n.year, n.month, n.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  final hm = formatHm(t);
  if (diff == 0) return 'Hôm nay, $hm';
  if (diff == 1) return 'Hôm qua, $hm';
  if (diff > 1 && diff < 7) return '${weekdayLabel(t)}, $hm';
  return '${_two(t.day)}/${_two(t.month)}, $hm';
}

/// Duration -> "mm:ss" (phút có thể vượt 59).
String formatMmSs(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${_two(total ~/ 60)}:${_two(total % 60)}';
}

/// Duration -> "m:ss" (dùng trong vòng đếm ngược 10 phút: "9:12").
String formatMSs(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${total ~/ 60}:${_two(total % 60)}';
}

/// "0900000012" -> "090 xxx xx12".
String maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 5) return phone;
  return '${digits.substring(0, 3)} xxx xx${digits.substring(digits.length - 2)}';
}

/// "nguyenphat@gmail.com" -> "n***@gmail.com".
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  return '${email[0]}***${email.substring(at)}';
}
