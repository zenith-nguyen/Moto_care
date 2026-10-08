import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/photo_attachment_field.dart';
import '../../../core/widgets/service_scaffold.dart';
import '../providers/compensation_draft_provider.dart';
import '../services/compensation_service.dart';

class CamKetDichVuScreen extends ConsumerStatefulWidget {
  const CamKetDichVuScreen({super.key});

  @override
  ConsumerState<CamKetDichVuScreen> createState() => _CamKetDichVuScreenState();
}

class _CamKetDichVuScreenState extends ConsumerState<CamKetDichVuScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _draftKey = Object();
  CompensationDraftController get _controller =>
      ref.read(compensationDraftProvider(_draftKey).notifier);
  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_controller.submit(_description.text)) {
      showServiceMessage(context, 'Đơn không còn phù hợp để gửi báo cáo.');
      return;
    }
    FocusScope.of(context).unfocus();
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
    final draft = ref.watch(compensationDraftProvider(_draftKey));
    final service = ref.watch(compensationServiceProvider);
    final recent = ref.watch(recentCompensationOrdersProvider);
    final commitments = ref.watch(commitmentsProvider);
    return ServiceScaffold(
      title: 'Cam kết dịch vụ & Bồi thường',
      bottomBar: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: ServiceColors.orange),
          onPressed: draft.submitted || recent.isEmpty ? null : _submit,
          icon: const Icon(Icons.send_outlined),
          label: Text(
            draft.submitted ? 'Đã ghi nhận báo cáo' : 'Gửi báo cáo bồi thường',
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
            for (final (index, (title, description)) in commitments.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: Icon(
                      const [
                        Icons.price_check,
                        Icons.verified_outlined,
                        Icons.badge_outlined,
                      ][index % 3],
                      color: ServiceColors.orange,
                      size: 30,
                    ),
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
                            recent.any((order) => order.id == draft.orderId)
                            ? draft.orderId
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
                        onChanged: _controller.selectOrder,
                        validator: service.validateOrder,
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
                        validator: service.validateDescription,
                      ),
                      const SizedBox(height: 16),
                      PhotoAttachmentField(
                        label: 'Tải ảnh hóa đơn/bằng chứng',
                        onChanged: _controller.attachEvidence,
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
