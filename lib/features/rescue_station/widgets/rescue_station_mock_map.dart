import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/service_scaffold.dart';
import '../models/rescue_station.dart';

class RescueStationMockMap extends StatelessWidget {
  const RescueStationMockMap({
    super.key,
    required this.stations,
    required this.selectedId,
    required this.onSelected,
  });
  final List<RescueStation> stations;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // Reserve margins for markers and project sample coordinates to this canvas.
    final minLat = stations.map((s) => s.latitude).reduce(math.min);
    final maxLat = stations.map((s) => s.latitude).reduce(math.max);
    final minLng = stations.map((s) => s.longitude).reduce(math.min);
    final maxLng = stations.map((s) => s.longitude).reduce(math.max);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 320,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _StationMapPainter()),
              ),
              for (final station in stations)
                Positioned(
                  left:
                      (maxLng == minLng
                              ? .5
                              : .15 +
                                    .7 *
                                        (station.longitude - minLng) /
                                        (maxLng - minLng)) *
                          constraints.maxWidth -
                      24,
                  top:
                      (maxLat == minLat
                              ? .5
                              : .15 +
                                    .6 *
                                        (maxLat - station.latitude) /
                                        (maxLat - minLat)) *
                          320 -
                      24,
                  child: Semantics(
                    selected: station.id == selectedId,
                    child: IconButton.filled(
                      tooltip: station.name,
                      style: IconButton.styleFrom(
                        backgroundColor: station.id == selectedId
                            ? ServiceColors.orange
                            : const Color(0xFF35664B),
                      ),
                      onPressed: () => onSelected(station.id),
                      icon: Icon(
                        station.stationType == StationType.mobileTeam
                            ? Icons.local_shipping
                            : Icons.location_on,
                      ),
                    ),
                  ),
                ),
              const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Bản đồ mô phỏng • Vị trí minh họa',
                    style: TextStyle(
                      color: ServiceColors.text,
                      fontSize: 12,
                      backgroundColor: ServiceColors.surface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationMapPainter extends CustomPainter {
  const _StationMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8F1E9),
    );
    final river = Path()
      ..moveTo(size.width * .82, 0)
      ..cubicTo(
        size.width * .4,
        size.height * .3,
        size.width,
        size.height * .6,
        size.width * .65,
        size.height,
      );
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFB9DFF3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30,
    );
    final road = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 12;
    for (var index = 1; index < 5; index++) {
      canvas.drawLine(
        Offset(0, size.height * index / 5),
        Offset(size.width, size.height * index / 5 + 30),
        road,
      );
      canvas.drawLine(
        Offset(size.width * index / 5, 0),
        Offset(size.width * index / 5 - 30, size.height),
        road,
      );
    }
  }

  @override
  bool shouldRepaint(_StationMapPainter oldDelegate) => false;
}
