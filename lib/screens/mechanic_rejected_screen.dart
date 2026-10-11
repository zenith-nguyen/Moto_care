import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'mechanic_pending_approval_screen.dart';

class MechanicRejectedScreen extends StatefulWidget {
  const MechanicRejectedScreen({super.key});

  @override
  State<MechanicRejectedScreen> createState() => _MechanicRejectedScreenState();
}

class _MechanicRejectedScreenState extends State<MechanicRejectedScreen> {
  bool _reuploaded = false;

  void _resubmit() {
    if (!_reuploaded) {
      showAppSnack(context, 'Vui lòng tải lại ảnh cần bổ sung trước khi gửi');
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MechanicPendingApprovalScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 36),
                      const Center(child: IconCircle(icon: Icons.highlight_off, size: 108)),
                      const SizedBox(height: 28),
                      Center(
                        child: Text(
                          'Hồ sơ chưa được duyệt',
                          textAlign: TextAlign.center,
                          style: appText(25, weight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Admin đã xem xét hồ sơ và cần bạn bổ sung thêm thông tin trước khi duyệt lại.',
                        textAlign: TextAlign.center,
                        style: appText(15.5, color: AppColors.textSub, height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.danger, width: 1.4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lý do từ chối',
                              style:
                                  appText(15, weight: FontWeight.w800, color: AppColors.dangerDark),
                            ),
                            const SizedBox(height: 6),
                            Text(MockData.rejectReason, style: appText(15, height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Cần bổ sung', style: appText(16, weight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      SurfaceCard(
                        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                MockData.rejectRequirement,
                                style: appText(14.5, height: 1.4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _reuploaded
                                ? const StatusBadge.success('Đã tải lên', icon: Icons.check)
                                : FilledButton.icon(
                                    onPressed: () => setState(() => _reuploaded = true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.ink,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      minimumSize: const Size(0, 44),
                                    ),
                                    icon: const Icon(Icons.file_upload_outlined, size: 20),
                                    label: Text(
                                      'Tải lại ảnh',
                                      style:
                                          appText(14, weight: FontWeight.w800, color: Colors.white),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PrimaryButton(label: 'Bổ sung hồ sơ', onPressed: _resubmit),
              const SizedBox(height: 6),
              MutedTextButton(
                label: 'Liên hệ hỗ trợ',
                onPressed: () =>
                    showAppSnack(context, 'Tổng đài hỗ trợ Thợ: ${MockData.supportHotline}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
