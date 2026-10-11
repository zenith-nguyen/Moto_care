import '../../../core/money/money_amount.dart';
import '../../../core/network/json_reader.dart';
import '../../orders/domain/order_status.dart';

class AdminPeriod {
  const AdminPeriod({
    required this.from,
    required this.to,
    required this.timezone,
  });

  final DateTime from;
  final DateTime to;
  final String timezone;

  factory AdminPeriod.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final from = reader.dateTime('from');
    final to = reader.dateTime('to');
    if (!from.isBefore(to)) {
      throw const FormatException('Invalid Admin reporting period.');
    }
    return AdminPeriod(from: from, to: to, timezone: reader.string('timezone'));
  }
}

class AdminUserMetrics {
  const AdminUserMetrics({
    required this.total,
    required this.customers,
    required this.providers,
    required this.admins,
    required this.createdInPeriod,
  });

  final int total;
  final int customers;
  final int providers;
  final int admins;
  final int createdInPeriod;

  factory AdminUserMetrics.fromJson(Map<String, dynamic> json) {
    return AdminUserMetrics(
      total: _count(json, 'total'),
      customers: _count(json, 'customers'),
      providers: _count(json, 'providers'),
      admins: _count(json, 'admins'),
      createdInPeriod: _count(json, 'createdInPeriod'),
    );
  }
}

class AdminProviderMetrics {
  const AdminProviderMetrics({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.online,
    required this.freshLocation,
  });

  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int online;
  final int freshLocation;

  factory AdminProviderMetrics.fromJson(Map<String, dynamic> json) {
    return AdminProviderMetrics(
      total: _count(json, 'total'),
      pending: _count(json, 'pending'),
      approved: _count(json, 'approved'),
      rejected: _count(json, 'rejected'),
      online: _count(json, 'online'),
      freshLocation: _count(json, 'freshLocation'),
    );
  }
}

class AdminOrderMetrics {
  const AdminOrderMetrics({
    required this.total,
    required this.byStatus,
    required this.completionRate,
  });

  final int total;
  final Map<OrderStatus, int> byStatus;
  final double completionRate;

  factory AdminOrderMetrics.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final rawStatus = reader.object('byStatus');
    final byStatus = <OrderStatus, int>{};
    for (final status in OrderStatus.values) {
      byStatus[status] = _count(rawStatus, status.wireValue);
    }
    final completionRate = reader.number('completionRate');
    if (completionRate < 0 || completionRate > 100) {
      throw const FormatException('Invalid completion rate.');
    }
    return AdminOrderMetrics(
      total: _count(json, 'total'),
      byStatus: Map.unmodifiable(byStatus),
      completionRate: completionRate,
    );
  }
}

class AdminMoneyMetrics {
  const AdminMoneyMetrics({
    required this.collectedInPeriod,
    required this.heldCurrent,
    required this.settledToProvidersInPeriod,
    required this.refundPendingCurrent,
    required this.refundedInPeriod,
    required this.grossCompletedValueInPeriod,
    required this.providerWalletBalanceCurrent,
    required this.providerWalletLockedCurrent,
    required this.providerWalletAvailableCurrent,
    required this.pendingWithdrawalAmountCurrent,
    required this.providerWithdrawnInPeriod,
  });

  final MoneyAmount collectedInPeriod;
  final MoneyAmount heldCurrent;
  final MoneyAmount settledToProvidersInPeriod;
  final MoneyAmount refundPendingCurrent;
  final MoneyAmount refundedInPeriod;
  final MoneyAmount grossCompletedValueInPeriod;
  final MoneyAmount providerWalletBalanceCurrent;
  final MoneyAmount providerWalletLockedCurrent;
  final MoneyAmount providerWalletAvailableCurrent;
  final MoneyAmount pendingWithdrawalAmountCurrent;
  final MoneyAmount providerWithdrawnInPeriod;

