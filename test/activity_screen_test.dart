import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/home/theme/home_theme.dart';
import 'package:moto_care/features/activity/data/mock_rescue_orders.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/activity/screens/chi_tiet_don_hang_screen.dart';
import 'package:moto_care/features/activity/screens/hoat_dong_screen.dart';
import 'package:moto_care/features/activity/services/activity_actions.dart';
import 'package:moto_care/features/activity/widgets/activity_order_card.dart';
import 'package:moto_care/features/services/screens/services_screen.dart';
import 'package:moto_care/features/profile/screens/profile_screen.dart';
import 'package:moto_care/features/activity/widgets/order_summary.dart';
import 'package:moto_care/features/chat/screens/chat_detail_screen.dart';
import 'package:moto_care/features/home/models/home_user.dart';
import 'package:moto_care/features/home/screens/trang_chu.dart';
import 'package:moto_care/features/home/widgets/home_bottom_navigation.dart';

Future<GoRouter> _open(
  WidgetTester tester, {
  String location = '/hoat-dong',
  List<RescueOrder>? orders,
  Future<bool> Function(Uri)? launcher,
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (orders != null)
          initialRescueOrdersProvider.overrideWithValue(orders),
        if (launcher != null)
          activityUrlLauncherProvider.overrideWithValue(launcher),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ),
  );
  router.go(
    location,
    extra: location == '/trang-chu'
        ? const HomeUser(displayName: 'Nguyễn Văn An', memberId: '15335206')
        : null,
  );
  await tester.pumpAndSettle();
  return router;
}

ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

Future<void> _reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final scrollable = find
        .byElementPredicate((element) {
          if (element.widget is! Scrollable) return false;
          final state = (element as StatefulElement).state as ScrollableState;
          return state.widget.axisDirection == AxisDirection.down &&
              state.position.maxScrollExtent > 0;
        })
        .hitTestable()
        .last;
    await tester.scrollUntilVisible(target, 120, scrollable: scrollable);
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Finder _bottom(String label) => find.descendant(
  of: find.byType(HomeBottomNavigation),
  matching: find.text(label),
);

