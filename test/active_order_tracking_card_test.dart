import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revo/core/theme/app_theme.dart';
import 'package:revo/features/activity/models/rescue_order.dart';
import 'package:revo/features/activity/providers/activity_provider.dart';
import 'package:revo/features/customer/presentation/widgets/active_order_tracking_card.dart';
import 'package:revo/features/home/screens/home_screen.dart';
import 'package:revo/features/home/widgets/smart_weather_rescue_card.dart';
import 'package:revo/features/rescue/screens/order_tracking_screen.dart';

import 'fixtures/marketplace_router_fixture.dart';

RescueOrder _order({
  RescueOrderStatus status = RescueOrderStatus.enRoute,
  int? etaMinutes = 7,
  String? providerName = 'Nguyễn Minh Tuấn',
}) => RescueOrder(
  id: 'tracking/home?order=1&source=test',
  orderCode: 'REVO-9824C',
  status: status,
  serviceType: RescueServiceType.flatTire,
  userVehicle: 'Honda Wave',
  locationAddress: '12 Nguyễn Huệ, Quận 1, TP.HCM',
  basePrice: 100000,
  extraPartPrice: 0,
  discount: 0,
  createdAt: DateTime(2026, 10, 19),
  providerName: providerName,
  etaMinutes: etaMinutes,
);

class _ActivityController extends ActivityController {
  void show(RescueOrder order) => state = ActivityState(orders: [order]);
}

Future<ProviderContainer> _openHome(
  WidgetTester tester, {
  List<RescueOrder> orders = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = marketplaceTestRouter(const HomeScreen());
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialRescueOrdersProvider.overrideWithValue(orders),
        activityProvider.overrideWith(_ActivityController.new),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
        builder: freezeMarketplaceMotion,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
}

void main() {
  testWidgets('Home inserts only an active order below the existing weather', (
    tester,
  ) async {
    final container = await _openHome(tester);
    final homeState = tester.state(find.byType(HomeScreen));
    final weather = tester.getRect(find.byType(SmartWeatherRescueCard));
    final stationsTop = tester.getTopLeft(find.text('Trạm cứu hộ')).dy;
    expect(find.byType(ActiveOrderTrackingCard), findsNothing);
    final controller =
        container.read(activityProvider.notifier) as _ActivityController;
    controller.show(_order());
    await tester.pumpAndSettle();
    final card = find.byType(ActiveOrderTrackingCard);
    expect(card, findsOneWidget);
    expect(tester.getRect(find.byType(SmartWeatherRescueCard)), weather);
    expect(tester.getTopLeft(card).dy, closeTo(weather.bottom + 16, 0.1));
    expect(find.text('#REVO-9824C'), findsOneWidget);
    expect(find.text('Đến trong: 7 phút'), findsOneWidget);
    expect(find.text(_order().locationAddress), findsOneWidget);

    controller.show(_order(status: RescueOrderStatus.repairing));
    await tester.pumpAndSettle();
    expect(find.text('ĐANG SỬA CHỮA'), findsOneWidget);
    expect(find.text('Đến trong: 7 phút'), findsNothing);

    controller.show(_order(status: RescueOrderStatus.completed));
    await tester.pumpAndSettle();
    expect(card, findsNothing);
    expect(tester.getTopLeft(find.text('Trạm cứu hộ')).dy, stationsTop);
    expect(tester.state(find.byType(HomeScreen)), same(homeState));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancelling the shared order removes the Home card', (
    tester,
  ) async {
    final order = _order();
    final container = await _openHome(tester, orders: [order]);
    expect(find.byType(ActiveOrderTrackingCard), findsOneWidget);
    expect(
      container.read(activityProvider.notifier).cancelOrder(order.id),
      true,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ActiveOrderTrackingCard), findsNothing);
    expect(find.byType(SmartWeatherRescueCard), findsOneWidget);
  });

  testWidgets('Quick action opens tracking for the exact saved order ID', (
    tester,
  ) async {
    final order = _order();
    await _openHome(tester, orders: [order]);
    final details = find.byTooltip('Theo dõi đơn ${order.orderCode}');
    await tester.ensureVisible(details);
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OrderTrackingScreen>(find.byType(OrderTrackingScreen))
          .orderId,
      order.id,
    );
    expect(tester.takeException(), isNull);
  });

  for (final (status, step, title) in [
    (RescueOrderStatus.pending, 'Đã nhận đơn', 'ĐÃ NHẬN ĐƠN'),
    (RescueOrderStatus.enRoute, 'Thợ đang đến', 'THỢ ĐANG ĐẾN'),
    (RescueOrderStatus.repairing, 'Đang sửa chữa', 'ĐANG SỬA CHỮA'),
    (RescueOrderStatus.completed, 'Hoàn thành', 'ĐÃ HOÀN THÀNH'),
  ]) {
    testWidgets(
      'Timeline reflects ${status.name} without advancing the order',
      (tester) async {
        final order = _order(status: status);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActiveOrderTrackingCard(order: order, onDetails: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        final selected = tester.widget<Semantics>(
          find
              .ancestor(of: find.text(step), matching: find.byType(Semantics))
              .first,
        );
        expect(selected.properties.selected, true);
        expect(order.status, status);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Missing ETA and an unassigned request have honest labels', (
    tester,
  ) async {
    for (final (order, label) in [
      (_order(etaMinutes: null), 'Đang cập nhật ETA'),
      (_order(etaMinutes: 0), 'Thợ sắp đến'),
      (
        _order(status: RescueOrderStatus.pending, providerName: null),
        'Đang tìm thợ',
      ),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveOrderTrackingCard(order: order, onDetails: () {}),
          ),
        ),
      );
      expect(find.text(label), findsOneWidget);
      expect(find.text('Đến trong: 5–10 phút'), findsNothing);
      if (!order.hasProvider) {
        expect(find.text('ĐÃ GỬI YÊU CẦU'), findsOneWidget);
        expect(find.text('THỢ ĐANG ĐẾN'), findsNothing);
      }
    }
  });

  testWidgets('Card fits 320px, large text and both text directions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Directionality(
                textDirection: direction,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ActiveOrderTrackingCard(
                    order: _order(),
                    onDetails: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('THỢ ĐANG ĐẾN'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
