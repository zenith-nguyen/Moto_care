import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/demo_notifications.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/incoming_order_popup.dart';
import 'package:motocare_mechanic/screens/mechanic_account_screen.dart';
import 'package:motocare_mechanic/screens/notifications_screen.dart';
import 'package:motocare_mechanic/screens/order_chat_screen.dart';
import 'package:motocare_mechanic/screens/order_final_quote_screen.dart';
import 'package:motocare_mechanic/screens/order_history_detail_screen.dart';
import 'package:motocare_mechanic/screens/wallet_transaction_detail_screen.dart';
import 'package:motocare_mechanic/services/notification_feed.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/notification_glyph.dart';

RevoNotification notice(RevoNotificationType type,
        {String? orderId,
        String? transactionId,
        DateTime? time,
        bool read = false,
        OrderOffer? offer}) =>
    RevoNotification('Sự kiện ${type.name}', 'Nội dung thông báo ${type.name}',
        orderRelated: true,
        type: type,
        orderId: orderId,
        transactionId: transactionId,
        time: time,
        isRead: read,
        offer: offer);
ActiveOrder repairing(AppState state) {
  final o = state.acceptOffer(state.nextOffer(serviceIndex: 0));
  state.beginNavigation(orderId: o.orderId);
  state.markArrived(orderId: o.orderId);
  state.startRepair(orderId: o.orderId, code: o.offer.verificationCode);
  return o;
}