void main() {
  testWidgets(
    'Active order shows all progress stages, provider, ETA and actions',
    (tester) async {
      await _open(tester, location: '/chi-tiet-don-hang?id=active-001');
      final stepper = tester.widget<Stepper>(find.byType(Stepper));
      expect(stepper.steps.length, 4);
      expect(stepper.currentStep, 2);
      for (final label in ['Đã gửi', 'Thợ nhận', 'Đang đến', 'Đang sửa']) {
        expect(
          find.descendant(of: find.byType(Stepper), matching: find.text(label)),
          findsOneWidget,
        );
      }
      expect(
        Theme.of(tester.element(find.byType(Stepper))).scaffoldBackgroundColor,
        HomeColors.background,
      );
      expect(find.text('Nguyễn Minh Tuấn'), findsOneWidget);
      expect(find.text('59-A1 456.78'), findsOneWidget);
      expect(find.text('1,8 km • Khoảng 5 phút'), findsOneWidget);
      for (final label in ['Mở bản đồ', 'Gọi điện', 'Chat', 'Hủy đơn']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Unassigned pending order disables provider actions', (
    tester,
  ) async {
    final pending = RescueOrder.fromJson({
      ...mockRescueOrders.first.toJson(),
      'status': 'pending',
      'providerName': null,
      'providerPhone': null,
      'providerPlate': null,
      'providerDistanceKm': null,
      'etaMinutes': null,
    });
    await _open(
      tester,
      orders: [pending],
      location: '/chi-tiet-don-hang?id=active-001',
    );
    expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 0);
    expect(find.text('Đang tìm thợ gần bạn'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Gọi điện'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Chat'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Cancellation requires confirmation and moves the order to history',
    (tester) async {
      await _open(tester, location: '/chi-tiet-don-hang?id=active-001');
      await _tap(tester, find.text('Hủy đơn'));
      await _tap(tester, find.text('Tiếp tục cứu hộ'));
      expect(_state(tester).read(activityProvider).activeOrders.length, 1);
      await _tap(tester, find.text('Hủy đơn'));
      await _tap(tester, find.text('Xác nhận hủy'));
      expect(find.byType(Stepper), findsNothing);
      expect(
        _state(tester).read(activityProvider).orderById('active-001')!.status,
        RescueOrderStatus.cancelled,
      );
      await _tap(tester, find.byTooltip('Quay lại'));
      expect(find.text('MC-261002-001'), findsOneWidget);
      expect(find.text('Đã hủy'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('No orders and filters give useful empty states', (tester) async {
    await _open(tester, orders: []);
    expect(find.text('Chưa có hoạt động nào'), findsOneWidget);
    await _tap(
      tester,
      find.byKey(const ValueKey('activity-filter-maintenance')),
    );
    expect(find.text('Chưa có hoạt động đặt lịch bảo dưỡng'), findsOneWidget);
  });

  testWidgets(
    'History opens the selected white invoice with correct charges and stars',
    (tester) async {
      final router = await _open(
        tester,
        orders: mockRescueOrders.skip(1).toList(),
      );
      final card = find.byKey(const ValueKey('completed-001'));
      expect(
        find.descendant(
          of: card,
          matching: find.text(formatOrderPrice(150000)),
        ),
        findsOneWidget,
      );
      await _tap(
        tester,
        find.descendant(of: card, matching: find.text('Chi tiết đơn')),
      );
      expect(router.state.uri.path, '/chi-tiet-don-hang');
      expect(router.state.uri.queryParameters['id'], 'completed-001');
      expect(find.byType(ChiTietDonHangScreen), findsOneWidget);
      final invoice = find.ancestor(
        of: find.text('HÓA ĐƠN'),
        matching: find.byType(Card),
      );
      expect(tester.widget<Card>(invoice).color, Colors.white);
      for (final label in [
        'Phí di chuyển',
        'Phí công sửa',
        'Phụ tùng phát sinh',
        'Voucher',
        'Tổng thanh toán',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text(formatOrderPrice(150000)), findsOneWidget);
      expect(find.text('- ${formatOrderPrice(20000)}'), findsOneWidget);
      await _reveal(tester, find.byIcon(Icons.star_half_rounded));
      expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
      await _tap(tester, find.byTooltip('Quay lại'));
      expect(find.byType(ActivityOrderCard), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Rebooking from invoice confirms location and shows a fresh pending order',
    (tester) async {
      await _open(
        tester,
        orders: [mockRescueOrders[1]],
        location: '/chi-tiet-don-hang?id=completed-001',
      );
      await _tap(tester, find.text('Đặt cứu hộ lại'));
      final address = find.widgetWithText(TextFormField, 'Địa chỉ cứu hộ');
      await tester.enterText(address, '20 Nguyễn Huệ, TP. Hồ Chí Minh');
      await _tap(tester, find.text('Xác nhận đặt lại'));
      expect(find.byType(HoatDongScreen), findsOneWidget);
      final order = _state(tester).read(activityProvider).activeOrders.single;
      expect(order.locationAddress, '20 Nguyễn Huệ, TP. Hồ Chí Minh');
      expect(order.status, RescueOrderStatus.pending);
      expect(order.providerName, isNull);
      expect(find.text('Đang tìm thợ gần bạn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Rebooking history shows the fresh order and prevents duplicate orders',
    (tester) async {
      await _open(tester, orders: [mockRescueOrders[1]]);
      await _tap(tester, find.text('Gọi lại đơn này'));
      await _tap(tester, find.text('Xác nhận đặt lại'));
      expect(find.text('Đang tìm thợ gần bạn'), findsOneWidget);
      expect(_state(tester).read(activityProvider).activeOrders.length, 1);
      await _tap(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('completed-001')),
          matching: find.text('Gọi lại đơn này'),
        ),
      );
      expect(
        find.text(
          'Bạn đang có đơn cứu hộ. Hãy hoàn tất hoặc hủy đơn trước khi đặt lại.',
        ),
        findsOneWidget,
      );
      expect(_state(tester).read(activityProvider).activeOrders.length, 1);
    },
  );

  testWidgets('Ratings and validated complaints update the selected order', (
    tester,
  ) async {
    await _open(tester, location: '/chi-tiet-don-hang?id=completed-001');
    await _tap(tester, find.byTooltip('Đánh giá 5 sao'));
    await _tap(tester, find.text('Lưu đánh giá'));
    expect(
      _state(tester).read(activityProvider).orderById('completed-001')!.rating,
      5,
    );
    await _tap(tester, find.text('Báo cáo / Khiếu nại'));
    await _tap(tester, find.text('Lưu khiếu nại'));
    expect(find.text('Vui lòng nhập ít nhất 10 ký tự'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      'Chi phí phụ tùng chưa rõ ràng.',
    );
    await _tap(tester, find.text('Lưu khiếu nại'));
    expect(
      _state(tester).read(activityProvider).complaints.single.orderId,
      'completed-001',
    );
    expect(find.text('Đã lưu khiếu nại trong phiên dùng thử.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Map and phone launch the selected address and number; chat receives provider',
    (tester) async {
      final urls = <Uri>[];
      final router = await _open(
        tester,
        location: '/chi-tiet-don-hang?id=active-001',
        launcher: (uri) async {
          urls.add(uri);
          return true;
        },
      );
      await _tap(tester, find.text('Mở bản đồ'));
      await _tap(tester, find.text('Gọi điện'));
      expect(urls.first.host, 'www.google.com');
      expect(urls.first.queryParameters['api'], '1');
      expect(
        urls.first.queryParameters['query'],
        mockRescueOrders.first.locationAddress,
      );
      expect(urls.last, Uri.parse('tel:0900000001'));
      await _tap(tester, find.text('Chat'));
      expect(router.state.uri.path, '/chat-detail');
      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.text('Nguyễn Minh Tuấn'), findsOneWidget);
      expect(find.text('Đang đến'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Unavailable external apps show the address and phone as fallbacks',
    (tester) async {
      await _open(
        tester,
        location: '/chi-tiet-don-hang?id=active-001',
        launcher: (uri) async {
          if (uri.scheme == 'tel') throw PlatformException(code: 'unavailable');
          return false;
        },
      );
      await _tap(tester, find.text('Mở bản đồ'));
      expect(
        find.text(
          'Không thể mở bản đồ. Địa chỉ cứu hộ: ${mockRescueOrders.first.locationAddress}',
        ),
        findsOneWidget,
      );
      await _tap(tester, find.text('Gọi điện'));
      expect(
        find.text('Không thể mở ứng dụng gọi điện. Số thợ: 0900000001'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Bottom navigation connects Home, Activity, Services and Account and preserves account',
    (tester) async {
      await _open(tester, location: '/trang-chu');
      await _tap(tester, _bottom('Hoạt động'));
      expect(find.byType(HoatDongScreen), findsOneWidget);
      await _tap(tester, _bottom('Dịch vụ'));
      expect(find.byType(ServicesScreen), findsOneWidget);
      await _tap(tester, _bottom('Tài khoản'));
      expect(find.byType(ProfileScreen), findsOneWidget);
      await _tap(tester, _bottom('Hoạt động'));
      expect(find.byType(HoatDongScreen), findsOneWidget);
      await _tap(tester, _bottom('Trang chủ'));
      expect(find.byType(TrangChu), findsOneWidget);
      expect(find.text('Chào Nguyễn Văn An'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final location in [
    '/chi-tiet-don-hang',
    '/chi-tiet-don-hang?id=unknown',
  ]) {
    testWidgets(
      'Invalid invoice $location returns to Activity without inventing an order',
      (tester) async {
        await _open(tester, location: location);
        expect(
          find.text('Không tìm thấy đơn hàng. Vui lòng quay lại Hoạt động.'),
          findsOneWidget,
        );
        await _tap(tester, find.byTooltip('Quay lại'));
        expect(find.byType(HoatDongScreen), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Small screens support large text across orders, invoice and dialogs',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester, location: '/chi-tiet-don-hang?id=active-001');
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Hủy đơn'));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Tiếp tục cứu hộ'));
      await _tap(tester, find.byTooltip('Quay lại'));
      await _tap(tester, find.text('Chi tiết đơn').first);
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Báo cáo / Khiếu nại'));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Đóng'));
      expect(tester.takeException(), isNull);
    },
  );
}