  factory AdminMoneyMetrics.fromJson(Map<String, dynamic> json) {
    MoneyAmount money(String key) => MoneyAmount.parse(json[key]);
    return AdminMoneyMetrics(
      collectedInPeriod: money('collectedInPeriod'),
      heldCurrent: money('heldCurrent'),
      settledToProvidersInPeriod: money('settledToProvidersInPeriod'),
      refundPendingCurrent: money('refundPendingCurrent'),
      refundedInPeriod: money('refundedInPeriod'),
      grossCompletedValueInPeriod: money('grossCompletedValueInPeriod'),
      providerWalletBalanceCurrent: money('providerWalletBalanceCurrent'),
      providerWalletLockedCurrent: money('providerWalletLockedCurrent'),
      providerWalletAvailableCurrent: money('providerWalletAvailableCurrent'),
      pendingWithdrawalAmountCurrent: money('pendingWithdrawalAmountCurrent'),
      providerWithdrawnInPeriod: money('providerWithdrawnInPeriod'),
    );
  }
}

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.period,
    required this.generatedAt,
    required this.sandboxOnly,
    required this.users,
    required this.providers,
    required this.orders,
    required this.money,
  });

  final AdminPeriod period;
  final DateTime generatedAt;
  final bool sandboxOnly;
  final AdminUserMetrics users;
  final AdminProviderMetrics providers;
  final AdminOrderMetrics orders;
  final AdminMoneyMetrics money;

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return AdminDashboardSummary(
      period: AdminPeriod.fromJson(reader.object('period')),
      generatedAt: reader.dateTime('generatedAt'),
      sandboxOnly: reader.boolean('sandboxOnly'),
      users: AdminUserMetrics.fromJson(reader.object('users')),
      providers: AdminProviderMetrics.fromJson(reader.object('providers')),
      orders: AdminOrderMetrics.fromJson(reader.object('orders')),
      money: AdminMoneyMetrics.fromJson(reader.object('money')),
    );
  }
}

class AdminTimeseriesPoint {
  const AdminTimeseriesPoint({
    required this.day,
    required this.ordersCreated,
    required this.ordersCompleted,
    required this.collected,
    required this.settledToProviders,
    required this.refunded,
    required this.providerWithdrawn,
  });

  final String day;
  final int ordersCreated;
  final int ordersCompleted;
  final MoneyAmount collected;
  final MoneyAmount settledToProviders;
  final MoneyAmount refunded;
  final MoneyAmount providerWithdrawn;

  factory AdminTimeseriesPoint.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final day = reader.string('day');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) {
      throw const FormatException('Invalid Admin timeseries day.');
    }
    return AdminTimeseriesPoint(
      day: day,
      ordersCreated: _count(json, 'ordersCreated'),
      ordersCompleted: _count(json, 'ordersCompleted'),
      collected: MoneyAmount.parse(reader.value('collected')),
      settledToProviders: MoneyAmount.parse(reader.value('settledToProviders')),
      refunded: MoneyAmount.parse(reader.value('refunded')),
      providerWithdrawn: MoneyAmount.parse(reader.value('providerWithdrawn')),
    );
  }
}

class AdminTimeseries {
  const AdminTimeseries({
    required this.period,
    required this.bucket,
    required this.sandboxOnly,
    required this.data,
  });

  final AdminPeriod period;
  final String bucket;
  final bool sandboxOnly;
  final List<AdminTimeseriesPoint> data;

  factory AdminTimeseries.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final bucket = reader.string('bucket');
    if (bucket != 'day') throw const FormatException('Unsupported bucket.');
    return AdminTimeseries(
      period: AdminPeriod.fromJson(reader.object('period')),
      bucket: bucket,
      sandboxOnly: reader.boolean('sandboxOnly'),
      data: reader
          .list('data')
          .map(_object)
          .map(AdminTimeseriesPoint.fromJson)
          .toList(growable: false),
    );
  }
}

enum ReconciliationFlag {
  completedMissingPaidPayment('COMPLETED_MISSING_PAID_PAYMENT'),
  paymentFinalPriceMismatch('PAYMENT_FINAL_PRICE_MISMATCH'),
  completedWalletCreditMismatch('COMPLETED_WALLET_CREDIT_MISMATCH'),
  refundStatusMismatch('REFUND_STATUS_MISMATCH'),
  refundedWithWalletCredit('REFUNDED_WITH_WALLET_CREDIT'),
  multiplePayments('MULTIPLE_PAYMENTS'),
  adjustmentStatusMismatch('ADJUSTMENT_STATUS_MISMATCH');

  const ReconciliationFlag(this.wireValue);
  final String wireValue;

  static ReconciliationFlag fromWire(Object? raw) {
    return values.firstWhere(
      (flag) => flag.wireValue == raw,
      orElse: () => throw FormatException('Unknown reconciliation flag: $raw'),
    );
  }
}

class AdminPartySummary {
  const AdminPartySummary({required this.id, required this.name});
  final int id;
  final String name;

  factory AdminPartySummary.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return AdminPartySummary(
      id: reader.positiveInt('id'),
      name: reader.string('name'),
    );
  }
}

