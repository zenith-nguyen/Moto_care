import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/core/network/api_failure.dart';
import 'package:moto_care/features/orders/data/orders_repository.dart';
import 'package:moto_care/features/orders/domain/order_models.dart';
import 'package:moto_care/features/payments/data/payments_repository.dart';
import 'package:moto_care/features/payments/screens/bank_transfer_screen.dart';

/// Fake PaymentsRepository: getTransferInstructions luôn ném lỗi đã cấu hình.
class _FakePayments implements PaymentsRepository {
  _FakePayments(this.error);
  final Object error;

  @override
  Future<Never> getTransferInstructions(int orderId) async => throw error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake OrdersRepository: getById trả về đơn với status cấu hình sẵn.
class _FakeOrders implements OrdersRepository {
  _FakeOrders(this.statusWire);
  final String statusWire;
  int getByIdCount = 0;

  @override
  Future<OrderDetails> getById(int orderId) async {
    getByIdCount += 1;
    return OrderDetails.fromJson(_detailsJson(statusWire));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  required Object instructionsError,
  String orderStatusWire = 'PENDING_MATCH',
}) async {
  final orders = _FakeOrders(orderStatusWire);
  final router = GoRouter(
    initialLocation: '/bank-transfer?id=42',
    routes: [
      GoRoute(
        path: '/bank-transfer',
        builder: (context, state) => BankTransferScreen(
          orderId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/order-tracking',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('TRACKING'))),
      ),
      GoRoute(
        path: '/hoat-dong',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('ACTIVITY'))),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        paymentsRepositoryProvider.overrideWithValue(
          _FakePayments(instructionsError),
        ),
        ordersRepositoryProvider.overrideWithValue(orders),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets(
    '409 conflict khi tải instructions thì tự điều hướng sang order-tracking',
    (tester) async {
      final router = await _pump(
        tester,
        instructionsError: const ApiFailure(
          kind: ApiFailureKind.conflict,
          message: 'Order is not awaiting bank-transfer prepayment',
          statusCode: 409,
        ),
      );

      expect(router.routeInformationProvider.value.uri.path, '/order-tracking');
      expect(find.text('TRACKING'), findsOneWidget);
      // Không hiện màn lỗi, không có nút Thử lại gây lặp 409.
      expect(find.text('Chưa tải được thông tin chuyển khoản.'), findsNothing);
      expect(find.text('Thử lại'), findsNothing);
    },
  );

  testWidgets(
    'lỗi không phải 409 vẫn hiển thị màn lỗi và ở lại trang thanh toán',
    (tester) async {
      final router = await _pump(
        tester,
        instructionsError: const ApiFailure(
          kind: ApiFailureKind.network,
          message: 'Không thể kết nối tới máy chủ.',
        ),
      );

      expect(router.routeInformationProvider.value.uri.path, '/bank-transfer');
      expect(
        find.text('Chưa tải được thông tin chuyển khoản.'),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );
}

Map<String, dynamic> _detailsJson(String statusWire) => {
  'id': 42,
  'code': 'MC-42',
  'status': statusWire,
  'customerId': 7,
  'providerId': null,
  'incidentType': {'id': 1, 'name': 'Xẹp lốp'},
  'customerLocation': {
    'type': 'Point',
    'coordinates': [106.7009, 10.7769],
  },
  'estimatedPrice': '110000.00',
  'pricing': _pricingJson(),
  'extraCost': '0.00',
  'discountAmount': '0.00',
  'finalPrice': null,
  'payment': null,
  'providerLocation': null,
  'message': null,
  'priceProposal': null,
  'paymentAdjustment': null,
};

Map<String, dynamic> _pricingJson() => {
  'basePrice': '100000.00',
  'weatherSurcharge': '10000.00',
  'weatherMultiplier': '1.1000',
  'weatherCategory': 'MODERATE',
  'weatherSource': 'OPEN_METEO',
  'weatherObservedAt': '2026-10-09T07:55:00.000Z',
  'weatherCode': 61,
  'precipitationMm': '1.20',
  'windSpeedKmh': '12.00',
  'windGustKmh': '20.00',
  'attribution': 'Weather data by Open-Meteo.com',
};
