import 'package:flutter/material.dart';

import '../../profile/models/profile_state.dart';
import '../theme/revo_home_theme.dart';
import 'home_account_avatar.dart';

class RevoHomeHeader extends StatelessWidget {
  const RevoHomeHeader({
    super.key,
    required this.location,
    required this.profile,
    required this.onLocation,
    required this.onNotifications,
    required this.onAccount,
    this.hasNotifications = false,
  });

  final String location;
  final ProfileState profile;
  final VoidCallback onLocation;
  final VoidCallback onNotifications;
  final VoidCallback onAccount;
  final bool hasNotifications;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      HomeAccountAvatar(profile: profile, onTap: onAccount, placeholder: true),
      const SizedBox(width: 12),
      Expanded(
        child: Tooltip(
          message: 'Chọn vị trí',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              key: const ValueKey('home-location'),
              onTap: onLocation,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Vị trí của tôi',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CustomPaint(
                          size: Size(24, 24),
                          painter: _LocationHomeIconPainter(),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Ink(
                            decoration: BoxDecoration(
                              color: RevoHomeColors.ink,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 7,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      IconButton(
        tooltip: 'Thông báo',
        onPressed: onNotifications,
        style: IconButton.styleFrom(
          backgroundColor: RevoHomeColors.surface,
          minimumSize: const Size(44, 44),
        ),
        icon: Badge(
          isLabelVisible: hasNotifications,
          backgroundColor: RevoHomeColors.verified,
          smallSize: 6,
          child: const Icon(Icons.notifications_none_rounded, size: 23),
        ),
      ),
    ],
  );
}

class _LocationHomeIconPainter extends CustomPainter {
  const _LocationHomeIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final outline = Paint()
      ..color = RevoHomeColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pin = Path()
      ..moveTo(9.5, 21)
      ..cubicTo(8.4, 19.9, 2.9, 15.7, 2.9, 8.8)
      ..cubicTo(2.9, 4.5, 5.8, 1.6, 9.5, 1.6)
      ..cubicTo(13.5, 1.6, 16.5, 4.5, 16.5, 8.8)
      ..cubicTo(16.5, 15.4, 10.5, 20, 9.5, 21)
      ..close();
    canvas.drawPath(pin, outline);
    canvas.drawCircle(const Offset(9.5, 8.5), 2.6, outline);

    // Clear the overlap so the small home reads as a separate outline.
    canvas.drawCircle(
      const Offset(17, 18),
      6.5,
      Paint()..color = RevoHomeColors.background,
    );
    final home = Path()
      ..moveTo(12.7, 17.3)
      ..lineTo(17, 13.45)
      ..lineTo(21.3, 17.3)
      ..moveTo(13.8, 16.35)
      ..lineTo(13.8, 22)
      ..lineTo(16, 22)
      ..lineTo(16, 18.7)
      ..lineTo(18.05, 18.7)
      ..lineTo(18.05, 22)
      ..lineTo(20.2, 22)
      ..lineTo(20.2, 16.35);
    canvas.drawPath(home, outline);
  }

  @override
  bool shouldRepaint(_LocationHomeIconPainter oldDelegate) => false;
}
