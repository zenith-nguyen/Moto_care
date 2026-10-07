import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/activity/services/activity_actions.dart';
import 'package:moto_care/features/activity/widgets/order_summary.dart';
import 'package:moto_care/features/home/theme/home_theme.dart';
import 'package:moto_care/features/rescue/models/order_tracking_journey.dart';
import 'package:moto_care/features/rescue/screens/order_tracking_screen.dart';
import 'package:moto_care/features/rescue/widgets/order_tracking_map.dart';

RescueOrder _order({
  String id = 'tracking-001',
  RescueOrderStatus status = RescueOrderStatus.pending,
  bool coordinates = true,
  String? phone,
}) => RescueOrder(
  id: id,
  orderCode: 'MC-TRACK-001',
  status: status,
  serviceType: RescueServiceType.flatTire,
  userVehicle: 'Honda Vision • 59-X1 123.45',
  locationAddress: '273 An Dương Vương, Quận 5',
  locationLatitude: coordinates ? 10.757 : null,
  locationLongitude: coordinates ? 106.668 : null,
  partnerName: 'Tiệm sửa xe Siêu Tốc',
  providerName: phone == null ? null : 'Nguyễn Văn A',
  providerPhone: phone,
  basePrice: 60000,
  travelFee: 10000,
  extraPartPrice: 0,
  discount: 10000,
  createdAt: DateTime(2026, 10, 7),
  items: [
    RescueOrderItem(
      packageId: 'tire-tubeless',
      name: 'Vá lốp không ruột',
      unitPrice: 50000,
      quantity: 1,
      serviceType: RescueServiceType.flatTire,
    ),
  ],
);

class _MapRecorder {
  OrderTrackingMapData? data;
  Widget build(BuildContext context, OrderTrackingMapData data) {
    this.data = data;
    return SimulatedTrackingMap(data: data);
  }
}

Future<GoRouter> _open(
  WidgetTester tester, {
  required _MapRecorder map,
  RescueOrder? order,
  bool motion = false,
  Future<bool> Function(Uri)? launcher,
  String path = '/order-tracking?id=tracking-001',
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialRescueOrdersProvider.overrideWithValue([order ?? _order()]),
        orderTrackingMapBuilderProvider.overrideWithValue(map.build),
        activityUrlLauncherProvider.overrideWithValue(
          launcher ?? (_) async => true,
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: !motion),
          child: child!,
        ),
      ),
    ),
  );
  router.go(path);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return router;
}

ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
Finder _key(String name) => find.byKey(ValueKey(name));

