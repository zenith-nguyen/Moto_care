import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/service_actions.dart';
import '../../../core/widgets/service_scaffold.dart';

const _questions = [
  (
    'Gọi SOS',
    'Tôi có thể hủy đơn cứu hộ không?',
    'Bạn có thể mở Hoạt động, chọn đơn đang diễn ra và bấm Hủy đơn. Nếu thợ đã di chuyển, hãy liên hệ thợ hoặc CSKH để xác nhận chi phí phát sinh trước khi hủy.',
  ),
  (
    'Thanh toán',
    'Làm sao khi thợ báo giá khác với app?',
    'Yêu cầu thợ giải thích từng khoản và xác nhận giá trước khi sửa. Giữ lại báo giá, hóa đơn hoặc ảnh trao đổi và gửi yêu cầu ở mục Cam kết dịch vụ & Bồi thường để được hỗ trợ.',
  ),
  (
    'Gọi SOS',
    'Ứng dụng hỗ trợ các khu vực nào?',
    'Danh sách địa điểm hiện minh họa khu vực TP. Hồ Chí Minh. Hãy liên hệ CSKH để xác nhận khả năng phục vụ tại địa chỉ của bạn.',
  ),
  (
    'Voucher',
    'Làm thế nào để sử dụng voucher?',
    'Mở Kho ưu đãi, kiểm tra hạn sử dụng và điều kiện đơn tối thiểu, rồi chọn Dùng ngay để trở về Trang chủ và bắt đầu yêu cầu cứu hộ.',
  ),
  (
    'Sự cố tài khoản',
    'Tôi cần làm gì khi quên mật khẩu?',
    'Chọn Quên mật khẩu ở màn hình đăng nhập và làm theo hướng dẫn. Nếu không nhận được mã xác minh, hãy liên hệ CSKH để được hỗ trợ.',
  ),
];

class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  String _query = '';
  final _search = TextEditingController();
  String? _topic;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions
        .where(
          (question) =>
              (_topic == null || question.$1 == _topic) &&
              normalizeServiceSearch('${question.$2} ${question.$3}')
                  .contains(_query),
        )
        .toList();
    return ServiceScaffold(
      title: 'Trung tâm trợ giúp & FAQ',
      bottomBar: LayoutBuilder(
        builder: (context, constraints) {
          final buttons = [
            FilledButton.icon(
              onPressed: () {
                final hotline = ref.read(supportHotlineProvider);
                launchServiceUri(
                  context,
                  ref,
                  Uri(scheme: 'tel', path: hotline),
                  'Không thể mở ứng dụng gọi điện. Hotline: $hotline',
                );
              },
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Gọi Hotline 24/7'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/tin-nhan'),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat với CSKH'),
            ),
          ];
          if (constraints.maxWidth < 420 ||
              MediaQuery.textScalerOf(context).scale(15) > 20) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [buttons[0], const SizedBox(height: 10), buttons[1]],
            );
          }
          return Row(
            children: [
              Expanded(child: buttons[0]),
              const SizedBox(width: 12),
              Expanded(child: buttons[1]),
            ],
          );
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ServiceSearchBar(
            controller: _search,
            hint: 'Tìm kiếm câu hỏi',
            onChanged: (value) =>
                setState(() => _query = normalizeServiceSearch(value)),
          ),
          const ServiceSectionTitle('Bạn cần hỗ trợ gì?'),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 74 + MediaQuery.textScalerOf(context).scale(62),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final (topic, icon) in const [
                ('Gọi SOS', Icons.sos_rounded),
                ('Thanh toán', Icons.payments_outlined),
                ('Voucher', Icons.local_offer_outlined),
                ('Sự cố tài khoản', Icons.manage_accounts_outlined),
              ])
                Semantics(
                  selected: _topic == topic,
                  child: Card(
                    color: _topic == topic
                        ? ServiceColors.navy
                        : ServiceColors.surface,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setState(
                        () => _topic = _topic == topic ? null : topic,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: ServiceColors.orange, size: 30),
                            const SizedBox(height: 12),
                            Text(
                              topic,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const ServiceSectionTitle('Câu hỏi phổ biến'),
          if (_topic != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _topic = null),
                icon: const Icon(Icons.clear),
                label: const Text('Xem tất cả chủ đề'),
              ),
            ),
          if (questions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Không tìm thấy câu hỏi phù hợp. Hãy thử từ khóa khác hoặc liên hệ CSKH.',
              ),
            ),
          for (final (_, question, answer) in questions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ExpansionTile(
                  key: ValueKey(question),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(
                    question,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        answer,
                        style: const TextStyle(
                          color: ServiceColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
