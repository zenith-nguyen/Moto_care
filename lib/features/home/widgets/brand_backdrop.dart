import 'package:flutter/material.dart';

import '../theme/home_theme.dart';

/// Soft orange curves shared by the home and account headers.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD6C2), Color(0xFFFFEEE6), HomeColors.background],
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
