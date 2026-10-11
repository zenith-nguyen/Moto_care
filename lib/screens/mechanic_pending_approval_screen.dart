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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const IconCircle(icon: Icons.schedule, size: 108),
                        const SizedBox(height: 28),
                        Text(
                          'Hồ sơ đang chờ duyệt',
                          textAlign: TextAlign.center,
                          style: appText(25, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Admin đang xem xét hồ sơ của bạn. Quá trình này thường mất khoảng 24 giờ.',
                          textAlign: TextAlign.center,
                          style: appText(15.5, color: AppColors.textSub, height: 1.5),
                        ),
                        const SizedBox(height: 36),
                        const StepProgressBar(
                          title: 'Đang xét duyệt',
                          current: 2,
                          steps: ['Đã gửi', 'Đang xét duyệt', 'Hoàn tất'],
                        ),
                      ],
                    ),
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
