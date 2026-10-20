import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'reference_image.dart';

/// CTA REVO dùng màu thương hiệu và cùng typography toàn ứng dụng.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = AppSpace.button,
    this.color = AppColors.primary,
    this.iconTrailing = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final Color color;
  final bool iconTrailing;

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
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSub,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        child: _ButtonLabel(
          label: label,
          icon: icon,
          color: onPressed == null ? AppColors.textSub : Colors.white,
          iconTrailing: iconTrailing,
        ),
      ),
    );
  }
}

/// Nút viền bo góc cho hành động phụ.
class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = AppSpace.button,
    this.color = AppColors.primary,
    this.borderColor = AppColors.primary,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
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
    this.color = AppColors.primary,
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
      child: Text(
        label,
        style: appText(15, weight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({
    required this.label,
    this.icon,
    required this.color,
    this.iconTrailing = false,
  });
  final String label;
  final IconData? icon;
  final Color color;
  final bool iconTrailing;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTypography.button.copyWith(color: color),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!iconTrailing) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
        ],
        Flexible(child: text),
        if (iconTrailing) ...[
          const SizedBox(width: 10),
          Icon(icon, size: 16, color: color),
        ],
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
    this.fontSize = 10,
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
          foreground: AppColors.successDark,
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
          foreground: AppColors.textSub,
          background: AppColors.light,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
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
              style: appText(
                fontSize,
                weight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar tròn chữ cái đầu: đen (thợ) hoặc xám nhạt (khách).
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.initials,
    this.size = 44,
    this.dark = true,
    this.imageAsset,
  });

  final String initials;
  final double size;
  final bool dark;

  /// Profile photo asset. If the file is missing the previous avatar is shown
  /// instead (never a broken-image icon).
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    if (dark || initials == 'TA') {
      final fallback = ReferenceImage(
        asset: dark
            ? 'assets/images/reference_profile.png'
            : 'assets/images/reference_customer.png',
        crop: dark
            ? const Rect.fromLTWH(34, 132, 94, 94)
            : const Rect.fromLTWH(80, 99, 54, 54),
      );
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: imageAsset == null
              ? fallback
              : Image.asset(imageAsset!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => fallback),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? AppColors.ink : AppColors.light,
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
    this.size = 44,
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
              child: Icon(
                icon,
                size: size * 0.44,
                color: filled ? Colors.white : AppColors.ink,
              ),
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
    this.centerTitle = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.fromLTRB(showBack ? 4 : 16, 0, 8, 0),
      color: AppColors.bg,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Quay lại',
              iconSize: 22,
              icon: const Icon(Icons.chevron_left),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
          if (showBack) const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: showBack && centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: showBack && centerTitle
                      ? TextAlign.center
                      : TextAlign.start,
                  style: AppTypography.title,
                ),
                if (subtitle != null)
                  Text(subtitle!, style: appText(13, color: AppColors.textSub)),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (showBack && centerTitle)
            const SizedBox(width: 48),
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
    this.padding = const EdgeInsets.all(14),
    this.color = AppColors.surface,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppColors.border, width: .7),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Card nền trắng bo góc có bóng nhẹ.
class ShadowCard extends StatelessWidget {
  const ShadowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
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
        border: Border.all(color: AppColors.border, width: .7),
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
    this.color = AppColors.primary,
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
  const FieldLabel(
    this.text, {
    super.key,
    this.required = false,
    this.color = AppColors.textSub,
  });
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
          style: appText(12, weight: FontWeight.w500, color: color),
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: appText(14.5, color: AppColors.danger),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dòng "nhãn ........ giá trị".
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(
    this.label,
    this.value, {
    super.key,
    this.valueStyle,
    this.labelStyle,
  });
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
            child: Text(
              label,
              style: labelStyle ?? appText(12, color: AppColors.textSub),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ?? appText(13, weight: FontWeight.w600),
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
            Expanded(
              child: Text(text, style: appText(17, weight: FontWeight.w600)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: appText(13, color: AppColors.textSub, height: 1.4),
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Fills taller phones while remaining scrollable on compact screens or large text.
class ViewportColumn extends StatelessWidget {
  const ViewportColumn({
    super.key,
    required this.children,
    required this.padding,
  });
  final List<Widget> children;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, bounds) => SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (bounds.maxHeight - padding.vertical).clamp(
                0,
                double.infinity,
              ),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      );
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
          color: AppColors.border,
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
            border: Border.all(
              color: value ? AppColors.ink : AppColors.textMuted,
              width: 2,
            ),
          ),
          child: value
              ? const Icon(Icons.check, size: 18, color: AppColors.ink)
              : null,
        ),
      ),
    );
  }
}

/// Đường kẻ nét đứt ngang (ngăn các phần trong card giao dịch).
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key, this.color = AppColors.border});
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

/// Ảnh phương tiện mẫu đính kèm trong cuộc trò chuyện demo.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({
    super.key,
    this.width,
    this.height = 120,
    this.radius = AppRadius.md,
    this.vehicle,
  });
  final String? vehicle;
  final double? width;
  final double height;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: width,
          height: height,
          color: AppColors.surfaceSoft,
          child: Stack(
            children: [
              Positioned.fill(
                child: vehicle == null
                    ? const Icon(Icons.photo_outlined,
                        size: 44, color: AppColors.primary)
                    : Icon(
                        vehicle!.contains('Toyota')
                            ? Icons.directions_car_rounded
                            : vehicle!.contains('Vision')
                                ? Icons.electric_moped_rounded
                                : Icons.two_wheeler_rounded,
                        size: 64,
                        color: AppColors.primary),
              ),
              Positioned(
                left: 8,
                bottom: 6,
                child: Text(
                  vehicle == null ? 'Ảnh mẫu' : 'Minh hoạ phương tiện',
                  style: appText(10, color: AppColors.textSub),
                ),
              ),
            ],
          ),
        ),
      );
}
