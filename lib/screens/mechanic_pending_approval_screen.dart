import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/ui.dart';
import 'mechanic_login_screen.dart';

class MechanicPendingApprovalScreen extends StatelessWidget {
  const MechanicPendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const IconCircle(
                        icon: Icons.schedule,
                        size: 112,
                        background: AppColors.warningSoft,
                        color: AppColors.warningDark,
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Hồ sơ đang chờ duyệt',
                        textAlign: TextAlign.center,
                        style: appText(23, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Admin đang xem xét hồ sơ của bạn. Thời gian xử lý thường trong vòng '
                        '24 giờ làm việc.',
                        textAlign: TextAlign.center,
                        style: appText(15, color: AppColors.textSub, height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      const SurfaceCard(
                        padding: EdgeInsets.fromLTRB(18, 16, 18, 16),
                        radius: AppRadius.md,
                        child: StepProgressBar(
                          current: 2,
                          steps: ['Đã gửi', 'Đang xét duyệt', 'Hoàn tất'],
                          accent: AppColors.warningDark,
                          centeredSteps: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              OutlineActionButton(
                label: 'Liên hệ hỗ trợ',
                onPressed: () =>
                    showAppSnack(context, 'Tổng đài hỗ trợ Thợ: ${MockData.supportHotline}'),
              ),
              const SizedBox(height: 6),
              MutedTextButton(
                label: 'Đăng xuất',
                color: AppColors.danger,
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MechanicLoginScreen()),
                  (_) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
