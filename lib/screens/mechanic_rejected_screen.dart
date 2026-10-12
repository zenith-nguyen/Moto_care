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
          padding: const EdgeInsets.fromLTRB(22, 32, 22, 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: IconCircle(
                          icon: Icons.close,
                          size: 112,
                          background: AppColors.dangerSoft,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Center(
                        child: Text(
                          'Hồ sơ chưa được duyệt',
                          textAlign: TextAlign.center,
                          style: appText(23, weight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Vui lòng bổ sung các mục dưới đây rồi gửi lại hồ sơ',
                          textAlign: TextAlign.center,
                          style: appText(14.5, color: AppColors.textSub, height: 1.45),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFAFA),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: const Color(0xFFF6D5D8), width: 1.6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lý do từ chối',
                              style: appText(15, weight: FontWeight.w600, color: AppColors.danger),
                            ),
                            const SizedBox(height: 6),
                            Text(MockData.rejectReason, style: appText(15, height: 1.55)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SurfaceCard(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cần bổ sung', style: appText(15, weight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    MockData.rejectRequirement,
                                    style: appText(15, weight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _reuploaded
                                    ? const StatusBadge.success('Đã tải lên', icon: Icons.check)
                                    : OutlinedButton(
                                        onPressed: () => setState(() => _reuploaded = true),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.danger,
                                          side: const BorderSide(
                                            color: AppColors.danger,
                                            width: 1.5,
                                          ),
                                          shape: const StadiumBorder(),
                                          padding: const EdgeInsets.symmetric(horizontal: 18),
                                          minimumSize: const Size(0, 40),
                                        ),
                                        child: Text(
                                          'Tải lại ảnh',
                                          style: appText(
                                            14,
                                            weight: FontWeight.w600,
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ),
                              ],
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
