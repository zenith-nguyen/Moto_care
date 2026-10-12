import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Hiển thị bottom sheet "Hồ sơ đối tác đã được duyệt!" trên nền mờ.
/// Trả về true nếu thợ chọn "Sang giao diện Thợ".
Future<bool?> showApprovedRedirectDialog(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => const ApprovedRedirectDialog(),
  );
}

class ApprovedRedirectDialog extends StatelessWidget {
  const ApprovedRedirectDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            const SizedBox(height: 12),
            const IconCircle(
              icon: Icons.check,
              size: 84,
              background: AppColors.successSoft,
              color: AppColors.success,
            ),
            const SizedBox(height: 22),
            Text(
              'Hồ sơ đối tác đã được duyệt!',
              textAlign: TextAlign.center,
              style: appText(21, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'Bạn có muốn chuyển sang Giao diện Thợ để bắt đầu nhận đơn ngay không?',
              textAlign: TextAlign.center,
              style: appText(15, color: AppColors.textSub, height: 1.5),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: OutlineActionButton(
                    label: 'Để sau',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: PrimaryButton(
                    label: 'Sang giao diện Thợ',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: appState,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Switch(
                    value: appState.autoOpenMechanic,
                    onChanged: appState.setAutoOpenMechanic,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.ink,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: AppColors.border,
                    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Lần đăng nhập sau tự vào giao diện Thợ',
                      style: appText(14, color: AppColors.textSub),
                    ),
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