Future<void> _tap(
  WidgetTester tester,
  Finder finder, {
  bool settle = true,
}) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      80,
      scrollable: find.byType(Scrollable).hitTestable().last,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('An active order can reopen tracking from its invoice', (
    tester,
  ) async {
    final router = await _open(
      tester,
      map: _MapRecorder(),
      path: '/chi-tiet-don-hang?id=tracking-001',
    );
    await _tap(tester, find.byTooltip('Theo dõi lộ trình thợ'));
    expect(router.state.uri.path, '/order-tracking');
    expect(find.byType(OrderTrackingScreen), findsOneWidget);
    expect(
      _state(tester).read(activityProvider).orders.single.id,
      'tracking-001',
    );
  });
  test(
    'The route ends at the exact incident coordinate and decreases to zero',
    () {
      final journey = OrderTrackingJourney.fromOrder(_order(), null)!;
      expect(journey.customer, const LatLng(10.757, 106.668));
      var previous = journey.distanceKm;
      for (var step = 0; step <= journey.lastStep; step++) {
        final remaining = journey.remainingKm(step, 0);
        expect(remaining, lessThanOrEqualTo(previous));
        previous = remaining;
      }
      expect(journey.positionAt(journey.lastStep, 1), journey.customer);
      expect(journey.remainingKm(journey.lastStep, 1), 0);
      expect(
        OrderTrackingJourney.fromOrder(_order(coordinates: false), null),
        isNull,
      );
    },
  );

  test(
    'Native map data keeps two identified markers and a red route to SOS',
    () {
      final journey = OrderTrackingJourney.fromOrder(_order(), null)!;
      final data = OrderTrackingMapData(
        customer: journey.customer,
        mechanic: journey.positionAt(1, .5),
        route: journey.remainingRoute(1, .5),
        fullRoute: journey.points,
      );
      final markers = data.markers();
      expect(markers.length, 2);
      expect(
        markers
            .singleWhere((marker) => marker.markerId.value == 'customer-sos')
            .position,
        journey.customer,
      );
      expect(
        markers
            .singleWhere((marker) => marker.markerId.value == 'mechanic-bike')
            .position,
        data.mechanic,
      );
      expect(data.polylines.single.color, const Color(0xFFCC0001));
      expect(data.polylines.single.points.first, data.mechanic);
      expect(data.polylines.single.points.last, data.customer);
    },
  );

  testWidgets(
    'Tracking shows white/red status, mechanic, services and the exact checkout total',
    (tester) async {
      final map = _MapRecorder();
      await _open(tester, map: map);
      expect(find.byType(OrderTrackingScreen), findsOneWidget);
      expect(find.text('Thợ đang trên đường đến'), findsOneWidget);
      expect(find.text('Lộ trình mô phỏng'), findsOneWidget);
      expect(find.textContaining('Dự kiến đến trong 5 phút'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('Tiệm sửa xe Siêu Tốc'), findsOneWidget);
      expect(find.text('59-P1 688.99 (Honda Wave)'), findsOneWidget);
      await tester.ensureVisible(_key('tracking-total'));
      expect(find.text('Vá lốp không ruột'), findsOneWidget);
      expect(
        tester.widget<Text>(_key('tracking-total')).data,
        formatOrderPrice(50000),
      );
      expect(
        tester.widget<Text>(_key('tracking-total')).style!.color,
        HomeColors.red,
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        Colors.white,
      );
      expect(
        _state(tester).read(activityProvider).orders.single.status,
        RescueOrderStatus.pending,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '1.5-second checkpoints interpolate the mechanic and stop at SOS without accepting a real order',
    (tester) async {
      final map = _MapRecorder();
      await _open(tester, map: map, motion: true);
      final initial = map.data!.mechanic;
      final customer = map.data!.customer;
      await tester.pump(const Duration(milliseconds: 750));
      expect(map.data!.mechanic, isNot(initial));
      expect(map.data!.customer, customer);
      final midpoint = map.data!.mechanic;
      await tester.pump(const Duration(milliseconds: 1500));
      expect(map.data!.mechanic, isNot(midpoint));
      await tester.pump(const Duration(seconds: 30));
      expect(map.data!.mechanic, customer);
      expect(find.text('Thợ đã đến vị trí của bạn'), findsOneWidget);
      final end = map.data!.mechanic;
      await tester.pump(const Duration(seconds: 10));
      expect(map.data!.mechanic, end);
      expect(
        _state(tester).read(activityProvider).orders.single.status,
        RescueOrderStatus.pending,
      );
    },
  );

  testWidgets(
    'Reduced motion and app background pause simulation; disposal removes timers',
    (tester) async {
      final map = _MapRecorder();
      await _open(tester, map: map);
      final static = map.data!.mechanic;
      await tester.pump(const Duration(seconds: 5));
      expect(map.data!.mechanic, static);
      await _open(tester, map: map, motion: true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final paused = map.data!.mechanic;
      await tester.pump(const Duration(seconds: 4));
      expect(map.data!.mechanic, paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      expect(map.data!.mechanic, isNot(paused));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Cancel confirmation retains or cancels the shared order and stops movement',
    (tester) async {
      final map = _MapRecorder();
      await _open(tester, map: map, motion: true);
      await _tap(tester, _key('tracking-cancel'), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      await _tap(tester, find.text('Tiếp tục cứu hộ'), settle: false);
      expect(
        _state(tester).read(activityProvider).orders.single.status,
        RescueOrderStatus.pending,
      );
      await _tap(tester, _key('tracking-cancel'), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      await _tap(tester, find.text('Xác nhận hủy'), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        _state(tester).read(activityProvider).orders.single.status,
        RescueOrderStatus.cancelled,
      );
      expect(find.text('Đơn cứu hộ đã hủy'), findsOneWidget);
      final stopped = map.data!.mechanic;
      await tester.pump(const Duration(seconds: 5));
      expect(map.data!.mechanic, stopped);
      expect(_key('tracking-cancel'), findsNothing);
    },
  );

  testWidgets(
    'Phone uses the assigned number; a demo mechanic never dials a fabricated number',
    (tester) async {
      final launched = <Uri>[];
      await _open(
        tester,
        map: _MapRecorder(),
        launcher: (uri) async {
          launched.add(uri);
          return false;
        },
      );
      await _tap(tester, _key('tracking-call'));
      expect(launched, isEmpty);
      expect(
        find.textContaining('Thợ mô phỏng chưa có số điện thoại'),
        findsOneWidget,
      );
      await _open(
        tester,
        map: _MapRecorder(),
        order: _order(phone: '0912345678'),
        launcher: (uri) async {
          launched.add(uri);
          return false;
        },
      );
      await _tap(tester, _key('tracking-call'));
      expect(launched.single, Uri(scheme: 'tel', path: '0912345678'));
      expect(
        find.textContaining('Không thể mở ứng dụng gọi điện'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Chat retains local messages when closed and reopened', (
    tester,
  ) async {
    await _open(tester, map: _MapRecorder());
    await _tap(tester, _key('tracking-chat'));
    await tester.enterText(_key('tracking-chat-input'), 'Xe ở cổng màu xanh');
    await _tap(tester, _key('tracking-chat-send'));
    expect(find.text('Xe ở cổng màu xanh'), findsOneWidget);
    await _tap(tester, find.byTooltip('Đóng trò chuyện'));
    await _tap(tester, _key('tracking-chat'));
    expect(find.text('Xe ở cổng màu xanh'), findsOneWidget);
    expect(find.textContaining('chưa gửi tới thợ'), findsOneWidget);
  });

  testWidgets(
    'Missing coordinates and unknown IDs never invent an incident marker',
    (tester) async {
      final map = _MapRecorder();
      final router = await _open(
        tester,
        map: map,
        order: _order(coordinates: false),
      );
      expect(map.data, isNull);
      expect(find.text('Đang chuẩn bị lộ trình'), findsOneWidget);
      expect(_key('tracking-customer-marker'), findsNothing);
      router.go('/order-tracking?id=missing');
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy đơn cứu hộ.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Completed orders keep their status and disable communications', (
    tester,
  ) async {
    await _open(
      tester,
      map: _MapRecorder(),
      order: _order(status: RescueOrderStatus.completed),
    );
    expect(find.text('Cứu hộ đã hoàn tất'), findsOneWidget);
    await tester.ensureVisible(_key('tracking-chat'));
    expect(
      tester.widget<FilledButton>(_key('tracking-chat')).onPressed,
      isNull,
    );
    expect(_key('tracking-cancel'), findsNothing);
  });

  testWidgets(
    '320px, large text and a keyboard keep card actions and chat usable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester, map: _MapRecorder());
      await _tap(tester, _key('tracking-chat'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await tester.enterText(_key('tracking-chat-input'), 'Đối diện cây xăng');
      await _tap(tester, _key('tracking-chat-send'));
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Đóng trò chuyện'));
      await _tap(tester, _key('tracking-cancel'));
      expect(find.text('Hủy đơn cứu hộ?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
