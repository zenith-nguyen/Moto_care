import 'package:flutter/material.dart';

import '../../../core/theme/revo_brand.dart';
import '../../../core/theme/revo_theme.dart';

/// Support screen with an FAQ and a lightweight, on-device "REVO assistant"
/// chatbot. The assistant is rule-based and runs entirely on the client (no
/// backend), giving quick canned answers to the most common provider questions.
class ProviderSupportScreen extends StatefulWidget {
  const ProviderSupportScreen({super.key});

  @override
  State<ProviderSupportScreen> createState() => _ProviderSupportScreenState();
}

class _ProviderSupportScreenState extends State<ProviderSupportScreen> {
  final List<({bool fromBot, String text})> _messages = [
    (
      fromBot: true,
      text: 'Chào bạn! Mình là trợ lý REVO. Chọn một câu hỏi bên dưới nhé.',
    ),
  ];

  static const _faqs = <(String, String)>[
    (
      'Vì sao tôi không nhận được đơn?',
      'Hãy kiểm tra: tài khoản đã được duyệt, đang bật trực tuyến, đã cấp '
          'quyền vị trí và GPS mới (dưới 2 phút), và nằm trong bán kính nhận '
          'đơn. Mở app để nhận đơn realtime.',
    ),
    (
      'Khi nào tôi nhận được tiền?',
      'Sau khi hoàn tất đơn, số dư vào ví. Bạn tạo yêu cầu rút, admin duyệt và '
          'chuyển khoản, rồi đối soát. Xem tab Ví để theo dõi trạng thái.',
    ),
    (
      'Làm sao để thêm dịch vụ?',
      'Vào tab Tài khoản → Quản lý dịch vụ, chọn các dịch vụ bạn nhận. Dịch vụ '
          'mới cần quản trị viên duyệt trước khi áp dụng.',
    ),
    (
      'Làm sao để lên hạng?',
      'Hoàn tất nhiều đơn đúng hẹn và giữ đánh giá cao. Xem tiến độ ở mục '
          'Thống kê & đánh giá.',
    ),
  ];

  void _ask(String question, String answer) {
    setState(() {
      _messages.add((fromBot: false, text: question));
      _messages.add((fromBot: true, text: answer));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hỗ trợ')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final message in _messages) _Bubble(message: message),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Câu hỏi thường gặp', style: RevoTypography.caption),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (question, answer) in _faqs)
                      ActionChip(
                        label: Text(
                          question,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _ask(question, answer),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: RevoBrandColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cần thêm trợ giúp? Gọi tổng đài 1900 0000 (8:00–21:00).',
                      style: RevoTypography.caption,
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ({bool fromBot, String text}) message;

  @override
  Widget build(BuildContext context) {
    final fromBot = message.fromBot;
    return Align(
      alignment: fromBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: fromBot
              ? RevoBrandColors.surfaceSoft
              : RevoBrandColors.primary,
          borderRadius: BorderRadius.circular(RevoRadius.md),
        ),
        child: Text(
          message.text,
          style: RevoTypography.body.copyWith(
            color: fromBot ? RevoBrandColors.ink : Colors.white,
          ),
        ),
      ),
    );
  }
}
