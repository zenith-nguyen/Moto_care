import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/screens/terms_and_commitment_screen.dart';
import 'package:motocare_mechanic/screens/incoming_order_popup.dart';
import 'package:motocare_mechanic/main.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/mechanic_account_screen.dart';
import 'package:motocare_mechanic/screens/order_arrived_screen.dart';
import 'package:motocare_mechanic/screens/order_in_progress_screen.dart';
import 'package:motocare_mechanic/screens/order_received_screen.dart';
import 'package:motocare_mechanic/screens/order_chat_screen.dart';
import 'package:motocare_mechanic/screens/order_final_quote_screen.dart';
import 'package:motocare_mechanic/screens/withdraw_screen.dart';
import 'package:motocare_mechanic/screens/settings_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Montserrat')
      ..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'));
    await font.load();
  });
  Future<void> host(WidgetTester tester, Widget child,
      {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: child));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.pumpAndSettle();
    final base = find.text(label);
    if (base.evaluate().isEmpty) {
      await tester.scrollUntilVisible(base, 180,
          scrollable: find.byType(Scrollable).last);
    }
    final finder = label == 'Nhận đơn' &&
            find.byType(IncomingOrderPopup).evaluate().isEmpty
        ? base.first
        : base.last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  ActiveOrder freshOrder({bool repairing = false}) {
    final order = appState.acceptOffer(appState.nextOffer(serviceIndex: 0));
    if (repairing) {
      appState.beginNavigation(orderId: order.orderId);
      appState.markArrived(orderId: order.orderId);
      appState.startRepair(
          orderId: order.orderId, code: order.offer.verificationCode);
    }
    return order;
  }

  setUp(() {
    appState.activeOrder = null;
    appState.setTab(0);
    appState.setNetworkAvailable(true);
    appState.setGps(true);
    appState.setOnline(true);
  });

  testWidgets(
      'Welcome requires consent then opens functional bottom navigation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const RevoMechanicApp());
    await tester.pumpAndSettle();
    // The app opens straight on the terms screen (no welcome step).
    expect(find.text('Cùng Revo'), findsNothing);
    expect(find.byType(TermsEntryScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('terms-consent')));
    await tester.pumpAndSettle();
    await tap(tester, 'Đồng ý');
    expect(find.text('Dịch vụ phổ biến'), findsOneWidget);
    await tap(tester, 'Ví');
    expect(find.text('Ví của tôi'), findsOneWidget);
    await tap(tester, 'Tài khoản');
    expect(find.text('Võ Thành Đạt'), findsOneWidget);
    await tap(tester, 'Đơn hàng');
    await tap(tester, 'Đang làm');
    expect(find.text('Chưa có đơn hàng phù hợp'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Emergency offer to navigation, PIN validation, repair, quote and completion',
      (tester) async {
    final before = appState.balance;
    await host(tester, const MechanicShell());
    await tap(tester, 'Nhận đơn');
    expect(find.text('Đơn cứu hộ khẩn cấp'), findsOneWidget);
    await tap(tester, 'Nhận đơn');
    await tap(tester, 'Bắt đầu dẫn đường');
    await tap(tester, 'Tôi đã đến nơi');
    expect(find.byType(OrderArrivedScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1111');
    await tester.pump();
    await tap(tester, 'Xác nhận');
    expect(find.textContaining('Mã không chính xác'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '2847');
    await tester.pump();
    await tap(tester, 'Xác nhận');
    await tap(tester, 'Kiểm tra tình trạng xe');
    await tap(tester, 'Tiến hành xử lý sự cố');
    await tap(tester, 'Kiểm tra lại và bàn giao');
    await tap(tester, 'Chi tiết & báo giá');
    await tap(tester, 'Báo giá phát sinh');
    await tester.tap(find.byTooltip('Thêm Thay ắc quy'));
    await tester.pump();
    await tap(tester, 'Gửi báo giá');
    await tap(tester, 'Xác nhận gửi');
    expect(find.text('Đang chờ khách duyệt'), findsOneWidget);
    expect(appState.activeOrder!.repairStage, 1);
    await tap(tester, 'Khách đồng ý báo giá');
    expect(find.byType(OrderInProgressScreen), findsOneWidget);
    expect(find.text('Khách đã duyệt báo giá'), findsWidgets);
    await tap(tester, 'Tiến hành xử lý sự cố');
    await tap(tester, 'Kiểm tra lại và bàn giao');
    await tap(tester, 'Hoàn thành sửa chữa');
    expect(find.text('Hoàn thành đơn hàng!'), findsOneWidget);
    expect(appState.balance, greaterThan(before));
    expect(appState.history.first.finalPrice,
        appState.transactions.first.finalPrice);
    await tap(tester, 'Xem chi tiết');
    expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Rejected quote retains original order amount', (tester) async {
    final order = freshOrder(repairing: true);
    appState.setQuoteQuantity(orderId: order.orderId, index: 0, quantity: 1);
    appState.sendQuote(orderId: order.orderId);
    await host(tester, OrderFinalQuoteScreen(order: order));
    await tap(tester, 'Khách từ chối báo giá');
    expect(find.text('Khách từ chối báo giá'), findsOneWidget);
    expect(order.finalPrice, order.offer.price);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Withdrawal validates amount and records a simulated request',
      (tester) async {
    final before = appState.balance;
    await host(tester, const WithdrawScreen());
    await tester.enterText(find.byType(TextFormField), '10000');
    await tap(tester, 'Rút tiền');
    expect(find.text('Số tiền rút tối thiểu 50.000đ'), findsOneWidget);
    await tester.enterText(
        find.byType(TextFormField), '${appState.balance + 1}');
    await tap(tester, 'Rút tiền');
    expect(find.text('Số tiền vượt quá số dư khả dụng'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '200000');
    await tap(tester, 'Rút tiền');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Đã gửi yêu cầu rút tiền'), findsOneWidget);
    expect(appState.balance, before - 200000);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Chat sends a message and receives a sample response',
      (tester) async {
    final chatOrder = freshOrder();
    final messages = chatOrder.messages;
    await host(
        tester,
        OrderChatScreen(
            orderId: chatOrder.orderId,
            customerName: 'Thùy An',
            customerPhone: '0905551298',
            messages: messages));
    await tester.enterText(find.byType(TextField), 'Mình đã đến nơi.');
    await tester.tap(find.byTooltip('Gửi'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(messages.any((m) => m.text == 'Mình đã đến nơi.'), isTrue);
    expect(find.text('Dạ em cảm ơn anh nhiều nha.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    testWidgets('Main tabs and account forms fit ${size.width.toInt()}px',
        (tester) async {
      await host(tester, const MechanicShell(), size: size);
      for (var tab = 0; tab < 4; tab++) {
        appState.setTab(tab);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tap(tester, 'Thông tin cá nhân');
      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Route panel scrolls without overflow on a compact phone',
      (tester) async {
    final order = freshOrder();
    await host(tester, OrderReceivedScreen(order: order),
        size: const Size(320, 568));
    expect(tester.takeException(), isNull);
    expect(
        tester
            .getRect(find.widgetWithText(PrimaryButton, 'Bắt đầu dẫn đường'))
            .top,
        greaterThan(284));
    expect(tester.getRect(find.byTooltip('Quay lại')).top,
        greaterThanOrEqualTo(0));
    await tap(tester, 'Bắt đầu dẫn đường');
    expect(find.text('Tôi đã đến nơi'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Repair start time survives opening and closing quote details',
      (tester) async {
    final active = freshOrder(repairing: true);
    final started = DateTime.now().subtract(const Duration(minutes: 15));
    active.repairStartedAt = started;
    await host(tester, OrderInProgressScreen(order: active));
    await tap(tester, 'Chi tiết & báo giá');
    await tap(tester, 'Báo giá phát sinh');
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(active.repairStartedAt, started);
    expect(find.textContaining('00:15:'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Settings renders and GPS switch updates online status',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const SettingsScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Định vị'));
    await tester.pumpAndSettle();
    final gps = find.widgetWithText(SwitchListTile, 'Định vị');
    await tester.tap(gps);
    await tester.pump(const Duration(milliseconds: 300));
    expect(appState.gpsEnabled, isFalse);
    expect(appState.isOnline, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
