import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../location/services/location_api_config.dart';
import '../theme/order_tracking_theme.dart';

// Matching teal pins keep markers visible while detailed icons load.
final _fallbackMarkerIcon = BitmapDescriptor.bytes(
  base64Decode(
    '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'
    'Ay7HbkvCwW6MAAAAAElFTkSuQmCC',
  ),
  width: 48,
  height: 60,
  imagePixelRatio: 3,
);

// Rasterized from the same Material motorcycle glyph as the detailed icon.
final _fallbackBikeIcon = BitmapDescriptor.bytes(
  base64Decode(
    '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'
    '/j9rWBZTM8WQ8gAAAABJRU5ErkJggg==',
  ),
  width: 48,
  height: 48,
  imagePixelRatio: 3,
);

class OrderTrackingMapData {
  const OrderTrackingMapData({
    required this.customer,
    required this.mechanic,
    required this.route,
    required this.fullRoute,
    this.padding = EdgeInsets.zero,
    this.isSimulated = true,
  });
  final LatLng customer;
  final LatLng? mechanic;
  final List<LatLng> route, fullRoute;
  final EdgeInsets padding;
  final bool isSimulated;

  // Include both people even when the service omits endpoints or has no route yet.
  List<LatLng> get cameraPoints => [
    customer,
    ?mechanic,
    ...fullRoute,
    ...route,
  ];
  LatLngBounds get cameraBounds {
    final points = cameraPoints;
    return LatLngBounds(
      southwest: LatLng(
        points.map((p) => p.latitude).reduce(math.min),
        points.map((p) => p.longitude).reduce(math.min),
      ),
      northeast: LatLng(
        points.map((p) => p.latitude).reduce(math.max),
        points.map((p) => p.longitude).reduce(math.max),
      ),
    );
  }

  Set<Marker> markers({
    BitmapDescriptor? sosIcon,
    BitmapDescriptor? bikeIcon,
  }) => {
    Marker(
      markerId: const MarkerId('customer-sos'),
      position: customer,
      anchor: const Offset(.5, 1),
      icon: sosIcon ?? _fallbackMarkerIcon,
      infoWindow: const InfoWindow(title: 'Vị trí sự cố của bạn'),
    ),
    if (mechanic != null)
      Marker(
        markerId: const MarkerId('mechanic-bike'),
        position: mechanic!,
        anchor: const Offset(.5, .5),
        icon: bikeIcon ?? _fallbackBikeIcon,
        zIndexInt: 2,
        infoWindow: InfoWindow(
          title: isSimulated ? 'Thợ cứu hộ • mô phỏng' : 'Thợ cứu hộ',
        ),
      ),
  };

