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
      Icons.person_outline,
      [
        'Xác nhận đúng vị trí, mã đơn trước khi sửa',
        'Báo giá phát sinh rõ ràng, có lý do cụ thể',
        'Giữ thông tin khách hàng bảo mật',
      ],
    ),
    (
      'Trách nhiệm của Khách hàng',
      Icons.location_on_outlined,
      [
        'Cung cấp mã xác nhận đúng khi thợ đến',
        'Thanh toán đầy đủ giá cuối đã duyệt',
        'Đánh giá trung thực sau khi hoàn thành',
      ],
    ),
    (
      'Trách nhiệm của Nền tảng',
      Icons.shield_outlined,
      [
        'Ghép đơn minh bạch, không ưu tiên không rõ lý do',
        'Xử lý tranh chấp công bằng qua Admin',
        'Bảo vệ dữ liệu cá nhân hai bên',
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Text(
                    'Trước khi hoạt động trên MotoCare, vui lòng đọc và đồng ý các cam kết '
                    'trách nhiệm sau giữa các bên.',
                    style: appText(14.5, color: AppColors.textSub, height: 1.5),
                  ),
                  for (final (title, icon, items) in _sections) ...[
                    const SizedBox(height: 16),
                    SurfaceCard(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(title, style: appText(16.5, weight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final item in items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.check, color: AppColors.success, size: 19),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(item, style: appText(14.5, height: 1.4)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCheckbox(value: _agreed, onChanged: (v) => setState(() => _agreed = v)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _agreed = !_agreed),
                          child: Text(
                            'Tôi đã đọc và đồng ý với toàn bộ Điều khoản & Cam kết trên',
                            style: appText(14, color: AppColors.textSub, height: 1.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                label: 'Đồng ý & Tiếp tục',
                onPressed: _agreed ? () => Navigator.of(context).pop(true) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
