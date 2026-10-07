import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card nền trắng, viền nhạt, shadow nhẹ, có thể bấm.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.radius = AppRadius.md,
    this.borderColor = AppColors.border,
    this.shadow = true,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final Color borderColor;
  final bool shadow;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: br,
        border: Border.all(color: borderColor),
        boxShadow: shadow ? AppShadows.soft : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: br,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Avatar tròn với chữ cái đầu.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.initial,
    this.size = 52,
    this.background = AppColors.primary,
    this.foreground = Colors.white,
    this.borderColor,
  });

  final String initial;
  final double size;
  final Color background;
  final Color foreground;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: borderColor == null ? null : Border.all(color: borderColor!, width: 2),
      ),
      child: Text(
        initial,
        style: appText(size * 0.42, weight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

/// Badge "Thợ đã xác thực" (nền xanh nhạt, icon check).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.label = 'Thợ đã xác thực'});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.successDark),
          const SizedBox(width: 4),
          Text(label,
              style: appText(11.5, weight: FontWeight.w600, color: AppColors.successDark)),
        ],
      ),
    );
  }
}

/// Badge "ĐƠN KHẨN CẤP" (nền đỏ nhạt, chữ đỏ).
class UrgentBadge extends StatelessWidget {
  const UrgentBadge({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_outlined, size: compact ? 12 : 14, color: AppColors.primaryDark),
          const SizedBox(width: 3),
          Text(
            'ĐƠN KHẨN CẤP',
            style: appText(compact ? 10 : 11.5,
                weight: FontWeight.w800, color: AppColors.primaryDark, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

/// Nút icon tròn (mặc định nền đen, icon trắng).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.size = 44,
    this.background = AppColors.ink,
    this.foreground = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.46, color: foreground),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text, style: appText(16, weight: FontWeight.w700))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Snackbar chung cho các thao tác demo.
void showAppSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Ảnh hiện trường (placeholder vẽ bằng CustomPainter: bánh xe găm đinh).
/// Khi có ảnh thật, thay bằng Image.asset(...) / Image.network(...).
class ScenePhoto extends StatelessWidget {
  const ScenePhoto({super.key, this.borderRadius = 0});
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        painter: _ScenePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF2E3238));
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.64, w, h * 0.36),
      Paint()..color = const Color(0xFF3D434B),
    );

    final dash = Paint()
      ..color = Colors.white.op(0.35)
      ..strokeWidth = math.max(1.5, h * 0.018);
    for (double x = -w * 0.04; x < w; x += w * 0.16) {
      canvas.drawLine(Offset(x, h * 0.88), Offset(x + w * 0.08, h * 0.88), dash);
    }

    final c = Offset(w * 0.5, h * 0.56);
    final r = h * 0.32;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF15171A)); // lốp
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..color = const Color(0xFFBFC5CC);
    canvas.drawCircle(c, r * 0.62, rim); // vành

    final spoke = Paint()
      ..color = const Color(0xFF8A9099)
      ..strokeWidth = r * 0.05;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawLine(
        c,
        c + Offset(math.cos(a), math.sin(a)) * (r * 0.6),
        spoke,
      );
    }
    canvas.drawCircle(c, r * 0.13, Paint()..color = const Color(0xFFBFC5CC));

    // Đinh găm vào lốp
    final nail = Paint()
      ..color = AppColors.primary
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    final nailStart = c + Offset(math.cos(-0.7), math.sin(-0.7)) * (r * 0.98);
    final nailEnd = c + Offset(math.cos(-0.7), math.sin(-0.7)) * (r * 0.72);
    canvas.drawLine(nailStart, nailEnd, nail);
    canvas.drawCircle(nailStart, r * 0.07, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