  Set<Polyline> get polylines => {
    if (route.length >= 2)
      Polyline(
        polylineId: const PolylineId('mechanic-route'),
        points: route,
        color: OrderTrackingColors.route,
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
  Timer? _fitDebounce;

  @override
  void initState() {
    super.initState();
    if (ref.read(locationApiConfigProvider).mapConfigured) {
      unawaited(_loadIcons());
    }
  }

  Future<void> _loadIcons() async {
    try {
      final sos = await createTrackingMarkerIcon(sos: true);
      final bike = await createTrackingMarkerIcon(sos: false);
      if (mounted) {
        setState(() {
          _sos = sos;
          _bike = bike;
        });
      }
    } on Exception {
      // Fallback pins remain visible if bitmap generation fails.
    }
  }

  Future<void> _fitRoute() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final bounds = widget.data.cameraBounds;
    try {
      await controller.animateCamera(
        (bounds.northeast.latitude - bounds.southwest.latitude).abs() <
                    .00001 &&
                (bounds.northeast.longitude - bounds.southwest.longitude)
                        .abs() <
                    .00001
            ? CameraUpdate.newLatLngZoom(widget.data.customer, 17)
            : CameraUpdate.newLatLngBounds(bounds, 56),
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
    final data = widget.data;
    if (_controller != null &&
        (oldWidget.data.customer != data.customer ||
            oldWidget.data.padding != data.padding ||
            !listEquals(oldWidget.data.fullRoute, data.fullRoute) ||
            (!data.isSimulated && oldWidget.data.mechanic != data.mechanic))) {
      _fitDebounce?.cancel();
      _fitDebounce = Timer(const Duration(milliseconds: 200), () {
        if (mounted) unawaited(_fitRoute());
      });
    }
  }

  @override
  void dispose() {
    _fitDebounce?.cancel();
    super.dispose();
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
          padding: widget.data.padding,
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
            bottom: widget.data.padding.bottom + 68,
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
          bottom: widget.data.padding.bottom + 8,
          right: 14,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              tooltip: 'Xem toàn bộ lộ trình',
              onPressed: _fitRoute,
              icon: const Icon(
                Icons.route_rounded,
                color: OrderTrackingColors.route,
              ),
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
          _project(point, data.cameraPoints, constraints.biggest, data.padding);
      final customer = project(data.customer),
          mechanic = data.mechanic == null ? null : project(data.mechanic!);
      final compact = constraints.maxHeight - data.padding.vertical < 180;
      return ColoredBox(
        color: CustomerOrderTheme.background,
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
                        color: OrderTrackingColors.route,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: OrderTrackingColors.routeHalo,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'SOS',
                        textScaler: TextScaler.noScaling,
                        style: CustomerOrderTheme.text(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 8,
                      color: OrderTrackingColors.route,
                    ),
                  ],
                ),
              ),
            ),
            if (mechanic != null)
              Positioned(
                left: mechanic.dx - 22,
                top: mechanic.dy - 22,
                child: Semantics(
                  label: data.isSimulated
                      ? 'Vị trí thợ cứu hộ mô phỏng'
                      : 'Vị trí thợ cứu hộ',
                  child: Container(
                    key: const ValueKey('tracking-mechanic-marker'),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: OrderTrackingColors.route,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: OrderTrackingColors.routeHalo,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      color: OrderTrackingColors.route,
                      size: 28,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: compact ? data.padding.top + 8 : null,
              bottom: compact ? null : data.padding.bottom + 4,
              left: 12,
              right: compact ? 96 : 12,
              child: Text(
                compact
                    ? 'Bản đồ chưa sẵn sàng'
                    : 'Sơ đồ vị trí • Bản đồ chưa sẵn sàng',
                textAlign: compact ? TextAlign.left : TextAlign.center,
                style: CustomerOrderTheme.text(
                  fontSize: 11,
                  color: CustomerOrderTheme.muted,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Offset _project(
  LatLng point,
  List<LatLng> route,
  Size size,
  EdgeInsets padding,
) {
  final south = route.map((p) => p.latitude).reduce(math.min);
  final north = route.map((p) => p.latitude).reduce(math.max);
  final west = route.map((p) => p.longitude).reduce(math.min);
  final east = route.map((p) => p.longitude).reduce(math.max);
  final x = east == west ? .5 : (point.longitude - west) / (east - west);
  final y = north == south ? .5 : (north - point.latitude) / (north - south);
  final available = math.max(0.0, size.height - padding.vertical);
  final top = math.min(56.0, available * .62);
  final bottom = math.min(36.0, available * .38);
  return Offset(
    padding.left + 48 + x * math.max(0, size.width - padding.horizontal - 96),
    padding.top + top + y * math.max(0, available - top - bottom),
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
      final point = _project(
        data.route[index],
        data.cameraPoints,
        size,
        data.padding,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = OrderTrackingColors.route
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) => oldDelegate.data != data;
}

Future<BitmapDescriptor> createTrackingMarkerIcon({required bool sos}) async {
  const width = 48.0;
  final height = sos ? 60.0 : 48.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(3);
  canvas.drawCircle(
    const Offset(24, 24),
    24,
    Paint()..color = OrderTrackingColors.routeHalo,
  );
  canvas.drawCircle(const Offset(24, 24), 20, Paint()..color = Colors.white);
  canvas.drawCircle(
    const Offset(24, 24),
    17,
    Paint()..color = sos ? OrderTrackingColors.route : Colors.white,
  );
  if (sos) {
    canvas.drawLine(
      const Offset(24, 44),
      const Offset(24, 58),
      Paint()
        ..color = OrderTrackingColors.route
        ..strokeWidth = 3,
    );
    final label = TextPainter(
      text: TextSpan(
        text: 'SOS',
        style: CustomerOrderTheme.text(
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
      18,
      Paint()
        ..color = OrderTrackingColors.route
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
          color: OrderTrackingColors.route,
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