class ReconciliationOrder {
  const ReconciliationOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.createdAt,
    required this.finalPrice,
    required this.customer,
    required this.provider,
  });
  final int id;
  final String code;
  final OrderStatus status;
  final DateTime createdAt;
  final MoneyAmount? finalPrice;
  final AdminPartySummary customer;
  final AdminPartySummary? provider;

  factory ReconciliationOrder.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final provider = reader.nullableObject('provider');
    return ReconciliationOrder(
      id: reader.positiveInt('id'),
      code: reader.string('code'),
      status: OrderStatus.fromWire(reader.value('status')),
      createdAt: reader.dateTime('createdAt'),
      finalPrice: _nullableMoney(reader.value('finalPrice')),
      customer: AdminPartySummary.fromJson(reader.object('customer')),
      provider: provider == null ? null : AdminPartySummary.fromJson(provider),
    );
  }
}

class ReconciliationPayment {
  const ReconciliationPayment({
    required this.id,
    required this.status,
    required this.amount,
    required this.paidAt,
    required this.refundedAt,
    required this.isDemo,
    required this.paymentCount,
  });
  final int id;
  final PaymentStatus status;
  final MoneyAmount amount;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final bool isDemo;
  final int paymentCount;

  factory ReconciliationPayment.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return ReconciliationPayment(
      id: reader.positiveInt('id'),
      status: PaymentStatus.fromWire(reader.value('status')),
      amount: MoneyAmount.parse(reader.value('amount')),
      paidAt: reader.nullableDateTime('paidAt'),
      refundedAt: reader.nullableDateTime('refundedAt'),
      isDemo: reader.boolean('isDemo'),
      paymentCount: _count(json, 'paymentCount'),
    );
  }
}

class ReconciliationAdjustment {
  const ReconciliationAdjustment({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.isDemo,
    required this.settledAt,
  });
  final int id;
  final PaymentAdjustmentType type;
  final PaymentAdjustmentStatus status;
  final MoneyAmount amount;
  final bool isDemo;
  final DateTime? settledAt;

  factory ReconciliationAdjustment.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return ReconciliationAdjustment(
      id: reader.positiveInt('id'),
      type: PaymentAdjustmentType.fromWire(reader.value('type')),
      status: PaymentAdjustmentStatus.fromWire(reader.value('status')),
      amount: MoneyAmount.parse(reader.value('amount')),
      isDemo: reader.boolean('isDemo'),
      settledAt: reader.nullableDateTime('settledAt'),
    );
  }
}

class ReconciliationSettlement {
  const ReconciliationSettlement({
    required this.creditCount,
    required this.creditedAmount,
    required this.adjustment,
  });
  final int creditCount;
  final MoneyAmount creditedAmount;
  final ReconciliationAdjustment? adjustment;

  factory ReconciliationSettlement.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final adjustment = reader.nullableObject('adjustment');
    return ReconciliationSettlement(
      creditCount: _count(json, 'creditCount'),
      creditedAmount: MoneyAmount.parse(reader.value('creditedAmount')),
      adjustment: adjustment == null
          ? null
          : ReconciliationAdjustment.fromJson(adjustment),
    );
  }
}

class ReconciliationItem {
  const ReconciliationItem({
    required this.order,
    required this.payment,
    required this.settlement,
    required this.flags,
  });
  final ReconciliationOrder order;
  final ReconciliationPayment? payment;
  final ReconciliationSettlement settlement;
  final List<ReconciliationFlag> flags;

  factory ReconciliationItem.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final payment = reader.nullableObject('payment');
    return ReconciliationItem(
      order: ReconciliationOrder.fromJson(reader.object('order')),
      payment: payment == null ? null : ReconciliationPayment.fromJson(payment),
      settlement: ReconciliationSettlement.fromJson(
        reader.object('settlement'),
      ),
      flags: reader
          .list('flags')
          .map(ReconciliationFlag.fromWire)
          .toList(growable: false),
    );
  }
}

class AdminReconciliationPage {
  const AdminReconciliationPage({
    required this.period,
    required this.sandboxOnly,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.items,
  });
  final AdminPeriod period;
  final bool sandboxOnly;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<ReconciliationItem> items;

  factory AdminReconciliationPage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return AdminReconciliationPage(
      period: AdminPeriod.fromJson(reader.object('period')),
      sandboxOnly: reader.boolean('sandboxOnly'),
      page: reader.positiveInt('page'),
      limit: reader.positiveInt('limit'),
      total: _count(json, 'total'),
      totalPages: _count(json, 'totalPages'),
      items: reader
          .list('items')
          .map(_object)
          .map(ReconciliationItem.fromJson)
          .toList(growable: false),
    );
  }
}

int _count(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int || value < 0) {
    throw FormatException('Invalid non-negative count: $key');
  }
  return value;
}

MoneyAmount? _nullableMoney(Object? raw) {
  return raw == null ? null : MoneyAmount.parse(raw);
}

Map<String, dynamic> _object(Object? raw) {
  if (raw is! Map) throw const FormatException('Expected object item.');
  return Map<String, dynamic>.from(raw);
}
