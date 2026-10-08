import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Banner cảnh báo thời tiết (nền cam nhạt). Hiển thị khi isRainIncoming = true.
class WeatherBanner extends StatelessWidget {
  const WeatherBanner({
    super.key,
    this.message = 'Trời sắp mưa — nhiều xe hư hơn, đừng tắt nhận đơn nhé!',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.op(0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.op(0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.thunderstorm_outlined,
              size: 22,
              color: Color(0xFF9A5B00),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: appText(13.5, weight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
