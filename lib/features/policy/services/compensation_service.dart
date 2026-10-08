import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/compensation_report.dart';

final compensationServiceProvider = Provider<CompensationService>(
  (ref) => const CompensationService(),
);

class CompensationService {
  const CompensationService();
  String? validateOrder(String? value) =>
      value == null ? 'Vui lòng chọn mã đơn cần báo cáo.' : null;
  String? validateDescription(String? value) => (value?.trim().length ?? 0) < 10
      ? 'Vui lòng mô tả sự cố ít nhất 10 ký tự.'
      : null;
  CompensationReport create(
    String orderId,
    String description,
    Uint8List? evidence,
  ) {
    if (validateOrder(orderId) != null ||
        validateDescription(description) != null) {
      throw ArgumentError('Incomplete compensation report');
    }
    return CompensationReport(
      orderId: orderId,
      description: description.trim(),
      evidence: evidence,
    );
  }
}
