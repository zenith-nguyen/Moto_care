import 'package:flutter/material.dart';

import '../theme/home_theme.dart';

const _red = HomeColors.red;
const _ink = Color(0xFF111111);
const _cardShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
);

class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.displayName,
    required this.memberId,
    required this.membershipLabel,
    required this.onProfile,
    required this.onMembership,
  });

  final String displayName;
  final String? memberId;
  final String membershipLabel;
  final VoidCallback onProfile;
  final VoidCallback onMembership;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFD4D4D4), Color(0xFFFAFAFA)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            const Positioned(
              right: -28,
              bottom: -36,
              child: ExcludeSemantics(
                child: Icon(
                  Icons.two_wheeler_rounded,
                  size: 210,
                  color: Color(0x0C000000),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/Logo_motocare.png',
                        width: 60,
                        height: 46,
                        fit: BoxFit.contain,
                        semanticLabel: 'Logo Moto Care',
                      ),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium_outlined,
                              color: Color(0xFF999999),
                              size: 29,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              membershipLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Thông tin cá nhân',
                        onPressed: onProfile,
                        padding: EdgeInsets.zero,
                        icon: SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFE5E5E5),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 36,
                                    color: Color(0xFFBDBDBD),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 12,
                                    color: _red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(
                                  'ID : ${memberId?.trim().isNotEmpty == true ? memberId!.trim() : '—'}',
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: onMembership,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF737373),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(child: Text('Nhận hạng ngay')),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

class VoucherCard extends StatelessWidget {
  const VoucherCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final action = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _red,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text('Khám phá'),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: HomeColors.primary,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 290 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Kho ưu đãi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (!compact) ...[const SizedBox(width: 8), action],
                  ],
                ),
                if (compact) ...[
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class NearbyServicesCard extends StatelessWidget {
  const NearbyServicesCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F2F2),
      shape: _cardShape,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sạc pin, sửa xe nhanh chóng tại các điểm gần bạn.',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: _red),
                      minimumSize: const Size(0, 42),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me_outlined, size: 19),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Tìm điểm gần nhất',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF99EEFF), Color(0xFF21B8F2)],
                ).createShader(bounds),
                child: const Icon(Icons.bolt_rounded, size: 72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.onVouchers,
    required this.onMessages,
  });

  final VoidCallback onVouchers;
  final VoidCallback onMessages;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 1.15,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFCFCFCF)),
                for (final (left, top, angle, icon) in const [
                  (-0.22, 0.05, -0.4, Icons.two_wheeler_rounded),
                  (0.48, -0.32, -0.18, Icons.electric_moped_rounded),
                  (0.57, 0.28, 0.2, Icons.motorcycle_rounded),
                ])
                  Positioned(
                    left: constraints.maxWidth * left,
                    top: constraints.maxHeight * top,
                    child: Transform.rotate(
                      angle: angle,
                      child: Container(
                        width: constraints.maxWidth * 0.75,
                        height: constraints.maxHeight * 0.9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1E1E1),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          size: constraints.maxWidth * 0.42,
                          color: const Color(0xFFBDBDBD),
                        ),
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.all(9),
                  child: CustomPaint(painter: _DashedBorderPainter()),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00FFFFFF), Color(0xA6FFFFFF)],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      _JourneyShortcut(
                        tooltip: 'Kho ưu đãi',
                        icon: Icons.local_offer_rounded,
                        color: _red,
                        onPressed: onVouchers,
                      ),
                      const SizedBox(height: 12),
                      _JourneyShortcut(
                        tooltip: 'Tin nhắn',
                        icon: Icons.forum_rounded,
                        color: Colors.white,
                        onPressed: onMessages,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JourneyShortcut extends StatelessWidget {
  const _JourneyShortcut({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF535353),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: const EdgeInsets.all(14),
        icon: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(13),
        ),
      );
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 8) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
