import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/mechanic_account_screen.dart';
import 'package:motocare_mechanic/screens/notifications_screen.dart';
import 'package:motocare_mechanic/screens/service_management_screen.dart';
import 'package:motocare_mechanic/screens/settings_screen.dart';
import 'package:motocare_mechanic/screens/withdraw_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/revo_switch.dart';

void main() {
  setUp(() {
    appState.activeOrder = null;
    appState.profile = MockData.profile();
    appState.setNetworkAvailable(true);
    appState.setGps(true);
    appState.setOnline(true);
    appState.saveServices([true, true, true, true, true, false, false]);
    appState.setTab(0);
  });
  Future<void> host(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: page));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.pumpAndSettle();
    final finder = find.text(label);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 180,
          scrollable: find.byType(Scrollable).last);
    }
    if (finder.last.hitTestable().evaluate().isEmpty) {
      await tester.ensureVisible(finder.last);
      await tester.pumpAndSettle();
    }
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> close(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets(
      'Profile validation and save update the account after navigating back',
      (tester) async {
    appState.setTab(3);
    await host(tester, const MechanicShell());
    await tap(tester, 'Thông tin cá nhân');
    expect(find.byType(ProfileEditScreen), findsOneWidget);
    final name = find.byType(TextFormField).first;
    await tester.enterText(name, 'A');
    await tap(tester, 'Lưu thay đổi');
    expect(find.text('Vui lòng nhập họ tên.'), findsOneWidget);
    await tester.enterText(name, 'Nguyễn Minh Hùng');
    await tap(tester, 'Lưu thay đổi');
    expect(appState.profile.name, 'Nguyễn Minh Hùng');
    await tester.drag(find.byType(ListView).last, const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh Hùng'), findsOneWidget);
    await close(tester);
  });

  testWidgets(
      'Service switches save and actually exclude that service from offers',
      (tester) async {
    await host(tester, const ServiceManagementScreen());
    await tester.tap(find.byType(RevoSwitch).first);
    await tester.pumpAndSettle();
    await tap(tester, 'Lưu thay đổi');
    expect(appState.services.first.enabled, isFalse);
    expect(() => appState.nextOffer(serviceIndex: 0), throwsStateError);
    expect(appState.nextOffer(serviceIndex: 1).issue, 'Xẹp lốp');
    await close(tester);
  });

  testWidgets('Turning off every service cannot save invalid preferences',
      (tester) async {
    await host(tester, const ServiceManagementScreen());
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byType(RevoSwitch).at(i));
      await tester.pumpAndSettle();
    }
    await tap(tester, 'Lưu thay đổi');
    expect(find.text('Vui lòng bật ít nhất một dịch vụ.'), findsOneWidget);
    expect(appState.services.take(5).every((s) => s.enabled), isTrue);
    await close(tester);
  });

  testWidgets(
      'Notification category filters and mark-all-read change the shared unread state',
      (tester) async {
    appState.notifications
      ..clear()
      ..addAll([
        RevoNotification('Thông báo đơn thử', 'Đơn thử', orderRelated: true),
        RevoNotification('Thông báo ví thử', 'Ví thử', orderRelated: false),
      ]);
    await host(tester, const NotificationsScreen());
    await tester.tap(find.byTooltip('Lọc thông báo'));
    await tester.pumpAndSettle();
    await tap(tester, 'Đơn hàng');
    expect(find.text('Thông báo ví thử'), findsNothing);
    expect(find.text('Thông báo đơn thử'), findsOneWidget);
    await tester.tap(find.byTooltip('Lọc thông báo'));
    await tester.pumpAndSettle();
    await tap(tester, 'Hệ thống');
    expect(find.text('Thông báo đơn thử'), findsNothing);
    await tester.tap(find.byTooltip('Lọc thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notification-mark-all')));
    await tester.pumpAndSettle();
    expect(appState.unreadCount, 0);
    await close(tester);
  });

  testWidgets(
      'Home income opens summary and history link returns to Orders without losing active order',
      (tester) async {
    final order = appState.acceptOffer(appState.nextOffer(serviceIndex: 0));
    await host(tester, const MechanicShell());
    await tap(tester, 'Xem lịch');
    await tap(tester, 'Thu nhập hôm nay');
    expect(find.text('Thu nhập tuần này'), findsOneWidget);
    await tap(tester, 'Xem tất cả');
    expect(appState.tabIndex, 1);
    expect(appState.activeOrder, same(order));
    await close(tester);
  });

  testWidgets('Order search empty state can recover without deleting history',
      (tester) async {
    final count = appState.history.length;
    appState.setTab(1);
    await host(tester, const MechanicShell());
    await tester.tap(find.byTooltip('Tìm đơn hàng'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'NO_SUCH_ORDER');
    await tester.pumpAndSettle();
    expect(find.text('Chưa có đơn hàng phù hợp'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(appState.history.length, count);
    expect(find.text('Không có dữ liệu'), findsNothing);
    await close(tester);
  });

  testWidgets('Offline withdrawal shows an error and never reserves money',
      (tester) async {
    final before = appState.balance;
    final count = appState.transactions.length;
    appState.setNetworkAvailable(false);
    await host(tester, const WithdrawScreen());
    await tap(tester, 'Rút tiền');
    expect(find.text('Mất kết nối mạng. Vui lòng thử lại.'), findsOneWidget);
    expect(appState.balance, before);
    expect(appState.transactions.length, count);
    await close(tester);
  });

  testWidgets('Support explains mandatory OTP and mock payment behavior',
      (tester) async {
    await host(tester, const SupportScreen());
    await tap(tester, 'Khách chưa cung cấp mã xác nhận?');
    expect(find.textContaining('Chỉ bắt đầu sửa khi đã xác nhận đúng mã.'),
        findsOneWidget);
    await tap(tester, 'Thanh toán');
    await tap(tester, 'Rút tiền mất bao lâu?');
    expect(find.textContaining('chưa chuyển tiền thật'), findsOneWidget);
    await close(tester);
  });

  testWidgets(
      'Notification setting changes shared preference and survives reopening Settings',
      (tester) async {
    appState.setNotifications(true);
    await host(tester, const SettingsScreen());
    await tester.tap(find.byType(RevoSwitch));
    await tester.pumpAndSettle();
    expect(appState.notificationsEnabled, isFalse);
    await close(tester);
    await host(tester, const SettingsScreen());
    expect(tester.widget<RevoSwitch>(find.byType(RevoSwitch)).value, isFalse);
    await close(tester);
  });
}
