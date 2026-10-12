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

/// Số tiền có dấu, cách một khoảng trắng như thiết kế: "+ 131.000đ", "- 500.000đ".
String formatSignedVnd(int amount, {required bool plus}) =>
    '${plus ? '+' : '-'} ${formatVnd(amount)}';

/// 2450000 -> "2.45tr", 1850000 -> "1.85tr", 800000 -> "800k", 68000 -> "68k".
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

/// Nhãn cố định T2..CN theo chỉ số 0..6.
String weekdayLabelAt(int index) => _weekdays[index];

String formatHm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// "Hôm nay · 08:33" hoặc "11/10 · 14:10".
String formatDayTime(DateTime t, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final diff = DateTime(n.year, n.month, n.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  final hm = formatHm(t);
  if (diff == 0) return 'Hôm nay · $hm';
  return '${_two(t.day)}/${_two(t.month)} · $hm';
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

/// "0905551298" -> "090• ••• •98".
String maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 6) return phone;
  return '${digits.substring(0, 3)}• ••• •${digits.substring(digits.length - 2)}';
}

/// "thokhang@motocare.vn" -> "th••••@motocare.vn".
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  final keep = at >= 2 ? 2 : 1;
  return '${email.substring(0, keep)}••••${email.substring(at)}';
}

/// "Minh Khang" -> "MK", "Minh Anh" -> "MA", "An" -> "A".
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
