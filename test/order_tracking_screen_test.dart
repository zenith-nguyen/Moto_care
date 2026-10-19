import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as images;
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/activity/services/activity_actions.dart';
import 'package:moto_care/features/activity/widgets/order_summary.dart';
import 'package:moto_care/features/rescue/models/order_tracking_journey.dart';
import 'package:moto_care/features/rescue/models/tracking_update.dart';
import 'package:moto_care/features/rescue/models/tracking_mechanic.dart';
import 'package:moto_care/features/rescue/services/order_tracking_feed.dart';
import 'package:moto_care/features/rescue/screens/order_tracking_screen.dart';
import 'package:moto_care/features/rescue/widgets/order_tracking_map.dart';
import 'package:moto_care/features/payments/data/payments_repository.dart';
import 'package:moto_care/features/payments/domain/bank_transfer_instructions.dart';
import 'package:moto_care/features/payments/domain/demo_payment_result.dart';

class _UnavailablePaymentsRepository implements PaymentsRepository {
  @override
  Future<BankTransferInstructions> getTransferInstructions(int orderId) =>
      Future.error(StateError('Payment test fixture unavailable'));

  @override
  Future<DemoPrepaymentResult> confirmDemoPrepayment(int orderId) =>
      Future.error(StateError('Payment test fixture unavailable'));

  @override
  Future<DemoAdjustmentResult> confirmDemoAdjustment(int orderId) =>
      Future.error(StateError('Payment test fixture unavailable'));
}

