import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/state/app_state.dart';

void main() {
  late AppState state;
  setUp(() => state = AppState());
  tearDown(() => state.dispose());

  ActiveOrder repair() {
    final order = state.acceptOffer(MockData.offers.first);
    state.beginNavigation(orderId: order.orderId);
    state.markArrived(orderId: order.orderId);
    state.startRepair(
        orderId: order.orderId, code: order.offer.verificationCode);
    state.advanceRepair(orderId: order.orderId);
    state.advanceRepair(orderId: order.orderId);
    state.advanceRepair(orderId: order.orderId);
    return order;
  }

  test('Accepted quote credits the approved net amount exactly once', () {
    final before = state.balance;
    final order = repair();
    state.setQuoteQuantity(orderId: order.orderId, index: 0, quantity: 1);
    state.sendQuote(orderId: order.orderId);
    expect(() => state.completeOrder(orderId: order.orderId), throwsStateError);
    state.resolveQuote(true, orderId: order.orderId);
    while (order.repairStage < 3) {
      state.advanceRepair(orderId: order.orderId);
    }
    final item = state.completeOrder(orderId: order.orderId);
    expect(item.finalPrice, 600000);
    expect(
        item.fee,
        orderFee(
            baseFee: order.offer.platformFee,
            basePrice: order.offer.price,
            price: 600000));
    expect(state.balance, before + item.earning);
    expect(state.transactions.first.amount, item.earning);
    expect(state.history.first, same(item));
    expect(state.activeOrder, isNull);
    expect(state.completeOrder(orderId: order.orderId), same(item));
    expect(state.balance, before + item.earning);
    expect(state.weekIncome, state.dailyIncome.reduce((a, b) => a + b));
  });

  test('Rejected and cancelled quotes retain the original price', () {
    final order = repair();
    state.setQuoteQuantity(orderId: order.orderId, index: 0, quantity: 1);
    state.sendQuote(orderId: order.orderId);
    state.resolveQuote(false, orderId: order.orderId);
    expect(order.quoteStatus, QuoteStatus.rejected);
    expect(order.finalPrice, order.offer.price);
    state.cancelQuote(orderId: order.orderId);
    expect(order.quoteStatus, QuoteStatus.none);
    expect(order.proposedPrice, isNull);
    expect(() => state.completeOrder(orderId: order.orderId), throwsStateError);
    state.continueWithoutRejectedQuote(orderId: order.orderId);
    while (order.repairStage < 3) {
      state.advanceRepair(orderId: order.orderId);
    }
    final item = state.completeOrder(orderId: order.orderId);
    expect(item.extra, 0);
    expect(item.extraReason, isNull);
  });

  test(
      'Withdrawals enforce limits and update balance, transaction and notifications',
      () {
    final before = state.balance;
    final count = state.transactions.length;
    expect(state.requestWithdraw(49999, requestId: "low"), isNull);
    expect(state.requestWithdraw(before + 1, requestId: "high"), isNull);
    expect(state.transactions.length, count);
    expect(state.balance, before);
    expect(state.requestWithdraw(200000, requestId: "valid"), isNotNull);
    expect(state.balance, before - 200000);
    expect(state.transactions.first.type, TxType.debit);
    expect(state.transactions.first.withdrawStatus, WithdrawStatus.pending);
    expect(state.notifications.first.orderRelated, isFalse);
  });

  test('GPS setting prevents online mode until re-enabled', () {
    state.setGps(false);
    expect(state.isOnline, isFalse);
    state.setOnline(true);
    expect(state.isOnline, isFalse);
    state.setGps(true);
    state.setOnline(true);
    expect(state.isOnline, isTrue);
  });

  test('Service preferences and read state remain consistent', () {
    state.saveServices([true, false, true, false, true, false, false]);
    expect(state.services[1].enabled, isFalse);
    final unreadBefore = state.unreadCount;
    state.markNotificationRead(state.notifications.firstWhere((n) => !n.read));
    expect(state.unreadCount, unreadBefore - 1);
    state.markAllRead();
    expect(state.unreadCount, 0);
  });
}
