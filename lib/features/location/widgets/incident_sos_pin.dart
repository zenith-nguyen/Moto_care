import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';

class IncidentSosPin extends StatelessWidget {
  const IncidentSosPin({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Ghim SOS cố định. Vị trí xe gặp sự cố.',
    child: SizedBox(
      key: const ValueKey('incident-sos-pin'),
      width: 72,
      height: 104,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HomeColors.primary,
              border: Border.all(color: HomeColors.surface, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                Text(
                  'SOS',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 3, height: 18, color: HomeColors.primary),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HomeColors.primary,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    ),
  );
}
