import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/photo_attachment_field.dart';
import '../../../core/widgets/service_scaffold.dart';
import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../providers/compensation_provider.dart';

class CamKetDichVuScreen extends ConsumerStatefulWidget {
  const CamKetDichVuScreen({super.key});

  @override
  ConsumerState<CamKetDichVuScreen> createState() => _CamKetDichVuScreenState();
}

class _CamKetDichVuScreenState extends ConsumerState<CamKetDichVuScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  String? _orderId;
  Uint8List? _evidence;
  bool _submitted = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitted || !_form.currentState!.validate()) return;
    final order = ref.read(activityProvider).orderById(_orderId);
    if (order == null || order.status == RescueOrderStatus.cancelled) {
      showServiceMessage(context, 'Đơn không còn phù hợp để gửi báo cáo.');
      return;
    }
    FocusScope.of(context).unfocus();
    ref
        .read(compensationReportsProvider.notifier)
        .submit(
          CompensationReport(
            orderId: _orderId!,
            description: _description.text.trim(),
            evidence: _evidence,
          ),
        );
    setState(() => _submitted = true);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.task_alt, color: ServiceColors.orange, size: 44),
        title: const Text('Đã ghi nhận báo cáo'),
        content: const Text(
          'Yêu cầu bồi thường được lưu trong phiên dùng thử. Vui lòng liên hệ CSKH để được hỗ trợ trực tiếp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders =
        ref
            .watch(activityProvider)
            .orders
            .where((order) => order.status != RescueOrderStatus.cancelled)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = orders.take(5).toList();
    return ServiceScaffold(
      title: 'Cam kết dịch vụ & Bồi thường',
      bottomBar: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: ServiceColors.orange),
          onPressed: _submitted || recent.isEmpty ? null : _submit,
          icon: const Icon(Icons.send_outlined),
          label: Text(
            _submitted ? 'Đã ghi nhận báo cáo' : 'Gửi báo cáo bồi thường',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.shield_outlined,
              color: ServiceColors.orange,
              size: 68,
            ),
            const SizedBox(height: 14),
            const Text(
              'Chính sách bảo vệ khách hàng MotoCare',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            for (final (icon, title, description) in const [
              (
                Icons.price_check,
                'Cam kết Giá',
                'Thợ xác nhận chi phí trước khi sửa. Bạn có quyền từ chối khoản phát sinh chưa được đồng ý.',
              ),
              (
                Icons.verified_outlined,
                'Bảo hành 7 ngày',
                'Liên hệ hỗ trợ nếu lỗi đã sửa tái diễn trong 7 ngày để được kiểm tra điều kiện bảo hành.',
              ),
              (
                Icons.badge_outlined,
                'Lý lịch Thợ',
                'Thông tin thợ được xác minh trước khi tham gia mạng lưới đối tác MotoCare.',
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: Icon(icon, color: ServiceColors.orange, size: 30),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        description,
                        style: const TextStyle(color: ServiceColors.muted),
                      ),
                    ),
                  ),
                ),
              ),
            const ServiceSectionTitle('Gửi yêu cầu bồi thường'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recent.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Chưa có đơn cứu hộ gần đây để gửi yêu cầu.',
                          ),
                        ),
                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          recent.map((order) => order.id).join(','),
                        ),
                        initialValue:
                            recent.any((order) => order.id == _orderId)
                            ? _orderId
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Mã đơn gần đây',
                        ),
                        items: [
                          for (final order in recent)
                            DropdownMenuItem(
                              value: order.id,
                              child: Text(order.orderCode),
                            ),
                        ],
                        onChanged: (value) => setState(() => _orderId = value),
                        validator: (value) => value == null
                            ? 'Vui lòng chọn mã đơn cần báo cáo.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _description,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả sự cố bồi thường',
                          hintText: 'Mô tả sự cố, thiệt hại và yêu cầu hỗ trợ',
                        ),
                        minLines: 4,
                        maxLines: 7,
                        maxLength: 1000,
                        validator: (value) => (value?.trim().length ?? 0) < 10
                            ? 'Vui lòng mô tả sự cố ít nhất 10 ký tự.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      PhotoAttachmentField(
                        label: 'Tải ảnh hóa đơn/bằng chứng',
                        onChanged: (photo) => _evidence = photo,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Báo cáo được lưu trong phiên dùng thử; chưa gửi đến bộ phận xử lý bồi thường.',
                        style: TextStyle(color: ServiceColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
