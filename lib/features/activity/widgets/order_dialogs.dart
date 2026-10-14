import 'package:flutter/material.dart';

import '../data/mock_rescue_orders.dart';
import '../models/rescue_order.dart';
import 'order_summary.dart';

typedef RebookRequest = ({String userVehicle, String locationAddress});

class RebookOrderDialog extends StatefulWidget {
  const RebookOrderDialog({super.key, required this.order});
  final RescueOrder order;

  @override
  State<RebookOrderDialog> createState() => _RebookOrderDialogState();
}

class _RebookOrderDialogState extends State<RebookOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _vehicle = TextEditingController(text: widget.order.userVehicle);
  late final _address = TextEditingController(
    text: widget.order.locationAddress,
  );

  @override
  void dispose() {
    _vehicle.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đặt cứu hộ lại'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dịch vụ: ${widget.order.serviceType.label}'),
            const SizedBox(height: 8),
            Text(
              'Phí dự kiến: ${formatOrderPrice(mockBasePrice(widget.order.serviceType))}',
            ),
            const SizedBox(height: 8),
            const Text('Chưa gồm phụ tùng phát sinh.'),
            const SizedBox(height: 20),
            TextFormField(
              controller: _vehicle,
              decoration: const InputDecoration(labelText: 'Xe cần cứu hộ'),
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập xe cần cứu hộ'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Địa chỉ cứu hộ'),
              minLines: 2,
              maxLines: 4,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập địa chỉ cứu hộ'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Đóng'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.of(context).pop<RebookRequest>((
            userVehicle: _vehicle.text.trim(),
            locationAddress: _address.text.trim(),
          ));
        },
        child: const Text('Xác nhận đặt lại'),
      ),
    ],
  );
}

class ReportOrderDialog extends StatefulWidget {
  const ReportOrderDialog({super.key, required this.orderCode});
  final String orderCode;

  @override
  State<ReportOrderDialog> createState() => _ReportOrderDialogState();
}

class _ReportOrderDialogState extends State<ReportOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Báo cáo / Khiếu nại'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đơn ${widget.orderCode}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _message,
              decoration: const InputDecoration(
                labelText: 'Nội dung khiếu nại',
                hintText: 'Mô tả vấn đề bạn gặp phải',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              validator: (value) => (value?.trim().length ?? 0) < 10
                  ? 'Vui lòng nhập ít nhất 10 ký tự'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Đóng'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.of(context).pop(_message.text.trim());
          }
        },
        child: const Text('Lưu khiếu nại'),
      ),
    ],
  );
}