void main() {
  late AppState state;
  setUp(() => state = AppState(demoEnabled: true));
  tearDown(() => state.dispose());

  test(
      'Demo fixtures have IDs, typed targets and verified domain references; no invented approvals',
      () {
    expect(state.notifications.map((n) => n.id).toSet().length,
        state.notifications.length);
    expect(state.notifications.every((n) => n.demo && n.targetRoute.isNotEmpty),
        isTrue);
    expect(
        state.notifications
            .where((n) => n.type == RevoNotificationType.quoteApproved),
        isEmpty);
    for (final n in state.notifications) {
      if (n.type == RevoNotificationType.income ||
          n.type == RevoNotificationType.withdrawal) {
        expect(
            state.transactions.any((t) => t.txnId == n.transactionId), isTrue);
      }
      if (n.type == RevoNotificationType.message ||
          n.type == RevoNotificationType.review) {
        expect(state.history.any((o) => o.code == n.orderId), isTrue);
      }
    }
    expect(state.notifications.any((n) => n.body.startsWith('Chứng chỉ nghề')),
        isFalse); // It is pending in the source profile.
    final production = AppState(demoEnabled: false);
    expect(production.notifications, isEmpty);
    production.dispose();
  });

  test(
      'All seven filters distinguish status, orders, messages, payments and system',
      () {
    final source = [
      for (final type in RevoNotificationType.values)
        notice(type, read: type.index.isEven)
    ];
    List<RevoNotification> filtered(NotificationFilter f) =>
        source.where((n) => matchesNotification(n, f)).toList();
    expect(filtered(NotificationFilter.all).length, 10);
    expect(filtered(NotificationFilter.read).every((n) => n.read), isTrue);
    expect(filtered(NotificationFilter.unread).every((n) => !n.read), isTrue);
    expect(filtered(NotificationFilter.messages).single.type,
        RevoNotificationType.message);
    expect(filtered(NotificationFilter.payments).map((n) => n.type),
        [RevoNotificationType.income, RevoNotificationType.withdrawal]);
    expect(filtered(NotificationFilter.system).map((n) => n.type),
        [RevoNotificationType.certificate, RevoNotificationType.system]);
    expect(filtered(NotificationFilter.orders).length, 5);
  });

  test(
      'Calendar grouping is sorted and handles yesterday, this week, last week and older',
      () {
    final now = DateTime(2026, 10, 16, 12);
    final dates = [
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 9),
      DateTime(2026, 10, 14),
      DateTime(2026, 10, 15),
      DateTime(2026, 10, 16, 10)
    ];
    final groups = groupNotifications([
      for (final date in dates) notice(RevoNotificationType.system, time: date)
    ], now);
    expect(groups.map((g) => g.label),
        ['Mới', 'Hôm qua', 'Tuần này', 'Tuần trước', 'Trước đó']);
    final monday = DateTime(2026, 10, 12, 0, 1);
    expect(
        groupNotifications([
          notice(RevoNotificationType.system,
              time: DateTime(2026, 10, 11, 23, 59))
        ], monday)
            .single
            .label,
        'Hôm qua');
  });

  test(
      'Relative timestamps come from actual time, including midnight and future data',
      () {
    final now = DateTime(2026, 10, 16, 12);
    expect(notificationTime(now.subtract(const Duration(seconds: 30)), now),
        'Vừa xong');
    expect(notificationTime(now.subtract(const Duration(minutes: 8)), now),
        '8 phút trước');
    expect(notificationTime(DateTime(2026, 10, 15, 16, 20), now),
        'Hôm qua · 16:20');
    expect(
        notificationTime(DateTime(2026, 10, 9, 14, 10), now), 'Thứ 6 · 14:10');
    expect(notificationTime(now.add(const Duration(minutes: 2)), now),
        '16/10 · 12:02');
  });

  test(
      'Read and mark-all only change notification flags, preserve IDs and business data',
      () {
    final n = state.notifications.first;
    final id = n.id, balance = state.balance, history = state.history.length;
    state.markNotificationRead(n);
    state.markNotificationRead(n);
    expect(n.id, id);
    expect(n.read, isTrue);
    state.markAllRead();
    expect(state.unreadCount, 0);
    expect(state.balance, balance);
    expect(state.history.length, history);
  });

  test(
      'Emergency resolver rejects expiry, missing data, disabled service and a different active order',
      () {
    final n = state.notifications
        .firstWhere((n) => n.type == RevoNotificationType.emergency);
    expect(resolveNotification(n, state, DateTime.now()).action,
        NotificationAction.request);
    expect(resolveNotification(n, state, n.offer!.expiresAt!).reason,
        contains('hết hạn'));
    expect(
        resolveNotification(
                notice(RevoNotificationType.emergency), state, DateTime.now())
            .action,
        NotificationAction.unavailable);
    state.services[0].enabled = false;
    expect(resolveNotification(n, state, DateTime.now()).reason,
        contains('đang tắt'));
    state.services[0].enabled = true;
    state.acceptOffer(state.nextOffer(serviceIndex: 0));
    expect(resolveNotification(n, state, DateTime.now()).reason,
        contains('đơn khác'));
  });

  test(
      'Completed emergency resolves read-only detail; cannot accept its order again',
      () {
    final item = state.history.first;
    final n = notice(RevoNotificationType.emergency, orderId: item.code);
    expect(resolveNotification(n, state, DateTime.now()).order, same(item));
    expect(resolveNotification(n, state, DateTime.now()).action,
        NotificationAction.history);
  });

  test(
      'Chat resolves exact active or historical messages and never falls back to another customer',
      () {
    final active = repairing(state), historical = state.history.first;
    expect(
        resolveNotification(
                notice(RevoNotificationType.message, orderId: active.orderId),
                state,
                DateTime.now())
            .active,
        same(active));
    expect(
        resolveNotification(
                notice(RevoNotificationType.message, orderId: historical.code),
                state,
                DateTime.now())
            .order,
        same(historical));
    expect(
        resolveNotification(
                notice(RevoNotificationType.message, orderId: '#MISSING'),
                state,
                DateTime.now())
            .action,
        NotificationAction.unavailable);
  });

  test(
      'Quote notifications are created only on recorded response; resolving a link changes no quote state',
      () {
    final o = repairing(state);
    state.setQuoteQuantity(orderId: o.orderId, index: 0, quantity: 1);
    state.sendQuote(orderId: o.orderId);
    expect(
        state.notifications
            .where((n) => n.type == RevoNotificationType.quoteApproved),
        isEmpty);
    final snapshot = List.of(o.quoteTimeline);
    final result = resolveNotification(
        notice(RevoNotificationType.quoteApproved, orderId: o.orderId),
        state,
        DateTime.now());
    expect(result.action, NotificationAction.quote);
    expect(o.quoteStatus, QuoteStatus.pending);
    expect(o.quoteTimeline, snapshot);
    state.resolveQuote(true, orderId: o.orderId);
    expect(state.notifications.first.type, RevoNotificationType.quoteApproved);
    expect(state.notifications.first.body, contains(o.offer.vehicle));
    final count = state.notifications.length;
    state.resolveQuote(true, orderId: o.orderId);
    expect(state.notifications.length, count);
  });

  test(
      'Income event follows an actual single ledger credit; repeated complete/read never credit again',
      () {
    final o = repairing(state);
    while (o.repairStage < 3) {
      state.advanceRepair(orderId: o.orderId);
    }
    final balance = state.balance;
    final item = state.completeOrder(orderId: o.orderId);
    final events = state.notifications
        .where((n) =>
            n.type == RevoNotificationType.income && n.orderId == item.code)
        .toList();
    expect(events.length, 1);
    final n = events.single;
    final d = resolveNotification(n, state, DateTime.now());
    expect(d.transaction!.amount, item.earning);
    state.markNotificationRead(n);
    resolveNotification(n, state, DateTime.now());
    state.completeOrder(orderId: o.orderId);
    expect(state.balance, balance + item.earning);
    expect(
        state.notifications
            .where((n) =>
                n.type == RevoNotificationType.income && n.orderId == item.code)
            .length,
        1);
    expect(
        state.transactions
            .where((t) => t.isCredit && t.orderCode == item.code)
            .length,
        1);
  });

  test(
      'Wallet link validates transaction and order IDs; missing data cannot credit money',
      () {
    final tx = state.transactions.firstWhere((t) => t.isCredit),
        balance = state.balance;
    expect(
        resolveNotification(
                notice(RevoNotificationType.income,
                    transactionId: tx.txnId, orderId: tx.orderCode),
                state,
                DateTime.now())
            .transaction,
        same(tx));
    for (final n in [
      notice(RevoNotificationType.income,
          transactionId: tx.txnId, orderId: '#WRONG'),
      notice(RevoNotificationType.income, transactionId: 'missing')
    ]) {
      expect(resolveNotification(n, state, DateTime.now()).action,
          NotificationAction.unavailable);
    }
    expect(state.balance, balance);
  });

  test(
      'Withdrawal pending and resolution events stay in payments with the same transaction ID',
      () {
    final tx = state.requestWithdraw(200000, requestId: 'notifications-test')!;
    expect(state.notifications.first.type, RevoNotificationType.withdrawal);
    state.resolveWithdraw(tx.txnId, approved: false);
    expect(state.notifications.first.type, RevoNotificationType.withdrawal);
    expect(state.notifications.first.transactionId, tx.txnId);
    expect(
        resolveNotification(state.notifications.first, state, DateTime.now())
            .transaction,
        same(tx));
  });

  testWidgets(
      'Delivered customer reply publishes a correctly linked message event',
      (tester) async {
    final o = repairing(state);
    state.sendChat(o.orderId, text: 'Tôi sắp tới.');
    await tester.pump(const Duration(seconds: 3));
    final n = state.notifications
        .firstWhere((n) => n.type == RevoNotificationType.message);
    expect(n.orderId, o.orderId);
    expect(n.detail, o.messages.last.text);
    expect(resolveNotification(n, state, DateTime.now()).active, same(o));
  });

  Future<void> host(WidgetTester tester,
      {List<RevoNotification>? items,
      Size size = const Size(390, 844),
      double scale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appState.activeOrder = null;
    appState.setTab(0);
    appState.profile = MockData.profile();
    appState.history
      ..clear()
      ..addAll(MockData.history());
    appState.transactions
      ..clear()
      ..addAll(MockData.transactions());
    appState.notifications
      ..clear()
      ..addAll(items ??
          demoNotifications(
              profile: appState.profile,
              history: appState.history,
              transactions: appState.transactions,
              now: DateTime.now()));
    await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        home: const NotificationsScreen(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!)));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());
  Future<void> openNotice(WidgetTester tester, RevoNotification n) async {
    final f = find.byKey(ValueKey('notification-${n.id}'));
    if (f.evaluate().isEmpty) {
      final list = find.byKey(const ValueKey('notification-list'));
      await tester.drag(list, const Offset(0, 4000));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(f, 160,
          scrollable: find
              .descendant(of: list, matching: find.byType(Scrollable))
              .first);
    }
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Reference header, all three time groups, Montserrat and exact blue icons/unread dots',
      (tester) async {
    await host(tester);
    expect(find.byTooltip('Lọc thông báo'), findsOneWidget);
    expect(find.text('Mới'), findsOneWidget);
    for (final label in ['Hôm qua', 'Tuần trước']) {
      await tester.scrollUntilVisible(find.text(label), 150,
          scrollable: find
              .descendant(
                  of: find.byKey(const ValueKey('notification-list')),
                  matching: find.byType(Scrollable))
              .first);
      expect(find.text(label), findsOneWidget);
    }
    await tester.drag(
        find.byKey(const ValueKey('notification-list')), const Offset(0, 4000));
    await tester.pumpAndSettle();
    expect(find.byType(AppBottomNav), findsOneWidget);
    for (final n in appState.notifications) {
      await tester.scrollUntilVisible(
          find.byKey(ValueKey('notification-${n.id}')), 140,
          scrollable: find
              .descendant(
                  of: find.byKey(const ValueKey('notification-list')),
                  matching: find.byType(Scrollable))
              .first);
      final icon = tester.widget<NotificationGlyph>(
          find.byKey(ValueKey('notification-icon-${n.id}')));
      expect(icon.color, const Color(0xFF317CBB));
      final title = tester.widget<Text>(find.text(n.title));
      expect(title.style!.fontFamily, 'Montserrat');
      if (!n.read) {
        expect(
            (tester
                    .widget<Container>(
                        find.byKey(ValueKey('notification-unread-${n.id}')))
                    .decoration as BoxDecoration)
                .color,
            const Color(0xFF317CBB));
      }
    }
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets(
      'Filter and mark-all work through menu and can recover from unread empty state',
      (tester) async {
    await host(tester);
    await tester.tap(find.byTooltip('Lọc thông báo'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('notification-filter-messages')));
    await tester.pumpAndSettle();
    expect(find.text('Khách hàng gửi tin nhắn'), findsOneWidget);
    expect(find.text('Đơn cứu hộ khẩn mới'), findsNothing);
    await tester.tap(find.byTooltip('Lọc thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notification-mark-all')));
    await tester.pumpAndSettle();
    expect(appState.unreadCount, 0);
    await tester.tap(find.byTooltip('Lọc thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notification-filter-unread')));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có thông báo'), findsOneWidget);
    await tester.tap(find.text('Xem tất cả thông báo'));
    await tester.pumpAndSettle();
    expect(find.text('Đơn cứu hộ khẩn mới'), findsOneWidget);
    await close(tester);
  });

  testWidgets(
      'Chat card opens the existing read-only chat for the referenced order',
      (tester) async {
    await host(tester);
    final n = appState.notifications
        .firstWhere((n) => n.type == RevoNotificationType.message);
    final order = appState.history.firstWhere((o) => o.code == n.orderId);
    await openNotice(tester, n);
    final chat = tester.widget<OrderChatScreen>(find.byType(OrderChatScreen));
    expect(chat.orderId, order.code);
    expect(chat.messages, same(order.messages));
    expect(chat.readOnly, isTrue);
    expect(n.read, isTrue);
    expect(appState.tabIndex, 0);
    await close(tester);
  });

  testWidgets(
      'Income card opens exact transaction; reading has no balance effect',
      (tester) async {
    await host(tester);
    final n = appState.notifications
            .firstWhere((n) => n.type == RevoNotificationType.income),
        balance = appState.balance;
    await openNotice(tester, n);
    expect(
        tester
            .widget<WalletTransactionDetailScreen>(
                find.byType(WalletTransactionDetailScreen))
            .tx
            .txnId,
        n.transactionId);
    expect(appState.balance, balance);
    await close(tester);
  });

  testWidgets(
      'Certificate and review cards navigate to existing documents and same order detail',
      (tester) async {
    await host(tester);
    final n = appState.notifications
        .firstWhere((n) => n.type == RevoNotificationType.certificate);
    await openNotice(tester, n);
    expect(find.byType(DocumentsScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại').first);
    await tester.pumpAndSettle();
    final review = appState.notifications
        .firstWhere((n) => n.type == RevoNotificationType.review);
    await openNotice(tester, review);
    expect(
        tester
            .widget<OrderHistoryDetailScreen>(
                find.byType(OrderHistoryDetailScreen))
            .item
            .code,
        review.orderId);
    await close(tester);
  });

  testWidgets(
      'Stale quote notification opens actual pending state without approving it',
      (tester) async {
    await host(tester, items: []);
    final o = repairing(appState);
    appState.setQuoteQuantity(orderId: o.orderId, index: 0, quantity: 1);
    appState.sendQuote(orderId: o.orderId);
    final n = notice(RevoNotificationType.quoteApproved, orderId: o.orderId);
    appState.notifications.add(n);
    appState.setTab(0);
    await tester.pumpAndSettle();
    await openNotice(tester, n);
    expect(find.byType(OrderFinalQuoteScreen), findsOneWidget);
    expect(o.quoteStatus, QuoteStatus.pending);
    expect(o.completionBlockedReason, isNotNull);
    await close(tester);
    appState.activeOrder = null;
  });

  testWidgets('Expired/missing links show a clear state without popup or crash',
      (tester) async {
    final n = notice(RevoNotificationType.emergency);
    await host(tester, items: [n]);
    await openNotice(tester, n);
    expect(find.text('Thông báo không còn khả dụng'), findsOneWidget);
    expect(find.byType(IncomingOrderPopup), findsNothing);
    expect(appState.activeOrder, isNull);
    await close(tester);
  });

  testWidgets(
      'Home bell badge refreshes and read flags survive closing/reopening the route',
      (tester) async {
    await host(tester, items: [notice(RevoNotificationType.system)]);
    await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const MechanicShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thông báo'));
    await tester.pumpAndSettle();
    await openNotice(tester, appState.notifications.single);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(appState.unreadCount, 0);
    await tester.tap(find.byTooltip('Quay lại').first);
    await tester.pumpAndSettle();
    final badge = find.descendant(
        of: find.byTooltip('Thông báo'), matching: find.byType(Badge));
    expect(tester.widget<Badge>(badge).isLabelVisible, isFalse);
    await tester.tap(find.byTooltip('Thông báo'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(ValueKey(
            'notification-unread-${appState.notifications.single.id}')),
        findsNothing);
    expect(appState.tabIndex, 0);
    await close(tester);
  });

  for (final config in [
    (const Size(320, 568), 1.6),
    (const Size(412, 915), 1.0)
  ]) {
    testWidgets(
        'Long notification cards, menu and full list fit ${config.$1} text ${config.$2}',
        (tester) async {
      final long = notice(RevoNotificationType.system);
      final source = [
        ...state.notifications,
        RevoNotification(
            'Thông báo có nội dung dài cần xuống dòng đầy đủ khi phóng to chữ',
            'Chi tiết sự cố, thông tin đơn và địa chỉ được hiển thị đầy đủ mà không bị cắt. ' *
                4,
            orderRelated: false,
            detail: 'Nội dung phụ cũng cần đọc được khi dùng thiết bị nhỏ.',
            id: long.id)
      ];
      await host(tester, items: source, size: config.$1, scale: config.$2);
      for (var i = 0; i < 7; i++) {
        expect(tester.takeException(), isNull);
        await tester.drag(find.byKey(const ValueKey('notification-list')),
            const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Lọc thông báo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  }
}
