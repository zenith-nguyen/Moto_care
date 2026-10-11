import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Điều khoản & Cam kết 3 bên: Thợ – Khách hàng – Nền tảng.
/// Trả về true khi thợ tích đồng ý và bấm "Đồng ý & Tiếp tục".
class TermsAndCommitmentScreen extends StatefulWidget {
  const TermsAndCommitmentScreen({super.key, this.readOnly = false, this.initiallyAgreed = false});

  /// true: mở để đọc lại (từ Tài khoản / Đăng nhập), vẫn cho phép xác nhận.
  final bool readOnly;
  final bool initiallyAgreed;

  @override
  State<TermsAndCommitmentScreen> createState() => _TermsAndCommitmentScreenState();
}

class _TermsAndCommitmentScreenState extends State<TermsAndCommitmentScreen> {
  late bool _agreed = widget.initiallyAgreed || widget.readOnly;

  static const _sections = <(String, IconData, List<String>)>[
    (
      'Trách nhiệm của Thợ',
      Icons.build_outlined,
      [
        'Chỉ nhận đơn thuộc đúng dịch vụ đã đăng ký và đủ năng lực thực hiện.',
        'Có mặt đúng thời gian đã báo, thông báo sớm nếu phát sinh trễ hẹn.',
        'Báo giá rõ ràng trước khi sửa, không thu thêm phí ngoài thỏa thuận.',
        'Giữ gìn tài sản, phương tiện của khách trong suốt quá trình sửa chữa.',
      ],
    ),
    (
      'Trách nhiệm của Khách hàng',
      Icons.person_outline,
      [
        'Cung cấp thông tin vị trí, tình trạng xe chính xác khi đặt đơn.',
        'Thanh toán đầy đủ chi phí đã xác nhận sau khi hoàn tất dịch vụ.',
        'Đối xử tôn trọng, không yêu cầu Thợ làm việc ngoài phạm vi đơn.',
      ],
    ),
    (
      'Trách nhiệm của Nền tảng',
      Icons.shield_outlined,
      [
        'Xác minh danh tính, chứng chỉ của Thợ trước khi cho phép nhận đơn.',
        'Hỗ trợ xử lý tranh chấp và bảo vệ quyền lợi hợp lý cho cả hai bên.',
        'Bảo mật thông tin cá nhân của Thợ và Khách hàng theo quy định.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Điều khoản & Cam kết'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    'Khi tham gia MotoCare với vai trò Thợ sửa xe, bạn đồng ý tuân thủ các cam kết '
                    'dưới đây giữa ba bên: Thợ, Khách hàng và Nền tảng, nhằm bảo đảm chất lượng '
                    'dịch vụ và an toàn cho tất cả mọi người.',
                    style: appText(14.5, color: AppColors.textSub, height: 1.5),
                  ),
                  for (final (title, icon, items) in _sections) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        IconCircle(
                          icon: icon,
                          size: 40,
                          background: AppColors.ink,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(title, style: appText(18, weight: FontWeight.w800))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check, color: AppColors.success, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(items[i], style: appText(14.5, height: 1.4)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _agreed = !_agreed),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreed,
                          activeColor: AppColors.ink,
                          onChanged: (v) => setState(() => _agreed = v ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Tôi đã đọc và đồng ý với các cam kết trách nhiệm giữa '
                              'Thợ – Khách hàng – Nền tảng nêu trên.',
                              style: appText(14, color: AppColors.textSub, height: 1.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Đồng ý & Tiếp tục',
                    onPressed: _agreed ? () => Navigator.of(context).pop(true) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
