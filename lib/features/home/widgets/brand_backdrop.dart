import 'package:flutter/material.dart';

import '../theme/home_theme.dart';

/// Soft curves shared by the home and account headers.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({
    super.key,
    required this.child,
    this.colors = const [
      HomeColors.surface,
      HomeColors.background,
      HomeColors.background,
    ],
  });
  final Widget child;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -120,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.24),
                  width: 48,
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: -200,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 56,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    ),
  );
}
