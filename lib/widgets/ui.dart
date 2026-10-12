import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Nút CTA chính dạng pill nền đen (hoặc [color] tuỳ chọn, vd. đỏ ở Tổng kết tuần).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 54,
    this.color = AppColors.ink,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.25),
          disabledForegroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        child: _ButtonLabel(label: label, icon: icon, color: Colors.white),
      ),
    );
  }
}

/// Nút viền đen dạng pill (hành động phụ).
class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 54,
    this.color = AppColors.ink,
    this.borderColor = AppColors.ink,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: onPressed == null ? AppColors.border : borderColor,
            width: 1.6,
          ),
          shape: const StadiumBorder(),
        ),
        child: _ButtonLabel(
          label: label,
          icon: icon,
          color: onPressed == null ? AppColors.textMuted : color,
        ),
      ),
    );
  }
}

/// Link dạng chữ (Đăng xuất, Hủy đề xuất, Liên hệ hỗ trợ...).
class MutedTextButton extends StatelessWidget {
  const MutedTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.ink,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(double.infinity, 48),
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: appText(15, weight: FontWeight.w600, color: color)),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon, required this.color});
  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: appText(16, weight: FontWeight.w700, color: color),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Flexible(child: text),
      ],
    );
  }
}

/// Badge bo tròn (pill) có icon tuỳ chọn.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
    this.fontSize = 12,
  });

  factory StatusBadge.verification(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.verified => const StatusBadge.success('Đã xác minh'),
      VerificationStatus.pending => const StatusBadge.pending('Chờ xác minh'),
      VerificationStatus.rejected => const StatusBadge.danger('Bị từ chối'),
    };
  }

  const StatusBadge.success(String label, {Key? key, IconData? icon})
      : this(
          key: key,
          label: label,
          foreground: AppColors.success,
          background: AppColors.successSoft,
          icon: icon,
        );

  const StatusBadge.pending(String label, {Key? key, IconData? icon})
      : this(
          key: key,
          label: label,
          foreground: AppColors.warningDark,
          background: AppColors.warningSoft,
          icon: icon,
        );

  const StatusBadge.danger(String label, {Key? key, IconData? icon})
      : this(
          key: key,
          label: label,
          foreground: AppColors.dangerDark,
          background: AppColors.dangerSoft,
          icon: icon,
        );

  const StatusBadge.neutral(String label, {Key? key, IconData? icon})
      : this(
          key: key,
          label: label,
          foreground: AppColors.ink,
          background: AppColors.surface,
          icon: icon,
        );

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: appText(fontSize, weight: FontWeight.w600, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar tròn chữ cái đầu: đen (thợ) hoặc xám nhạt (khách).
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.initials, this.size = 52, this.dark = true});

  final String initials;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? AppColors.ink : AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: appText(
          size * 0.36,
          weight: dark ? FontWeight.w600 : FontWeight.w500,
          color: dark ? Colors.white : AppColors.ink,
        ),
      ),
    );
  }
}

/// Nút icon tròn (gọi, chat, chỉ đường...). Mặc định nền xám nhạt.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.filled = false,
    this.size = 46,
    this.white = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool filled;
  final double size;

  /// Nền trắng có bóng (nút nổi trên bản đồ).
  final bool white;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? AppColors.ink
        : white
            ? Colors.white
            : AppColors.surface;
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: white ? AppShadows.soft : null,
        ),
        child: Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: size * 0.44, color: filled ? Colors.white : AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thanh tiêu đề màn hình: nút back (chevron) + tiêu đề, viền dưới mảnh.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.showBack = true,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: EdgeInsets.fromLTRB(showBack ? 8 : 24, 8, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEFEFF1))),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Quay lại',
              iconSize: 30,
              icon: const Icon(Icons.chevron_left),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
          if (showBack) const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: appText(19, weight: FontWeight.w600)),
                if (subtitle != null) Text(subtitle!, style: appText(13, color: AppColors.textSub)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Khối nền xám nhạt bo góc.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.surfaceSoft,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}

/// Card nền trắng bo góc có bóng nhẹ.
class ShadowCard extends StatelessWidget {
  const ShadowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Icon trong vòng tròn nền nhạt.
class IconCircle extends StatelessWidget {
  const IconCircle({
    super.key,
    required this.icon,
    this.size = 44,
    this.background = AppColors.surface,
    this.color = AppColors.ink,
  });

  final IconData icon;
  final double size;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.46, color: color),
    );
  }
}

/// Nhãn ô nhập liệu (xám, đậm vừa).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false, this.color = AppColors.textSub});
  final String text;
  final bool required;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: appText(14.5, weight: FontWeight.w600, color: color),
          children: [
            if (required) TextSpan(text: ' *', style: appText(14.5, color: AppColors.danger)),
          ],
        ),
      ),
    );
  }
}

/// Dòng "nhãn ........ giá trị".
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key, this.valueStyle, this.labelStyle});
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(label, style: labelStyle ?? appText(15, color: AppColors.textSub)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ?? appText(15, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.subtitle, this.trailing});
  final String text;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(text, style: appText(17, weight: FontWeight.w600))),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: appText(13, color: AppColors.textSub, height: 1.4)),
        ],
      ],
    );
  }
}

/// Cột cuộn không lazy: mọi ô trong Form luôn được build nên validate() kiểm tra đủ.
class ScrollColumn extends StatelessWidget {
  const ScrollColumn({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// Snackbar chung cho các thao tác mock.
void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Tay nắm của bottom sheet (tự vẽ để dùng được cả khi sheet không cho kéo).
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.only(top: 12, bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFDADDE1),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// Ô tick dạng viền đen, dấu check đen (theo thiết kế).
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: value ? AppColors.ink : AppColors.textMuted, width: 2),
          ),
          child: value ? const Icon(Icons.check, size: 18, color: AppColors.ink) : null,
        ),
      ),
    );
  }
}

/// Khung viền nét đứt bo góc (ô tải giấy tờ).
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    super.key,
    required this.child,
    this.radius = AppRadius.lg,
    this.color = const Color(0xFFD5D8DD),
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final double radius;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(radius: radius, color: color),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({required this.radius, required this.color});
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        Radius.circular(radius),
      ));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color;
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) => old.color != color || old.radius != radius;
}

/// Đường kẻ nét đứt ngang (ngăn các phần trong card giao dịch).
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key, this.color = const Color(0xFFD5D8DD)});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 1.6,
      child: CustomPaint(painter: _DashedLinePainter(color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.6
      ..color = color;
    for (var x = 0.0; x < size.width; x += 11) {
      canvas.drawLine(Offset(x, 0.8), Offset(x + 6, 0.8), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

/// Ảnh placeholder (nền đen + icon camera) — thay bằng Image khi có ảnh thật.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({super.key, this.width, this.height = 120, this.radius = AppRadius.md});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: AppColors.ink,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: height * 0.28,
              child: Container(color: const Color(0xFF26272B)),
            ),
            Center(
              child: Container(
                width: height * 0.4,
                height: height * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: height * 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
