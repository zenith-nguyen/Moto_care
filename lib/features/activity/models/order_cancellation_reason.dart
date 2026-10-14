import 'package:flutter/foundation.dart';

/// A validated cancellation reason with stable codes for a future API adapter.
@immutable
class OrderCancellationReason {
  const OrderCancellationReason._({
    required this.code,
    required this.label,
    required this.details,
  });

  static const options = <String, String>{
    'long_wait': 'Thời gian thợ di chuyển quá lâu',
    'resolved_elsewhere': 'Tôi đã tự xử lý / tìm được tiệm khác',
    'mechanic_unavailable': 'Thợ không liên lạc được / báo bận',
    'changed_plan': 'Đổi ý / Muốn thay đổi vị trí sự cố',
    'other': 'Lý do khác...',
  };

  final String code;
  final String label;
  final String details;

  static OrderCancellationReason? tryCreate({
    String? selectedReason,
    String details = '',
  }) {
    final note = details.trim();
    final code = selectedReason ?? 'other';
    final label = options[code];
    if (label == null || (code == 'other' && note.isEmpty)) return null;
    return OrderCancellationReason._(code: code, label: label, details: note);
  }

  String get description => code == 'other'
      ? details
      : details.isEmpty
      ? label
      : '$label\n$details';

  factory OrderCancellationReason.fromJson(Map<String, dynamic> json) {
    final reason = tryCreate(
      selectedReason: json['code'] as String,
      details: json['details'] as String? ?? '',
    );
    if (reason == null) {
      throw const FormatException('Invalid cancellation reason');
    }
    return reason;
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'label': label,
    'details': details,
  };
}