RescueOrder _order({
  String id = 'tracking-001',
  RescueOrderStatus status = RescueOrderStatus.pending,
  bool coordinates = true,
  String? phone,
  bool awaitingPrepayment = false,
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
  awaitingPrepayment: awaitingPrepayment,
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

class _TrackingFeed implements OrderTrackingFeed {
  int subscriptions = 0;
  final watchedOrders = <String>[];
  late final controller = StreamController<TrackingUpdate>.broadcast(
    onListen: () => subscriptions++,
    onCancel: () => subscriptions--,
  );
  @override
  Stream<TrackingUpdate> watchOrder(String orderId) {
    watchedOrders.add(orderId);
    return controller.stream;
  }
}

TrackingUpdate _update({
  int minute = 0,
  String orderId = 'tracking-001',
  LatLng mechanic = const LatLng(10.761, 106.661),
  List<LatLng>? route,
  double distance = 1.2,
  int eta = 5,
  bool arrived = false,
}) => TrackingUpdate(
  orderId: orderId,
  observedAt: DateTime.utc(2026, 10, 9, 9, minute),
  mechanic: mechanic,
  route:
      route ??
      [mechanic, const LatLng(10.759, 106.665), const LatLng(10.757, 106.668)],
  remainingDistanceKm: distance,
  etaMinutes: eta,
  arrived: arrived,
  mechanicDetails: const TrackingMechanic(
    name: 'Trần Minh Hải',
    plate: '59-B2 567.89',
    phoneNumber: '0901234567',
  ),
);

Future<GoRouter> _open(
  WidgetTester tester, {
  required _MapRecorder map,
  RescueOrder? order,
  bool motion = false,
  Future<bool> Function(Uri)? launcher,
  String path = '/order-tracking?id=tracking-001',
  OrderTrackingFeed? feed,
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialRescueOrdersProvider.overrideWithValue([order ?? _order()]),
        orderTrackingMapBuilderProvider.overrideWithValue(map.build),
        orderTrackingFeedProvider.overrideWithValue(feed),
        activityUrlLauncherProvider.overrideWithValue(
          launcher ?? (_) async => true,
        ),
        paymentsRepositoryProvider.overrideWithValue(
          _UnavailablePaymentsRepository(),
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
  testWidgets(
    'An unpaid runtime order cannot appear to be matching a provider',
    (tester) async {
      final router = await _open(
        tester,
        map: _MapRecorder(),
        order: _order(id: '1', awaitingPrepayment: true),
        path: '/order-tracking?id=1',
      );
      await tester.pump();
      expect(router.state.uri.path, '/bank-transfer');
      expect(router.state.uri.queryParameters['id'], '1');
    },
  );

  testWidgets(
    'Backend route and GPS update the card even with reduced motion',
    (tester) async {
      final feed = _TrackingFeed();
      addTearDown(feed.controller.close);
      final map = _MapRecorder();
      await _open(tester, map: map, feed: feed);
      expect(feed.watchedOrders, ['tracking-001']);
      expect(map.data!.mechanic, isNull);
      expect(map.data!.markers().length, 1);
      expect(find.text('Đang kết nối'), findsOneWidget);
      expect(find.text('Nguyễn Minh Tuấn'), findsNothing);
      final event = _update();
      feed.controller.add(event);
      await tester.pumpAndSettle();
      expect(map.data!.customer, const LatLng(10.757, 106.668));
      expect(map.data!.mechanic, event.mechanic);
      expect(map.data!.route, event.route);
      expect(map.data!.isSimulated, isFalse);
      expect(find.text('Trần Minh Hải'), findsOneWidget);
      expect(find.text('59-B2 567.89'), findsOneWidget);
      expect(find.text('1.2 km'), findsOneWidget);
      expect(find.text('5 phút'), findsOneWidget);
      expect(find.text('Lộ trình mô phỏng'), findsNothing);
      final next = _update(
        minute: 1,
        mechanic: const LatLng(10.758, 106.666),
        distance: .4,
        eta: 2,
      );
      feed.controller.add(next);
      await tester.pumpAndSettle();
      expect(map.data!.mechanic, next.mechanic);
      expect(map.data!.polylines.single.points, next.route);
      expect(find.text('0.4 km'), findsOneWidget);
      expect(find.text('2 phút'), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(map.data!.mechanic, next.mechanic);
      expect(
        _state(tester).read(activityProvider).orders.single.status,
        RescueOrderStatus.pending,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Stale and other-order updates are ignored; disconnection retains the last position',
    (tester) async {
      final feed = _TrackingFeed();
      addTearDown(feed.controller.close);
      final map = _MapRecorder();
      await _open(tester, map: map, feed: feed, motion: true);
      feed.controller.add(_update(minute: 2));
      await tester.pumpAndSettle();
      final last = map.data!.mechanic;
      feed.controller.add(
        _update(minute: 1, mechanic: const LatLng(10.8, 106.7)),
      );
      feed.controller.add(
        _update(
          minute: 3,
          orderId: 'other',
          mechanic: const LatLng(10.9, 106.8),
        ),
      );
      await tester.pumpAndSettle();
      expect(map.data!.mechanic, last);
      feed.controller.addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(map.data!.mechanic, last);
      expect(find.textContaining('Mất kết nối'), findsOneWidget);
      feed.controller.add(
        _update(
          minute: 4,
          mechanic: const LatLng(10.757, 106.668),
          distance: 0,
          eta: 0,
          arrived: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thợ đã đến'), findsOneWidget);
      expect(find.text('0.0 km'), findsOneWidget);
      expect(find.textContaining('Mất kết nối'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(feed.subscriptions, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Cancelling an order unsubscribes from GPS and preserves its last location',
    (tester) async {
      final feed = _TrackingFeed();
      addTearDown(feed.controller.close);
      final map = _MapRecorder();
      await _open(tester, map: map, feed: feed);
      feed.controller.add(_update());
      await tester.pumpAndSettle();
      final last = map.data!.mechanic;
      await _tap(tester, _key('tracking-cancel'));
      await _tap(tester, find.byKey(const ValueKey('cancel-reason-long_wait')));
      await _tap(tester, find.byKey(const ValueKey('cancel-confirm')));
      expect(feed.subscriptions, 0);
      feed.controller.add(
        _update(minute: 3, mechanic: const LatLng(10.8, 106.7)),
      );
      await tester.pumpAndSettle();
      expect(map.data!.mechanic, last);
      expect(find.text('Đã hủy đơn thành công'), findsOneWidget);
      expect(find.byType(OrderTrackingScreen), findsNothing);
    },
  );

  testWidgets(
    'Live contacts open the selected mechanic chat and dial the feed phone',
    (tester) async {
      final feed = _TrackingFeed();
      addTearDown(feed.controller.close);
      final launched = <Uri>[];
      final router = await _open(
        tester,
        map: _MapRecorder(),
        feed: feed,
        launcher: (uri) async {
          launched.add(uri);
          return true;
        },
      );
      feed.controller.add(_update());
      await tester.pumpAndSettle();
      await _tap(tester, _key('tracking-call'));
      expect(launched.single, Uri(scheme: 'tel', path: '0901234567'));
      await _tap(tester, _key('tracking-chat'));
      expect(router.state.uri.path, '/chat-detail');
      expect(find.text('Trần Minh Hải'), findsOneWidget);
      expect(find.textContaining('MC-TRACK-001'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Theo dõi trực tiếp'), findsOneWidget);
    },
  );

  test(
    'Empty service routes still fit both people and route lists are immutable',
    () {
      final route = <LatLng>[const LatLng(10.758, 106.665)];
      final update = _update(route: route);
      route.clear();
      expect(update.route.length, 1);
      expect(() => update.route.clear(), throwsUnsupportedError);
      for (final points in [<LatLng>[], update.route]) {
        final data = OrderTrackingMapData(
          customer: const LatLng(10.757, 106.668),
          mechanic: update.mechanic,
          route: points,
          fullRoute: points,
          isSimulated: false,
        );
        expect(data.cameraBounds.contains(data.customer), isTrue);
        expect(data.cameraBounds.contains(update.mechanic), isTrue);
        expect(data.polylines, isEmpty);
      }
      expect(() => _update(distance: -1), throwsArgumentError);
      expect(() => _update(eta: -1), throwsArgumentError);
    },
  );
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

  test('Native map data keeps both markers and a red width-5 route to SOS', () {
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
    for (final marker in markers.where(
      (marker) => marker.markerId.value == 'customer-sos',
    )) {
      final icon = marker.icon as BytesMapBitmap;
      final bitmap = images.decodePng(icon.byteData)!;
      var hasBlack = false;
      for (final pixel in bitmap) {
        if (pixel.a == 0) continue;
        expect(pixel.r, pixel.g);
        expect(pixel.g, pixel.b);
        hasBlack |= pixel.r == 0;
      }
      expect(hasBlack, isTrue);
    }
    expect(data.polylines.single.color, const Color(0xFFE53935));
    expect(data.polylines.single.width, 5);
    final bike =
        markers
                .singleWhere(
                  (marker) => marker.markerId.value == 'mechanic-bike',
                )
                .icon
            as BytesMapBitmap;
    final bikeBitmap = images.decodePng(bike.byteData)!;
    expect(
      bikeBitmap.any(
        (pixel) =>
            pixel.r == 229 && pixel.g == 57 && pixel.b == 53 && pixel.a > 0,
      ),
      isTrue,
    );
    expect(data.polylines.single.points.first, data.mechanic);
    expect(data.polylines.single.points.last, data.customer);
  });

  testWidgets(
    'Tracking keeps the map full screen, with compact status and the exact checkout total',
    (tester) async {
      final map = _MapRecorder();
      await _open(tester, map: map);
      expect(find.byType(OrderTrackingScreen), findsOneWidget);
      expect(find.text('Thợ đang trên đường đến'), findsOneWidget);
      expect(find.text('Lộ trình mô phỏng'), findsOneWidget);
      expect(find.textContaining('Dự kiến đến trong 5 phút'), findsOneWidget);
      expect(find.text('Nguyễn Minh Tuấn'), findsOneWidget);
      expect(find.text('Tiệm sửa xe Siêu Tốc'), findsOneWidget);
      expect(find.text('59-X1 123.45'), findsOneWidget);
      expect(find.text('Theo dõi trực tiếp'), findsOneWidget);
      expect(find.text('Cứu hộ xe máy'), findsOneWidget);
      expect(find.text('Đang trên đường đến'), findsOneWidget);
      expect(
        tester.getSize(_key('order-tracking-schematic')),
        tester.getSize(find.byType(Scaffold)),
      );
      await tester.ensureVisible(_key('tracking-total'));
      expect(find.text('Vá lốp không ruột'), findsOneWidget);
      expect(
        tester.widget<Text>(_key('tracking-total')).data,
        formatOrderPrice(50000),
      );
      expect(
        tester.widget<Text>(_key('tracking-total')).style!.color,
        Colors.black,
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
      await _tap(
        tester,
        find.byKey(const ValueKey('cancel-reason-long_wait')),
        settle: false,
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('cancel-confirm')),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        _state(tester).read(activityProvider).orders.single.status,
        RescueOrderStatus.cancelled,
      );
      expect(find.text('Đã hủy đơn thành công'), findsOneWidget);
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
      tester
          .widget<IconButton>(
            find.descendant(
              of: _key('tracking-chat'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
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
      expect(find.text('Lý do bạn muốn hủy đơn?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
