import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/state/app_state.dart';

/// Loads the demo history and ledger with every entry re-timed to today, so
/// "this week" / "this month" tests give the same result on any weekday
/// (the stock fixtures are 1-4 days old and fall into last week on Mondays).
/// Order and amounts are unchanged; only the timestamps move.
void seedCurrentWeekFixtures() {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);

  final orders = MockData.history();
  appState.history
    ..clear()
    ..addAll([
      for (var i = 0; i < orders.length; i++)
        _retime(orders[i], day.add(Duration(seconds: orders.length - i)))
    ]);

  final txs = MockData.transactions();
  appState.transactions
    ..clear()
    ..addAll([
      for (var i = 0; i < txs.length; i++)
        _retimeTx(txs[i], day.add(Duration(seconds: txs.length - i)))
    ]);
}

OrderHistoryItem _retime(OrderHistoryItem o, DateTime time) => OrderHistoryItem(
      code: o.code,
      issue: o.issue,
      vehicle: o.vehicle,
      plate: o.plate,
      customerName: o.customerName,
      customerPhone: o.customerPhone,
      address: o.address,
      status: o.status,
      time: time,
      initialPrice: o.initialPrice,
      finalPrice: o.finalPrice,
      fee: o.fee,
      timeline: o.timeline,
      extraReason: o.extraReason,
      messages: o.messages,
      customerRating: o.customerRating,
      customerReview: o.customerReview,
      rating: o.rating,
      ratingComment: o.ratingComment,
      extraItems: o.extraItems,
    );

WalletTransaction _retimeTx(WalletTransaction t, DateTime time) =>
    WalletTransaction(
      code: t.code,
      txnId: t.txnId,
      type: t.type,
      amount: t.amount,
      time: time,
      withdrawStatus: t.withdrawStatus,
      orderCode: t.orderCode,
      serviceName: t.serviceName,
      customerName: t.customerName,
      customerPhone: t.customerPhone,
      finalPrice: t.finalPrice,
      platformFee: t.platformFee,
      resolvedAt: t.resolvedAt,
    );
