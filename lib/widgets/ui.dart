import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Nút CTA chính nền đen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
    this.light = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  /// Nút trắng chữ đen (dùng trên nền tối).
  final bool light;

  @override
  Widget build(BuildContext context) {
    final bg = light ? Colors.white : AppColors.ink;
    final fg = light ? AppColors.ink : Colors.white;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.25),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
        child: _ButtonLabel(label: label, icon: icon, color: null, size: 16),
      ),
    );
  }
}

/// Nút viền (hành động phụ).
class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
    this.color = AppColors.ink,
    this.borderColor = AppColors.border,
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
          side: BorderSide(color: borderColor, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
        child: _ButtonLabel(label: label, icon: icon, color: color, size: 16),
      ),
    );
  }
}

/// Link dạng chữ xám đậm (Đăng xuất, Hủy đề xuất...).
class MutedTextButton extends StatelessWidget {
  const MutedTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.textMuted,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      child: Text(label, style: appText(15, weight: FontWeight.w700, color: color)),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon, this.color, required this.size});
  final String label;
  final IconData? icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? DefaultTextStyle.of(context).style.color;
    final text = Text(
      label,
      style: appText(size, weight: FontWeight.w800, color: fg ?? Colors.white),
      textAlign: TextAlign.center,
    );
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
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

  factory StatusBadge.verification(VerificationStatus status, {bool withIcon = false}) {
    return switch (status) {
      VerificationStatus.verified => StatusBadge(
          label: 'Đã xác minh',
          foreground: AppColors.success,
          background: AppColors.successSoft,
          icon: withIcon ? Icons.check_circle_outline : null,
        ),
      VerificationStatus.pending => const StatusBadge(
          label: 'Chờ xác minh',
          foreground: AppColors.warningDark,
          background: AppColors.warningSoft,
        ),
      VerificationStatus.rejected => const StatusBadge(
          label: 'Bị từ chối',
          foreground: AppColors.dangerDark,
          background: AppColors.dangerSoft,
        ),
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

  const StatusBadge.pending(String label, {Key? key})
      : this(
          key: key,
          label: label,
          foreground: AppColors.warningDark,
          background: AppColors.warningSoft,
        );

  const StatusBadge.neutral(String label, {Key? key})
      : this(
          key: key,
          label: label,
          foreground: AppColors.ink,
          background: AppColors.surface,
        );

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: appText(fontSize, weight: FontWeight.w700, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar tròn: chữ cái đầu hoặc icon.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    this.initial,
    this.icon = Icons.person_outline,
    this.size = 52,
    this.dark = true,
  });

  final String? initial;
  final IconData icon;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.ink;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? AppColors.ink : Colors.white,
        shape: BoxShape.circle,
        border: dark ? null : Border.all(color: AppColors.border),
      ),
      child: initial != null
          ? Text(initial!, style: appText(size * 0.4, weight: FontWeight.w800, color: fg))
          : Icon(icon, size: size * 0.46, color: fg),
    );
  }
}

/// Nút icon tròn (gọi, chat, chỉ đường...).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.filled = false,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppColors.ink : AppColors.surface,
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
    );
  }
}

/// Nút back tròn viền xám.
class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key, this.onTap, this.icon = Icons.chevron_left});
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Quay lại',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap ?? () => Navigator.of(context).maybePop(),
          child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 24)),
        ),
      ),
    );
  }
}

/// Header màn hình con: nút back + tiêu đề.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          BackCircleButton(onTap: onBack),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: appText(22, weight: FontWeight.w800)),
          ),
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
    this.padding = const EdgeInsets.all(18),
    this.color = const Color(0xFFF9F9F9),
    this.border = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: border ? Border.all(color: AppColors.border) : null,
      ),
      child: child,
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

/// Nhãn ô nhập liệu.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false, this.trailing});
  final String text;
  final bool required;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: text,
                style: appText(15, weight: FontWeight.w700),
                children: [
                  if (required) TextSpan(text: ' *', style: appText(15, color: AppColors.danger)),
                ],
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
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
              style: valueStyle ?? appText(15, weight: FontWeight.w800),
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
            Expanded(child: Text(text, style: appText(18, weight: FontWeight.w800))),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: appText(13, color: AppColors.textSub, height: 1.35)),
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

/// Ảnh placeholder (nền đen + icon camera) — thay bằng Image khi có ảnh thật.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({super.key, this.width = 120, this.height = 88});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
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
              height: height * 0.3,
              child: Container(color: const Color(0xFF26272B)),
            ),
            Center(
              child: Container(
                width: height * 0.44,
                height: height * 0.44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: height * 0.22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
