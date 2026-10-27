import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/widgets/active_order_tracking_card.dart';

RescueOrder _order({
  RescueOrderStatus status = RescueOrderStatus.pending,
  bool hasProvider = false,
  int? etaMinutes,
  String locationAddress =
      '123 Nguyễn Văn Cừ, Phường An Khánh, Thành phố Thủ Đức',
}) {
  return RescueOrder(
    id: 'order-1',
    orderCode: 'RV240001',
    status: status,
    serviceType: RescueServiceType.flatTire,
    userVehicle: 'Honda Wave',
    locationAddress: locationAddress,
    basePrice: 120000,
    extraPartPrice: 0,
    discount: 0,
    createdAt: DateTime(2026, 10, 27, 9),
    providerName: hasProvider ? 'Anh Tuấn' : null,
    providerPhone: hasProvider ? '0901234567' : null,
    etaMinutes: etaMinutes,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required RescueOrder order,
  double width = 360,
  double textScale = 1.0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Center(
            child: SizedBox(
              width: width,
              child: ActiveOrderTrackingCard(order: order, onDetails: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders every status without layout errors', (tester) async {
    for (final status in RescueOrderStatus.values) {
      await _pump(
        tester,
        order: _order(
          status: status,
          hasProvider: status != RescueOrderStatus.pending,
          etaMinutes: status == RescueOrderStatus.enRoute ? 8 : null,
        ),
      );
      expect(tester.takeException(), isNull, reason: 'status=$status');
    }
  });

  testWidgets('survives narrow width and large text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pump(
      tester,
      order: _order(
        status: RescueOrderStatus.enRoute,
        hasProvider: true,
        etaMinutes: 12,
      ),
      width: 280,
      textScale: 1.6,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows status and ETA text', (tester) async {
    await _pump(
      tester,
      order: _order(
        status: RescueOrderStatus.enRoute,
        hasProvider: true,
        etaMinutes: 8,
      ),
    );
    expect(find.text('THỢ ĐANG ĐẾN'), findsOneWidget);
    expect(find.text('Đến trong: 8 phút'), findsOneWidget);
    expect(find.text('#RV240001'), findsOneWidget);
  });

  testWidgets('pending without provider shows searching copy', (tester) async {
    await _pump(tester, order: _order(status: RescueOrderStatus.pending));
    expect(find.text('ĐÃ GỬI YÊU CẦU'), findsOneWidget);
    expect(find.text('Đang tìm thợ'), findsOneWidget);
  });
}
