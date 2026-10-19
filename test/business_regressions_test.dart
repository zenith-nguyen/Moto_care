import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/state/app_state.dart';

void main() {
  late AppState state;
  setUp(() => state = AppState());
  tearDown(() => state.dispose());
  ActiveOrder accept() => state.acceptOffer(state.nextOffer(serviceIndex: 0));
  ActiveOrder repair() {
    final order = accept();
    state.beginNavigation(orderId: order.orderId);
    state.markArrived(orderId: order.orderId);
    expect(
        state.startRepair(
            orderId: order.orderId, code: order.offer.verificationCode),
        isTrue);
    return order;
  }

  void finishChecks(ActiveOrder order) {
    while (order.repairStage < 3) {
      state.advanceRepair(orderId: order.orderId);
    }
  }

  void quote(ActiveOrder order) {
    state.setQuoteQuantity(orderId: order.orderId, index: 0, quantity: 1);
    state.sendQuote(orderId: order.orderId);
  }

  test('Every mandatory checkpoint is enforced by state, including OTP', () {
    final order = accept();
    final id = order.orderId;
    expect(() => state.markArrived(orderId: id), throwsStateError);
    expect(
        () => state.startRepair(orderId: id, code: '2847'), throwsStateError);
    expect(() => state.advanceRepair(orderId: id), throwsStateError);
    expect(() => state.completeOrder(orderId: id), throwsStateError);
    state.beginNavigation(orderId: id);
    expect(order.step, OrderStep.navigating);
    state.markArrived(orderId: id);
    expect(state.startRepair(orderId: id, code: '1111'), isFalse);
    expect(order.otpVerifiedAt, isNull);
    expect(() => state.completeOrder(orderId: id), throwsStateError);
    expect(state.startRepair(orderId: id, code: '2847'), isTrue);
    expect(order.repairStage, 0);
    finishChecks(order);
    final before = state.balance;
    final item = state.completeOrder(orderId: id);
    expect(state.balance, before + item.earning);
    expect(
        item.timeline.map((e) => e.label),
        containsAll(
            ['Bắt đầu dẫn đường', 'Đã đến nơi', 'Xác nhận mã và bắt đầu sửa']));
  });

  test(
      'A different offer cannot overwrite an active order; retry same accept is safe',
      () {
    final order = accept();
    expect(state.acceptOffer(order.offer), same(order));
    expect(() => state.acceptOffer(MockData.offers.last), throwsStateError);
    expect(state.activeOrder, same(order));
    expect(() => state.nextOffer(), throwsStateError);
  });

  test('Mismatched order ID cannot advance or complete another order', () {
    final order = repair();
    expect(() => state.advanceRepair(orderId: '#wrong'), throwsStateError);
    expect(() => state.completeOrder(orderId: '#wrong'), throwsStateError);
    expect(order.repairStage, 0);
    expect(state.activeOrder, same(order));
  });

  test('Completion is idempotent and replay acceptance cannot add credit', () {
    final order = repair();
    finishChecks(order);
    final initial = state.balance;
    final count = state.transactions.length;
    final item = state.completeOrder(orderId: order.orderId);
    expect(state.completeOrder(orderId: order.orderId), same(item));
    expect(state.balance, initial + item.earning);
    expect(state.transactions.length, count + 1);
    expect(() => state.acceptOffer(order.offer), throwsStateError);
    final next = accept();
    expect(state.completeOrder(orderId: order.orderId), same(item));
    expect(state.activeOrder, same(next));
    expect(next.step, OrderStep.received);
  });

  test(
      'Offline and GPS permissions block new offers without dropping active data',
      () {
    state.setNetworkAvailable(false);
    expect(() => state.acceptOffer(MockData.offers.first), throwsStateError);
    expect(() => state.nextOffer(), throwsStateError);
    state.setNetworkAvailable(true);
    state.setGps(false);
    state.setOnline(true);
    expect(state.isOnline, isFalse);
    state.setGps(true);
    state.setOnline(true);
    final order = repair();
    state.setNetworkAvailable(false);
    expect(state.activeOrder, same(order));
    expect(order.otpVerifiedAt, isNotNull);
  });

  test('Expired offers are rejected by state independently of popup timer', () {
    final base = MockData.offers.first;
    final expired = OrderOffer(
        code: '#expired',
        issue: base.issue,
        description: base.description,
        vehicle: base.vehicle,
        plate: base.plate,
        customerName: base.customerName,
        customerPhone: base.customerPhone,
        address: base.address,
        distanceKm: 1,
        etaMinutes: 2,
        price: base.price,
        platformFee: 0,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)));
    expect(() => state.acceptOffer(expired), throwsStateError);
    expect(state.activeOrder, isNull);
  });

  test('Quote draft is attached to order and rejects invalid quantities', () {
    final order = repair();
    state.setQuoteQuantity(orderId: order.orderId, index: 0, quantity: 2);
    expect(order.draftExtra, 900000);
    expect(
        () => state.setQuoteQuantity(
            orderId: order.orderId, index: 0, quantity: -1),
        throwsArgumentError);
    expect(
        () => state.setQuoteQuantity(
            orderId: order.orderId, index: 0, quantity: 10),
        throwsArgumentError);
    expect(
        () => state.setQuoteQuantity(
            orderId: order.orderId, index: 3, quantity: 1),
        throwsArgumentError);
    expect(order.quoteDraft.first.quantity, 2);
  });

  testWidgets('Quote remains pending beyond former automatic approval deadline',
      (tester) async {
    final order = repair();
    quote(order);
    await tester.pump(const Duration(seconds: 30));
    expect(order.quoteStatus, QuoteStatus.pending);
    expect(order.finalPrice, order.offer.price);
    state.advanceRepair(orderId: order.orderId); // Inspection is independent.
    expect(() => state.advanceRepair(orderId: order.orderId), throwsStateError);
    expect(() => state.completeOrder(orderId: order.orderId), throwsStateError);
  });

  for (final accepted in [true, false]) {
    test(
        'Quote ${accepted ? 'accepted' : 'rejected'} resumes same repair and correct ledger',
        () {
      final order = repair();
      quote(order);
      state.resolveQuote(accepted, orderId: order.orderId);
      expect(order.step, OrderStep.repairing);
      expect(order.finalPrice, order.offer.price + (accepted ? 450000 : 0));
      if (!accepted) {
        state.continueWithoutRejectedQuote(orderId: order.orderId);
      }
      finishChecks(order);
      final before = state.balance;
      final result = state.completeOrder(orderId: order.orderId);
      expect(result.orderId, order.orderId);
      expect(result.finalPrice, order.finalPrice);
      expect(state.transactions.first.orderCode, result.orderId);
      expect(state.transactions.first.amount, result.earning);
      expect(state.balance, before + result.earning);
      expect(result.extraItems.length, accepted ? 1 : 0);
      expect(state.notifications.first.orderId, result.orderId);
    });
  }

  test('Pending quote cannot be cancelled to bypass customer approval', () {
    final order = repair();
    quote(order);
    final sent = order.submittedQuote;
    expect(() => state.cancelQuote(orderId: order.orderId), throwsStateError);
    expect(order.quoteStatus, QuoteStatus.pending);
    expect(order.step, OrderStep.quoting);
    expect(order.submittedQuote, same(sent));
    state.advanceRepair(orderId: order.orderId); // Inspection is independent.
    expect(() => state.advanceRepair(orderId: order.orderId), throwsStateError);
    state.resolveQuote(false, orderId: order.orderId);
    state.cancelQuote(orderId: order.orderId);
    expect(order.quoteStatus, QuoteStatus.none);
    expect(order.draftExtra, 450000);
  });

  test('Rejected replacement quote preserves earlier approved charges', () {
    final order = repair();
    quote(order);
    state.resolveQuote(true, orderId: order.orderId);
    state.cancelQuote(orderId: order.orderId);
    state.setQuoteQuantity(orderId: order.orderId, index: 0, quantity: 2);
    state.sendQuote(orderId: order.orderId);
    state.resolveQuote(false, orderId: order.orderId);
    expect(order.finalPrice, order.offer.price + 450000);
    expect(order.approvedQuote.first.quantity, 1);
  });

  test(
      'A selected enabled service determines offer; disabled service is rejected',
      () {
    expect(state.nextOffer(serviceIndex: 1).issue, 'Xẹp lốp');
    state.saveServices([true, false, true, true, true, false, false]);
    expect(() => state.nextOffer(serviceIndex: 1), throwsStateError);
    expect(
        () => state
            .saveServices([false, false, false, false, false, false, false]),
        throwsArgumentError);
  });

  test('Withdrawal validates and reserves money once for the same request ID',
      () {
    final before = state.balance;
    final count = state.transactions.length;
    expect(state.requestWithdraw(49999, requestId: 'low'), isNull);
    expect(state.requestWithdraw(before + 1, requestId: 'high'), isNull);
    final tx = state.requestWithdraw(200000, requestId: 'same')!;
    expect(state.requestWithdraw(200000, requestId: 'same'), same(tx));
    expect(state.requestWithdraw(300000, requestId: 'same'), isNull);
    expect(state.balance, before - 200000);
    expect(state.transactions.length, count + 1);
    expect(state.notifications.first.transactionId, tx.txnId);
  });

  for (final approved in [true, false]) {
    test(
        'Withdrawal ${approved ? 'success' : 'failure'} settles/refunds exactly once',
        () {
      final before = state.balance;
      final withdrawn = state.weekWithdrawn;
      final tx = state.requestWithdraw(200000, requestId: 'settle')!;
      expect(tx.withdrawStatus, WithdrawStatus.pending);
      expect(state.resolveWithdraw(tx.txnId, approved: approved), isTrue);
      expect(state.resolveWithdraw(tx.txnId, approved: !approved), isFalse);
      expect(state.balance, before - (approved ? 200000 : 0));
      expect(state.weekWithdrawn, withdrawn + (approved ? 200000 : 0));
      expect(tx.withdrawStatus,
          approved ? WithdrawStatus.approved : WithdrawStatus.failed);
      expect(tx.balanceEffect, approved ? -200000 : 0);
      expect(tx.resolvedAt, isNotNull);
    });
  }

  testWidgets('Chat delivery and reply continue without a mounted chat screen',
      (tester) async {
    final order = accept();
    final message = state.sendChat(order.orderId, text: 'Mình đang tới.');
    expect(message.status, MessageStatus.sending);
    await tester.pump(const Duration(milliseconds: 800));
    expect(message.status, MessageStatus.sent);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(order.messages.last.text, 'Dạ em cảm ơn anh nhiều nha.');
  });

  testWidgets(
      'Failed chat can retry after reconnection without duplicating text',
      (tester) async {
    final order = accept();
    state.setNetworkAvailable(false);
    final message = state.sendChat(order.orderId, text: 'Mình tới rồi.');
    expect(message.status, MessageStatus.failed);
    state.setNetworkAvailable(true);
    state.retryChat(order.orderId, message);
    await tester.pump(const Duration(milliseconds: 800));
    expect(message.status, MessageStatus.sent);
    expect(order.messages.where((m) => m.text == 'Mình tới rồi.').length, 1);
    await tester.pump(const Duration(milliseconds: 1500));
  });

  test(
      'Skill registration preserves admin verification and prevents duplicates',
      () {
    expect(state.registerSkill('Thay nhớt'), isTrue);
    expect(state.profile.skills.last.status, VerificationStatus.pending);
    expect(state.registerSkill('Thay nhớt'), isFalse);
    expect(state.registerSkill(' '), isFalse);
  });
}
