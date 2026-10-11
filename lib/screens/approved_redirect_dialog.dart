import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Hiển thị dialog "Hồ sơ đối tác đã được duyệt" trên nền mờ.
/// Trả về true nếu thợ chọn "Sang giao diện Thợ".
Future<bool?> showApprovedRedirectDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const ApprovedRedirectDialog(),
  );
}

class ApprovedRedirectDialog extends StatelessWidget {
  const ApprovedRedirectDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hồ sơ đối tác đã được duyệt', style: appText(20, weight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              'Bạn muốn sang Màn hình Thợ để nhận đơn ngay?',
              style: appText(15.5, color: AppColors.textSub, height: 1.45),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.border, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text('Để sau', style: appText(15, weight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: FittedBox(
                        child: Text(
                          'Sang giao diện Thợ',
                          style: appText(15, weight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
