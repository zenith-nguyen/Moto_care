import 'package:flutter/material.dart';

import '../models/home_destination.dart';
import '../theme/home_theme.dart';

class TrangChuMenu extends StatelessWidget {
  const TrangChuMenu({
    super.key,
    required this.onClose,
    required this.onSelected,
    this.light = true,
  });

  final VoidCallback onClose;
  final ValueChanged<HomeDestination> onSelected;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: (MediaQuery.sizeOf(context).width * 0.82).clamp(260.0, 420.0),
      backgroundColor: light ? HomeColors.background : const Color(0xFF191919),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 28),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Đóng menu',
                  onPressed: onClose,
                  icon: SizedBox(
                    width: 28,
                    height: 28,
                    child: CustomPaint(
                      painter: _CloseIconPainter(light: light),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  for (final destination in [
                    ...HomeDestination.menuItems,
                    if (light) HomeDestination.myVehicles,
                    if (light) HomeDestination.messages,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: light
                            ? HomeColors.surface
                            : const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(13),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onSelected(destination),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  destination.icon,
                                  color: light
                                      ? HomeColors.primary
                                      : const Color(0xFFFF251E),
                                  size: 25,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    destination.label,
                                    style: TextStyle(
                                      color: light
                                          ? HomeColors.text
                                          : Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF333333)),
                  const SizedBox(height: 16),
                  Text(
                    'MOTO CARE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: light ? HomeColors.text : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đồng hành trên mọi hành trình',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF999999), fontSize: 13),
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

class _CloseIconPainter extends CustomPainter {
  const _CloseIconPainter({required this.light});
  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      const Offset(2, 2),
      Offset(size.width - 2, size.height - 2),
      paint..color = light ? HomeColors.text : Colors.white,
    );
    canvas.drawLine(
      Offset(2, size.height - 2),
      Offset(size.width - 2, 2),
      paint..color = light ? HomeColors.primary : const Color(0xFFFF251E),
    );
  }

  @override
  bool shouldRepaint(_CloseIconPainter oldDelegate) =>
      oldDelegate.light != light;
}
