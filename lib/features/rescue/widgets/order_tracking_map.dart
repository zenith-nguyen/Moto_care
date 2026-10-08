import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../home/theme/home_theme.dart';
import '../../location/services/location_api_config.dart';

class OrderTrackingMapData {
  const OrderTrackingMapData({
    required this.customer,
    required this.mechanic,
    required this.route,
    required this.fullRoute,
  });
  final LatLng customer, mechanic;
  final List<LatLng> route, fullRoute;

  Set<Marker> markers({
    BitmapDescriptor? sosIcon,
    BitmapDescriptor? bikeIcon,
  }) => {
    Marker(
      markerId: const MarkerId('customer-sos'),
      position: customer,
      anchor: const Offset(.5, 1),
      icon:
          sosIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Vị trí sự cố của bạn'),
    ),
    Marker(
      markerId: const MarkerId('mechanic-bike'),
      position: mechanic,
      anchor: const Offset(.5, .5),
      icon:
          bikeIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      zIndexInt: 2,
      infoWindow: const InfoWindow(title: 'Thợ cứu hộ • mô phỏng'),
    ),
  };

  Set<Polyline> get polylines => {
    if (route.length >= 2)
      Polyline(
        polylineId: const PolylineId('mechanic-route'),
        points: route,
        color: HomeColors.red,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
  };
}

typedef OrderTrackingMapBuilder = Widget Function(
  BuildContext,
  OrderTrackingMapData,
);

final orderTrackingMapBuilderProvider = Provider<OrderTrackingMapBuilder>(
  (ref) =>
      (context, data) => OrderTrackingMap(data: data),
);

class OrderTrackingMap extends ConsumerStatefulWidget {
  const OrderTrackingMap({super.key, required this.data});
  final OrderTrackingMapData data;
  @override
  ConsumerState<OrderTrackingMap> createState() => _OrderTrackingMapState();
}

class _OrderTrackingMapState extends ConsumerState<OrderTrackingMap> {
  BitmapDescriptor? _sos, _bike;
  GoogleMapController? _controller;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    if (ref.read(locationApiConfigProvider).mapConfigured) {
      unawaited(_loadIcons());
    }
  }

  Future<void> _loadIcons() async {
    try {
      final sos = await _markerIcon(sos: true);
      final bike = await _markerIcon(sos: false);
      if (mounted) {
        setState(() {
          _sos = sos;
          _bike = bike;
        });
      }
    } on Exception {
      // Native red markers remain usable if bitmap generation is unavailable.
    }
  }

  Future<void> _fitRoute() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final points = widget.data.fullRoute;
    final latitudes = points.map((point) => point.latitude);
    final longitudes = points.map((point) => point.longitude);
    final south = latitudes.reduce(math.min),
        north = latitudes.reduce(math.max);
    final west = longitudes.reduce(math.min),
        east = longitudes.reduce(math.max);
    try {
      await controller.animateCamera(
        (north - south).abs() < .00001 && (east - west).abs() < .00001
            ? CameraUpdate.newLatLngZoom(widget.data.customer, 17)
            : CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(south, west),
                  northeast: LatLng(north, east),
                ),
                56,
              ),
      );
      if (mounted && _cameraError != null) setState(() => _cameraError = null);
    } on Exception {
      if (mounted) {
        setState(
          () => _cameraError =
              'Chưa căn được bản đồ. Bấm nút lộ trình để thử lại.',
        );
      }
    }
  }

  @override
  void didUpdateWidget(OrderTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.customer != widget.data.customer) unawaited(_fitRoute());
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(locationApiConfigProvider).mapConfigured) {
      return SimulatedTrackingMap(data: widget.data);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        GoogleMap(
          key: const ValueKey('order-tracking-native-map'),
          initialCameraPosition: CameraPosition(
            target: widget.data.customer,
            zoom: 14,
          ),
          markers: widget.data.markers(sosIcon: _sos, bikeIcon: _bike),
          polylines: widget.data.polylines,
          onMapCreated: (controller) {
            if (!mounted) return;
            _controller = controller;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) unawaited(_fitRoute());
            });
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          tiltGesturesEnabled: false,
        ),
        if (_cameraError != null)
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_cameraError!),
              ),
            ),
          ),
        Positioned(
          bottom: 34,
          right: 14,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              tooltip: 'Xem toàn bộ lộ trình',
              onPressed: _fitRoute,
              icon: const Icon(Icons.route_rounded, color: HomeColors.red),
            ),
          ),
        ),
      ],
    );
  }
}

