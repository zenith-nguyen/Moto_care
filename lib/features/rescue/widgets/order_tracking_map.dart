import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' as osm_map;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_dependencies.dart';
import '../../home/theme/home_theme.dart';
import '../../location/services/location_api_config.dart';
import '../theme/order_tracking_theme.dart';

// A monochrome PNG pin keeps markers visible while detailed icons load.
final _fallbackMarkerIcon = BitmapDescriptor.bytes(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAADAAAAA8CAYAAAAgwDn8AAACSElEQVR42u1aC83DIBBGQiVU'
    'QiUgYRIqYRJwgAQkVAISkFAJSODvJdDcWEuBvw8g+5JLlq7Ave+AEvJDIzDG0IXYQnIhZb6h'
    '7H/wDi2F6WEhsZA26dB27PAU43KLK6WUmabJMMY+CJ7BfzuQtwiyLNItxP3VgblxHE3XdQZe'
    'CxG8A+/CmA3A3N2VWv9QoRDC9H1/yPQewViYYyNWhiuYX/1cSvkvxrcEgTm9+BguYR78+SzG'
    'fYK5TxXCZx589yrmHcEapwhhA1bdyfyOECorsHG2udJtIt2J57jOGrB3M+/IC+whRYB15JnZ'
    'Jic74WKXrH3I0U8x78irE0OMAKIE7e9YQcQIoF17kLsg5/yj74Hf8CxXIajt0DEtcXbahDFa'
    '7zem8F/uvAg0JMCau2Ias8AiQaQKAbwgsMPsAyZPdZuQ5rcskepOyCVlSACV4//g36mAMZlx'
    'oEICZFXewEZlF6lWxpX5dAFy8ROgRReqPoirT6PVF7K6W4nqm7lW2um6NzTVbymb2NRXf6zS'
    'xMFW9UeLTRzuNnG83sQFx9EV0+v1SmYextx6xRS65JvnOVkAGHP7Jd+GIFNOhvIyzfTkPXGf'
    'YwVP+/3Tl908xQqe9jl5GjawdawVkPb1LQEbKcQ7xgqe9t+lfewxH1kBaX8u8WuVNbFTSr+Y'
    'h2e4dJT6yY3c20OgVkGSUoFPNbAVPO1TUjLcoQC2AtK+IKXDFjftrIC0rx8vWglCMGcFpH1G'
    'agEubsUVrQQhcNUaSY2wxW0mtcKmVUp+aBh/gj6PkZycUaAAAAAASUVORK5CYII=',
  ),
  width: 24,
  height: 30,
  imagePixelRatio: 2,
);

// Rasterized from the same Material motorcycle glyph as the detailed icon.
final _fallbackBikeIcon = BitmapDescriptor.bytes(
  base64Decode(
    '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',
  ),
  width: 48,
  height: 48,
  imagePixelRatio: 1,
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
      return ref.watch(runtimeApiIntegrationProvider)
          ? OsmOrderTrackingMap(data: widget.data)
          : SimulatedTrackingMap(data: widget.data);
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

class OsmOrderTrackingMap extends StatefulWidget {
  const OsmOrderTrackingMap({super.key, required this.data});

  final OrderTrackingMapData data;

  @override
  State<OsmOrderTrackingMap> createState() => _OsmOrderTrackingMapState();
}

class _OsmOrderTrackingMapState extends State<OsmOrderTrackingMap> {
  final _controller = osm_map.MapController();

  List<osm.LatLng> get _points => widget.data.cameraPoints
      .map((point) => osm.LatLng(point.latitude, point.longitude))
      .toList(growable: false);

  void _fitRoute() {
    final points = _points;
    if (points.isEmpty) return;
    if (points.length == 1 ||
        points.every(
          (point) =>
              (point.latitude - points.first.latitude).abs() < .00001 &&
              (point.longitude - points.first.longitude).abs() < .00001,
        )) {
      _controller.move(points.first, 17);
      return;
    }
    _controller.fitCamera(
      osm_map.CameraFit.bounds(
        bounds: osm_map.LatLngBounds.fromPoints(points),
        padding: EdgeInsets.fromLTRB(
          48 + widget.data.padding.left,
          48 + widget.data.padding.top,
          48 + widget.data.padding.right,
          48 + widget.data.padding.bottom,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(OsmOrderTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.customer != widget.data.customer ||
        oldWidget.data.mechanic != widget.data.mechanic ||
        !listEquals(oldWidget.data.route, widget.data.route) ||
        oldWidget.data.padding != widget.data.padding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitRoute();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.data.route
        .map((point) => osm.LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    final customer = osm.LatLng(
      widget.data.customer.latitude,
      widget.data.customer.longitude,
    );
    final mechanic = widget.data.mechanic == null
        ? null
        : osm.LatLng(
            widget.data.mechanic!.latitude,
            widget.data.mechanic!.longitude,
          );
    return Stack(
      key: const ValueKey('order-tracking-osm-map'),
      fit: StackFit.expand,
      children: [
        osm_map.FlutterMap(
          mapController: _controller,
          options: osm_map.MapOptions(
            initialCenter: customer,
            initialZoom: 15,
            minZoom: 5,
            maxZoom: 19,
            onMapReady: _fitRoute,
          ),
          children: [
            osm_map.TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.motocare.app',
              maxNativeZoom: 19,
            ),
            if (route.length >= 2)
              osm_map.PolylineLayer(
                polylines: [
                  osm_map.Polyline(
                    points: route,
                    color: OrderTrackingColors.route,
                    strokeWidth: 5,
                  ),
                ],
              ),
            osm_map.MarkerLayer(
              markers: [
                osm_map.Marker(
                  point: customer,
                  width: 52,
                  height: 62,
                  alignment: Alignment.topCenter,
                  child: const _OsmTrackingMarker(sos: true),
                ),
                if (mechanic != null)
                  osm_map.Marker(
                    point: mechanic,
                    width: 48,
                    height: 48,
                    child: _OsmTrackingMarker(
                      sos: false,
                      simulated: widget.data.isSimulated,
                    ),
                  ),
              ],
            ),
            osm_map.RichAttributionWidget(
              showFlutterMapAttribution: false,
              attributions: [
                osm_map.TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ],
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

class _OsmTrackingMarker extends StatelessWidget {
  const _OsmTrackingMarker({required this.sos, this.simulated = false});

  final bool sos;
  final bool simulated;

  @override
  Widget build(BuildContext context) => Semantics(
    label: sos
        ? 'Vị trí sự cố của khách hàng'
        : simulated
        ? 'Vị trí thợ cứu hộ mô phỏng'
        : 'Vị trí thợ cứu hộ',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: ValueKey(
            sos ? 'tracking-customer-marker' : 'tracking-mechanic-marker',
          ),
          width: sos ? 46 : 44,
          height: sos ? 46 : 44,
          decoration: BoxDecoration(
            color: sos ? HomeColors.red : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: sos ? Colors.white : OrderTrackingColors.route,
              width: sos ? 3 : 2,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 6),
            ],
          ),
          alignment: Alignment.center,
          child: sos
              ? const Text(
                  'SOS',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                )
              : const Icon(
                  Icons.two_wheeler_rounded,
                  color: OrderTrackingColors.route,
                  size: 28,
                ),
        ),
        if (sos) Container(width: 3, height: 8, color: HomeColors.red),
      ],
    ),
  );
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
                style: const TextStyle(
                  fontSize: 11,
                  color: HomeColors.secondary,
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
          fontFamily: 'Montserrat',
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
