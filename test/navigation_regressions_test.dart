import 'package:flutter/material.dart';
import 'package:motocare_mechanic/screens/nearby_jobs_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/demo_controls_screen.dart';
import 'package:motocare_mechanic/screens/incoming_order_popup.dart';
import 'package:motocare_mechanic/screens/mechanic_account_screen.dart';
import 'package:motocare_mechanic/screens/notifications_screen.dart';
import 'package:motocare_mechanic/screens/order_final_quote_screen.dart';
import 'package:motocare_mechanic/screens/order_history_detail_screen.dart';
import 'package:motocare_mechanic/screens/order_chat_screen.dart';
import 'package:motocare_mechanic/screens/order_in_progress_screen.dart';
import 'package:motocare_mechanic/screens/order_received_screen.dart';
import 'package:motocare_mechanic/screens/wallet_transaction_detail_screen.dart';
import 'package:motocare_mechanic/screens/mechanic_wallet_screen.dart';
import 'package:motocare_mechanic/screens/withdraw_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/home_components.dart';
import 'package:motocare_mechanic/widgets/ui.dart';

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

  ActiveOrder active({bool repairing = false}) {
    final order = appState.acceptOffer(appState.nextOffer(serviceIndex: 0));
    if (repairing) {
      appState.beginNavigation(orderId: order.orderId);
      appState.markArrived(orderId: order.orderId);
      appState.startRepair(
          orderId: order.orderId, code: order.offer.verificationCode);
    }
    return order;
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('Dashboard has one online switch and a direct emergency entry',
      (tester) async {
    await host(tester, const MechanicShell());
    expect(find.byKey(const ValueKey('home-online-toggle')), findsOneWidget);
    await tap(tester, 'Nhận đơn');
    expect(find.byType(IncomingOrderPopup), findsOneWidget);
    await tap(tester, 'Từ chối');
    expect(appState.activeOrder, isNull);
    await unmount(tester);
  });

  testWidgets('Selected service produces corresponding emergency offer',
      (tester) async {
    await host(tester, const MechanicShell());
    // Flood is no longer a Home card; select it through the existing filter.
    await tester.tap(find.byTooltip('Bộ lọc đơn gần bạn'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ngập nước'));
    await tap(tester, 'Áp dụng bộ lọc');
    expect(find.text('Chưa có đơn phù hợp.'), findsWidgets);
    await tap(tester, 'Nhận đơn');
    expect(
        tester
            .widget<IncomingOrderPopup>(find.byType(IncomingOrderPopup))
            .offer
            .issue,
        'Ngập nước');
    expect(
        tester
            .widget<IncomingOrderPopup>(find.byType(IncomingOrderPopup))
            .offer
            .price,
        350000);
    await tap(tester, 'Từ chối');
    await unmount(tester);
  });

  testWidgets(
      'Navigation checkpoint survives Back, tabs and reopening same order',
      (tester) async {
    final order = active();
    await host(tester, const MechanicShell());
    await tap(tester, 'Tiếp tục');
    await tap(tester, 'Bắt đầu dẫn đường');
    final started = order.navigationStartedAt;
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    await tap(tester, 'Tài khoản');
    await tap(tester, 'Đơn hàng');
    await tester.tap(find.byKey(ValueKey(order.orderId)));
    await tester.pumpAndSettle();
    expect(find.text('Tôi đã đến nơi'), findsOneWidget);
    expect(appState.activeOrder, same(order));
    expect(order.navigationStartedAt, started);
    await unmount(tester);
  });

  testWidgets('Quote quantities survive Back and opening the quote again',
      (tester) async {
    final order = active(repairing: true);
    await host(
        tester,
        Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                OrderFinalQuoteScreen(order: order))),
                    child: const Text('Mở báo giá')))));
    await tap(tester, 'Mở báo giá');
    await tester.tap(find.byTooltip('Thêm Thay ắc quy'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    await tap(tester, 'Mở báo giá');
    expect(find.text('Thay ắc quy × 1'), findsOneWidget);
    expect(order.draftExtra, 450000);
    await tap(tester, 'Gửi báo giá');
    await tap(tester, 'Xác nhận gửi');
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Đang chờ khách duyệt'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
      'Sending chat then leaving early still delivers and replies on reopening',
      (tester) async {
    final order = active();
    await host(
        tester,
        Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => openOrderChat(context, order),
                    child: const Text('Mở chat')))));
    await tap(tester, 'Mở chat');
    await tester.enterText(find.byType(TextField), 'Mình đã đến.');
    await tester.tap(find.byTooltip('Gửi'));
    await tester.pump();
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tap(tester, 'Mở chat');
    expect(order.messages.firstWhere((m) => m.text == 'Mình đã đến.').status,
        MessageStatus.sent);
    expect(find.text('Dạ em cảm ơn anh nhiều nha.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
      'Flow A without extras reaches completion, orders, detail and wallet',
      (tester) async {
    final before = appState.balance;
    await host(tester, const MechanicShell());
    await tester
        .ensureVisible(find.byKey(const ValueKey('home-service-battery')));
    await tester.tap(find.byKey(const ValueKey('home-service-battery')));
    await tester.pumpAndSettle();
    expect(find.byType(NearbyJobsScreen), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(NearbyJobsScreen),
        matching: find.byType(NearbyRequestCard)));
    await tester.pumpAndSettle();
    await tap(tester, 'Nhận đơn');
    final order = appState.activeOrder!;
    await tap(tester, 'Bắt đầu dẫn đường');
    await tap(tester, 'Tôi đã đến nơi');
    await tester.enterText(
        find.byType(TextField), order.offer.verificationCode);
    await tap(tester, 'Xác nhận');
    for (final step in [
      'Kiểm tra tình trạng xe',
      'Tiến hành xử lý sự cố',
      'Kiểm tra lại và bàn giao'
    ]) {
      await tap(tester, step);
    }
    await tap(tester, 'Hoàn thành sửa chữa');
    await tap(tester, 'Về trang chủ');
    await tap(tester, 'Đơn hàng');
    await tester.tap(find.byKey(ValueKey(order.orderId)));
    await tester.pumpAndSettle();
    expect(find.byType(OrderHistoryDetailScreen), findsOneWidget);
    await tap(tester, 'Xem trong ví');
    expect(find.text('Ví của tôi'), findsOneWidget);
    final item = appState.history.first;
    expect(item.orderId, order.orderId);
    expect(appState.transactions.first.orderCode, order.orderId);
    expect(appState.balance, before + item.earning);
    await unmount(tester);
  });

  for (final accepted in [true, false]) {
    testWidgets(
        'Flow B quote ${accepted ? 'accepted' : 'rejected'} keeps order and amount through completion',
        (tester) async {
      final order = active(repairing: true);
      final before = appState.balance;
      await host(tester, OrderInProgressScreen(order: order));
      await tap(tester, 'Báo giá phát sinh');
      await tester.tap(find.byTooltip('Thêm Thay ắc quy'));
      await tester.pumpAndSettle();
      await tap(tester, 'Gửi báo giá');
      await tap(tester, 'Xác nhận gửi');
      await tap(tester, 'Quay lại đơn hàng');
      final button = tester.widget<PrimaryButton>(
          find.widgetWithText(PrimaryButton, 'Hoàn thành sửa chữa'));
      expect(button.onPressed, isNull);
      await tap(tester, 'Xem báo giá đang chờ duyệt');
      await tap(
          tester, accepted ? 'Khách đồng ý báo giá' : 'Khách từ chối báo giá');
      if (!accepted) {
        await tap(tester, 'Bỏ phát sinh bị từ chối');
        await tap(tester, 'Tiếp tục theo giá đã xác nhận');
      }
      for (final step in [
        'Kiểm tra tình trạng xe',
        'Tiến hành xử lý sự cố',
        'Kiểm tra lại và bàn giao'
      ]) {
        await tap(tester, step);
      }
      await tap(tester, 'Hoàn thành sửa chữa');
      expect(appState.history.first.finalPrice,
          order.offer.price + (accepted ? 450000 : 0));
      expect(appState.history.first.orderId, order.orderId);
      expect(appState.balance, before + appState.history.first.earning);
      await unmount(tester);
    });
  }

  testWidgets('Restored skill picker registers a pending skill in Documents',
      (tester) async {
    appState.setTab(3);
    await host(tester, const MechanicShell());
    await tap(tester, 'Giấy tờ & chứng chỉ');
    expect(find.byType(DocumentsScreen), findsOneWidget);
    await tap(tester, '+ Đăng ký kỹ năng mới');
    await tap(tester, 'Thay nhớt');
    expect(appState.profile.skills.last.name, 'Thay nhớt');
    expect(appState.profile.skills.last.status, VerificationStatus.pending);
    await unmount(tester);
  });

  testWidgets(
      'Chat contact dialog and sample attachment stay on the same order',
      (tester) async {
    final order = active();
    await host(
        tester,
        OrderChatScreen(
            orderId: order.orderId,
            customerName: order.offer.customerName,
            customerPhone: order.offer.customerPhone,
            messages: order.messages));
    await tester.tap(find.byTooltip('Gọi khách'));
    await tester.pumpAndSettle();
    expect(find.textContaining(order.offer.customerPhone), findsOneWidget);
    expect(find.textContaining('Cuộc gọi mô phỏng'), findsOneWidget);
    await tap(tester, 'Đóng');
    await tester.tap(find.byTooltip('Gửi ảnh mẫu'));
    await tester.pumpAndSettle();
    await tap(tester, 'Gửi ảnh mẫu sự cố');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(order.messages.where((message) => message.isImage), hasLength(1));
    expect(order.messages.firstWhere((message) => message.isImage).status,
        MessageStatus.sent);
    expect(find.byType(PhotoPlaceholder), findsOneWidget);
    expect(appState.activeOrder, same(order));
    await unmount(tester);
  });

  testWidgets('Demo network switch renders offline state and can reconnect',
      (tester) async {
    await host(tester, const DemoControlsScreen());
    // First switch is the network one; the showcase switch follows it.
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(appState.networkAvailable, isFalse);
    await host(tester, const MechanicShell());
    expect(find.text('Mất kết nối mạng'), findsOneWidget);
    await tap(tester, 'Mất kết nối mạng');
    expect(appState.networkAvailable, isTrue);
    await unmount(tester);
  });

  testWidgets(
      'Notification opens its completed order rather than only a dialog',
      (tester) async {
    final order = active(repairing: true);
    for (var i = 0; i < 3; i++) {
      appState.advanceRepair(orderId: order.orderId);
    }
    final item = appState.completeOrder(orderId: order.orderId);
    await host(tester, const NotificationsScreen());
    await tester.tap(find.text('Hoàn thành đơn hàng').first);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<OrderHistoryDetailScreen>(
                find.byType(OrderHistoryDetailScreen))
            .item,
        same(item));
    await unmount(tester);
  });

  for (final success in [true, false]) {
    testWidgets(
        'Wallet transaction UI can settle demo ${success ? 'success' : 'failure'} and update balance',
        (tester) async {
      final before = appState.balance;
      final tx = appState.requestWithdraw(200000,
          requestId: 'ui-${DateTime.now().microsecondsSinceEpoch}')!;
      await host(tester, WalletTransactionDetailScreen(tx: tx));
      await tester.tap(find.byTooltip('Mô phỏng giao dịch'));
      await tester.pumpAndSettle();
      await tap(tester,
          success ? 'Demo · Thành công' : 'Demo · Thất bại và hoàn tiền');
      expect(tx.withdrawStatus,
          success ? WithdrawStatus.approved : WithdrawStatus.failed);
      expect(appState.balance, before - (success ? 200000 : 0));
      expect(
          find.text(
              success ? 'Giao dịch thành công' : 'Thất bại · Đã hoàn tiền'),
          findsOneWidget);
      await unmount(tester);
    });
  }

  testWidgets('Emergency timeout cannot create an active order',
      (tester) async {
    await host(
        tester, IncomingOrderPopup(offer: appState.nextOffer(serviceIndex: 0)));
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.text('Đơn đã hết hạn'), findsWidgets);
    expect(find.text('Nhận đơn'), findsNothing);
    expect(appState.activeOrder, isNull);
    await unmount(tester);
  });

  testWidgets(
      'Leaving withdrawal during loading keeps one pending request in wallet',
      (tester) async {
    final before = appState.balance;
    appState.setTab(2);
    await host(tester, const MechanicShell());
    await tap(tester, 'Rút tiền');
    await tap(tester, '200.000');
    await tester.tap(find.text('Rút tiền').last);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Đang xử lý…'), findsOneWidget);
    final tx = appState.transactions.first;
    expect(tx.withdrawStatus, WithdrawStatus.pending);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(appState.balance, before - 200000);
    expect(appState.transactions.where((t) => t.txnId == tx.txnId).length, 1);
    // The wallet tab is back (its title may be scrolled out of the lazy list).
    expect(find.byType(MechanicWalletScreen), findsOneWidget);
    expect(find.byType(WithdrawScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets(
      'Historical failed message is read-only and never retries a closed order',
      (tester) async {
    await host(
        tester,
        OrderChatScreen(
            orderId: '#closed',
            customerName: 'Thùy An',
            customerPhone: '0905551298',
            readOnly: true,
            messages: [
              ChatMessage(
                  fromMechanic: true,
                  time: DateTime.now(),
                  text: 'Tin không gửi được',
                  status: MessageStatus.failed)
            ]));
    expect(find.text('Gửi thất bại'), findsOneWidget);
    await tester.tap(find.text('Tin không gửi được'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNothing);
    await unmount(tester);
  });

  testWidgets(
      'Pending approval permits inspection but locks dependent repair and handover',
      (tester) async {
    final order = active(repairing: true);
    appState.setQuoteQuantity(orderId: order.orderId, index: 0, quantity: 1);
    appState.sendQuote(orderId: order.orderId);
    await host(tester, OrderInProgressScreen(order: order));
    await tester.tap(find.text('Kiểm tra tình trạng xe'));
    await tester.pumpAndSettle();
    expect(order.repairStage, 1);
    await tester.tap(find.text('Tiến hành xử lý sự cố'));
    await tester.pumpAndSettle();
    expect(order.repairStage, 1);
    expect(find.byKey(const ValueKey('completion-blocked-reason')),
        findsOneWidget);
    expect(
        tester
            .widget<PrimaryButton>(
                find.widgetWithText(PrimaryButton, 'Hoàn thành sửa chữa'))
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
