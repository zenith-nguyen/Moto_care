import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/order_final_quote_screen.dart';
import 'package:motocare_mechanic/screens/order_in_progress_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/ui.dart';

ActiveOrder repair(AppState state) {
  final order = state.acceptOffer(state.nextOffer(serviceIndex: 0));
  state.beginNavigation(orderId: order.orderId);
  state.markArrived(orderId: order.orderId);
  state.startRepair(orderId: order.orderId, code: order.offer.verificationCode);
  return order;
}

void finish(AppState state, ActiveOrder order) {
  while (order.repairStage < 3) {
    state.advanceRepair(orderId: order.orderId);
  }
}

void send(AppState state, ActiveOrder order, {int quantity = 1}) {
  state.setQuoteQuantity(orderId: order.orderId, index: 0, quantity: quantity);
  state.sendQuote(orderId: order.orderId);
}

Future<void> tap(WidgetTester tester, String label) async {
  final target = find.text(label);
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(find.text(label), 180,
        scrollable: find.byType(Scrollable).last);
  }
  await tester.ensureVisible(find.text(label).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  group('Quote state regression', () {
    late AppState state;
    setUp(() => state = AppState(demoEnabled: true));
    tearDown(() => state.dispose());

    test('A: no extras requires OTP and all work before a single wallet credit',
        () {
      final o = state.acceptOffer(state.nextOffer(serviceIndex: 0));
      expect(o.completionBlockedReason, contains('OTP'));
      expect(o.canAdvanceRepair, isFalse);
      expect(() => state.completeOrder(orderId: o.orderId), throwsStateError);
      state.beginNavigation(orderId: o.orderId);
      state.markArrived(orderId: o.orderId);
      state.startRepair(orderId: o.orderId, code: o.offer.verificationCode);
      expect(o.completionBlockedReason, contains('3 bước'));
      finish(state, o);
      expect(o.completionBlockedReason, isNull);
      final before = state.balance;
      final item = state.completeOrder(orderId: o.orderId);
      expect(state.completeOrder(orderId: o.orderId), same(item));
      expect(o.completionBlockedReason, contains('đã hoàn thành'));
      expect(state.balance, before + item.earning);
    });

    test(
        'B/F: late quote invalidates old repair/handover; approval never checks work',
        () {
      final o = repair(state);
      final started = o.repairStartedAt;
      finish(state, o);
      send(state, o);
      expect(o.repairStage, 1);
      expect(o.completionBlockedReason, contains('Chờ khách duyệt'));
      expect(o.canAdvanceRepair, isFalse);
      expect(() => state.completeOrder(orderId: o.orderId), throwsStateError);
      expect(() => state.advanceRepair(orderId: o.orderId), throwsStateError);
      final submitted = o.submittedQuote;
      state.resolveQuote(true, orderId: o.orderId);
      state.resolveQuote(false,
          orderId: o.orderId); // Duplicate response ignored.
      expect(o.quoteStatus, QuoteStatus.accepted);
      expect(o.repairStage, 1);
      expect(o.repairStartedAt, started);
      expect(o.submittedQuote, same(submitted));
      expect(o.finalPrice, o.offer.price + 450000);
      expect(() => state.completeOrder(orderId: o.orderId), throwsStateError);
      finish(state, o);
      final before = state.balance;
      final item = state.completeOrder(orderId: o.orderId);
      expect(state.completeOrder(orderId: o.orderId), same(item));
      expect(state.balance, before + item.earning);
      expect(state.transactions.where((t) => t.orderCode == o.orderId),
          hasLength(1));
      expect(item.extraItems.single.quantity, 1);
      expect(item.timeline.where((e) => e.label == 'Khách đã đồng ý báo giá'),
          hasLength(1));
    });

    test(
        'C: reject, edit, resend, accept preserves timeline and only final charges',
        () {
      final o = repair(state);
      send(state, o);
      state.advanceRepair(orderId: o.orderId); // Inspection while waiting.
      state.resolveQuote(false, orderId: o.orderId);
      expect(o.rejectedQuoteNeedsAction, isTrue);
      expect(o.finalPrice, o.offer.price);
      expect(() => state.advanceRepair(orderId: o.orderId), throwsStateError);
      state.cancelQuote(orderId: o.orderId);
      expect(o.draftExtra, 450000);
      expect(o.rejectedQuoteNeedsAction, isTrue);
      expect(() => state.completeOrder(orderId: o.orderId), throwsStateError);
      send(state, o, quantity: 2);
      expect(() => state.continueWithoutRejectedQuote(orderId: o.orderId),
          throwsStateError);
      state.resolveQuote(true, orderId: o.orderId);
      expect(o.rejectedQuoteNeedsAction, isFalse);
      finish(state, o);
      final item = state.completeOrder(orderId: o.orderId);
      expect(item.finalPrice, o.offer.price + 900000);
      expect(item.extraItems.single.quantity, 2);
      expect(item.timeline.where((e) => e.label.startsWith('Gửi báo giá:')),
          hasLength(2));
      expect(
          item.timeline.map((e) => e.label),
          containsAllInOrder([
            'Khách từ chối báo giá',
            'Khách đã đồng ý báo giá',
            'Hoàn thành'
          ]));
    });

    test('Rejected replacement keeps previous approval after explicit omission',
        () {
      final o = repair(state);
      send(state, o);
      state.resolveQuote(true, orderId: o.orderId);
      state.cancelQuote(orderId: o.orderId);
      send(state, o, quantity: 2);
      state.resolveQuote(false, orderId: o.orderId);
      state.continueWithoutRejectedQuote(orderId: o.orderId);
      expect(o.repairStage, 0);
      expect(o.finalPrice, o.offer.price + 450000);
      finish(state, o);
      final item = state.completeOrder(orderId: o.orderId);
      expect(item.extraItems.single.quantity, 1);
      expect(
          item.timeline.map((e) => e.label),
          contains(
              'Tiếp tục theo chi phí đã xác nhận; bỏ hạng mục bị từ chối'));
    });

    test('Production cannot fabricate a customer response through demo state',
        () {
      final production = AppState(demoEnabled: false);
      expect(() => production.resolveQuote(true, orderId: '#RVO3281'),
          throwsStateError);
      expect(() => production.resolveQuote(false, orderId: '#RVO3281'),
          throwsStateError);
      production.dispose();
    });
  });

  group('Quote screen regression', () {
    setUp(() {
      appState.activeOrder = null;
      appState.setNetworkAvailable(true);
      appState.setGps(true);
      appState.setOnline(true);
      appState.setTab(0);
    });

    Future<void> host(WidgetTester t, Widget page,
        {bool compact = false}) async {
      t.view.physicalSize =
          compact ? const Size(320, 568) : const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(MaterialApp(theme: buildAppTheme(), home: page));
      await t.pumpAndSettle();
    }

    testWidgets(
        'B: visible demo approval returns to same repair with remaining work',
        (t) async {
      final o = repair(appState);
      await host(t, const MechanicShell());
      await tap(t, 'Tiếp tục');
      await tap(t, 'Kiểm tra tình trạng xe');
      await tap(t, 'Báo giá phát sinh');
      await t.tap(find.byTooltip('Thêm Thay ắc quy'));
      await t.pumpAndSettle();
      await tap(t, 'Gửi báo giá');
      await tap(t, 'Xác nhận gửi');
      expect(find.text('Mô phỏng phản hồi khách hàng'), findsOneWidget);
      expect(find.text('Khách đồng ý báo giá'), findsOneWidget);
      expect(find.text('Khách từ chối báo giá'), findsOneWidget);
      await tap(t, 'Khách đồng ý báo giá');
      expect(find.byType(OrderInProgressScreen), findsOneWidget);
      expect(appState.activeOrder, same(o));
      expect(o.repairStage, 1);
      expect(
          t
              .widget<PrimaryButton>(
                  find.widgetWithText(PrimaryButton, 'Hoàn thành sửa chữa'))
              .onPressed,
          isNull);
      await tap(t, 'Tiến hành xử lý sự cố');
      await tap(t, 'Kiểm tra lại và bàn giao');
      final before = appState.balance;
      await tap(t, 'Hoàn thành sửa chữa');
      expect(find.text('Hoàn thành đơn hàng!'), findsOneWidget);
      final item = appState.history.first;
      await tap(t, 'Xem chi tiết');
      expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
      await tap(t, 'Xem trong ví');
      expect(find.text('Ví của tôi'), findsOneWidget);
      expect(appState.completeOrder(orderId: o.orderId), same(item));
      expect(appState.balance, before + item.earning);
      expect(appState.transactions.where((tx) => tx.orderCode == o.orderId),
          hasLength(1));
      await t.pumpWidget(const SizedBox());
    });

    testWidgets(
        'C: visible rejection offers edit/resend and approval without hidden menus',
        (t) async {
      final o = repair(appState);
      send(appState, o);
      await host(t, OrderFinalQuoteScreen(order: o), compact: true);
      await tap(t, 'Khách từ chối báo giá');
      expect(find.text('Khách từ chối báo giá'), findsOneWidget);
      expect(find.text('Đang chờ khách duyệt'), findsNothing);
      await tap(t, 'Chỉnh sửa và gửi lại báo giá');
      expect(o.draftExtra, 450000);
      await t.tap(find.byTooltip('Thêm Thay ắc quy'));
      await t.pumpAndSettle();
      await tap(t, 'Gửi báo giá');
      await tap(t, 'Xác nhận gửi');
      await tap(t, 'Khách đồng ý báo giá');
      expect(find.byType(OrderInProgressScreen), findsOneWidget);
      expect(o.quoteStatus, QuoteStatus.accepted);
      expect(o.finalPrice, o.offer.price + 900000);
      for (final label in [
        'Kiểm tra tình trạng xe',
        'Tiến hành xử lý sự cố',
        'Kiểm tra lại và bàn giao'
      ]) {
        await tap(t, label);
      }
      await tap(t, 'Hoàn thành sửa chữa');
      expect(appState.history.first.orderId, o.orderId);
      expect(appState.history.first.extraItems.single.quantity, 2);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets(
        'D/F: Back and tabs retain pending snapshot and block completion',
        (t) async {
      final o = repair(appState);
      send(appState, o);
      final sent = o.quoteSentAt;
      final lines = o.submittedQuote;
      await host(t, const MechanicShell());
      await tap(t, 'Tiếp tục');
      await tap(t, 'Xem báo giá đang chờ duyệt');
      await tap(t, 'Quay lại đơn hàng');
      await t.tap(find.byTooltip('Quay lại'));
      await t.pumpAndSettle();
      await tap(t, 'Tài khoản');
      await tap(t, 'Đơn hàng');
      await t.tap(find.byKey(ValueKey(o.orderId)));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('completion-blocked-reason')),
          findsOneWidget);
      expect(o.quoteStatus, QuoteStatus.pending);
      expect(o.quoteSentAt, sent);
      expect(o.submittedQuote, same(lines));
      expect(o.orderId, appState.activeOrder!.orderId);
      expect(
          t
              .widget<PrimaryButton>(
                  find.widgetWithText(PrimaryButton, 'Hoàn thành sửa chữa'))
              .onPressed,
          isNull);
      await tap(t, 'Xem báo giá đang chờ duyệt');
      await tap(t, 'Hạng mục phát sinh');
      expect(find.text('Thay ắc quy × 1'), findsOneWidget);
      expect(find.text(o.offer.customerName), findsOneWidget);
      expect(find.text('Mã đơn ${o.orderId}'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });
}