/// Explicitly a diagram, used when native map tiles are not configured.
class SimulatedTrackingMap extends StatelessWidget {
  const SimulatedTrackingMap({super.key, required this.data});
  final OrderTrackingMapData data;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      Offset project(LatLng point) =>
          _project(point, data.fullRoute, constraints.biggest);
      final customer = project(data.customer),
          mechanic = project(data.mechanic);
      return ColoredBox(
        color: const Color(0xFFF8F9FA),
        child: Stack(
          key: const ValueKey('order-tracking-schematic'),
          children: [
            Positioned.fill(child: CustomPaint(painter: _RoutePainter(data))),
            Positioned(
              left: customer.dx - 23,
              top: customer.dy - 54,
              child: Semantics(
                label: 'Khách hàng tại vị trí sự cố',
                child: Column(
                  children: [
                    Container(
                      key: const ValueKey('tracking-customer-marker'),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: HomeColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'SOS',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(width: 3, height: 8, color: HomeColors.red),
                  ],
                ),
              ),
            ),
            Positioned(
              left: mechanic.dx - 22,
              top: mechanic.dy - 22,
              child: Semantics(
                label: 'Vị trí thợ cứu hộ mô phỏng',
                child: Container(
                  key: const ValueKey('tracking-mechanic-marker'),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: HomeColors.red, width: 2),
                  ),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    color: HomeColors.red,
                    size: 28,
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                'Sơ đồ mô phỏng • Bản đồ chưa sẵn sàng',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: HomeColors.secondary),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Offset _project(LatLng point, List<LatLng> route, Size size) {
  final south = route.map((p) => p.latitude).reduce(math.min);
  final north = route.map((p) => p.latitude).reduce(math.max);
  final west = route.map((p) => p.longitude).reduce(math.min);
  final east = route.map((p) => p.longitude).reduce(math.max);
  final x = east == west ? .5 : (point.longitude - west) / (east - west);
  final y = north == south ? .5 : (north - point.latitude) / (north - south);
  return Offset(
    48 + x * math.max(0, size.width - 96),
    72 + y * math.max(0, size.height - 120),
  );
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.data);
  final OrderTrackingMapData data;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE9ECEF)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path();
    for (var index = 0; index < data.route.length; index++) {
      final point = _project(data.route[index], data.fullRoute, size);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = HomeColors.red
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) => oldDelegate.data != data;
}

Future<BitmapDescriptor> _markerIcon({required bool sos}) async {
  const width = 48.0;
  final height = sos ? 60.0 : 48.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(3);
  canvas.drawCircle(const Offset(24, 24), 22, Paint()..color = Colors.white);
  canvas.drawCircle(
    const Offset(24, 24),
    19,
    Paint()..color = sos ? HomeColors.red : Colors.white,
  );
  if (sos) {
    canvas.drawLine(
      const Offset(24, 44),
      const Offset(24, 58),
      Paint()
        ..color = HomeColors.red
        ..strokeWidth = 3,
    );
    final label = TextPainter(
      text: const TextSpan(
        text: 'SOS',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(24 - label.width / 2, 24 - label.height / 2));
  } else {
    canvas.drawCircle(
      const Offset(24, 24),
      20,
      Paint()
        ..color = HomeColors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final icon = Icons.two_wheeler_rounded;
    final glyph = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 28,
          color: HomeColors.red,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(canvas, Offset(24 - glyph.width / 2, 24 - glyph.height / 2));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (width * 3).toInt(),
    (height * 3).toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    width: width,
    height: height,
    imagePixelRatio: 3,
  );
}
