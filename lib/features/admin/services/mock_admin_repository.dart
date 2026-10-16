import '../data/admin_mock_data.dart';
import '../models/admin_models.dart';
import 'admin_repository.dart';

class MockAdminRepository implements AdminRepository {
  MockAdminRepository({
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 350),
    this.empty = false,
  }) : clock = clock ?? DateTime.now {
    final now = this.clock();
    _orders = empty ? [] : AdminMockData.orders(now).toList();
    _providers = empty ? [] : AdminMockData.providers(now);
    _disputes = empty ? [] : AdminMockData.disputes.toList();
    _withdrawals = empty ? [] : AdminMockData.withdrawals(now);
    _wallets = empty
        ? {}
        : {for (final w in AdminMockData.wallets(now)) w.providerId: w};
  }

  final DateTime Function() clock;
  final Duration latency;
  final bool empty;
  late List<AdminOrder> _orders;
  late List<AdminProviderApplication> _providers;
  late List<AdminPriceDispute> _disputes;
  late List<AdminWithdrawal> _withdrawals;
  late Map<String, AdminWallet> _wallets;

  /// Fault injection for previews/tests; consumed before any mutation.
  AdminException? nextError;
  final Map<String, AdminException> nextErrors = {};
  Future<void> _wait(String endpoint) async {
    await Future<void>.delayed(latency);
    if ((nextErrors.remove(endpoint) ?? nextError) case final error?) {
      nextError = null;
      throw error;
    }
  }

  void _validateNote(String note, {required bool required}) {
    if (required && note.trim().isEmpty) {
      throw const AdminException('Vui lòng nhập lý do / ghi chú.');
    }
    if (note.trim().length > 500) {
      throw const AdminException('Ghi chú tối đa 500 ký tự.');
    }
  }

  @override
  Future<List<AdminOrder>> orders() async {
    await _wait('/admin/orders');
    return List.unmodifiable(_orders);
  }

  @override
  Future<List<AdminProviderApplication>> pendingProviders() async {
    await _wait('/admin/providers/pending');
    return List.unmodifiable(
      _providers.where((p) => p.status == AdminReviewStatus.pending),
    );
  }

  @override
  Future<void> resolveProvider(
    String id, {
    required bool approve,
    required String note,
  }) async {
    _validateNote(note, required: !approve);
    await _wait('/admin/providers/$id/approval');
    final index = _providers.indexWhere(
      (p) => p.id == id && p.status == AdminReviewStatus.pending,
    );
    if (index < 0) {
      throw const AdminException('Hồ sơ đã được xử lý. Vui lòng tải lại.');
    }
    _providers[index] = _providers[index].resolve(approve, note.trim());
  }

  @override
  Future<List<AdminRefund>> pendingRefunds() async {
    await _wait('/admin/refunds/pending');
    return empty
        ? []
        : AdminMockData.refunds.where((r) => r.source == 'refund').toList();
  }

  @override
  Future<List<AdminRefund>> pendingAdjustmentRefunds() async {
    await _wait('/admin/payment-adjustments/pending-refunds');
    return empty
        ? []
        : AdminMockData.refunds
              .where((r) => r.source == 'payment-adjustment')
              .toList();
  }

  @override
  Future<List<AdminPriceDispute>> pendingDisputes() async {
    await _wait('/admin/price-disputes/pending');
    return List.unmodifiable(
      _disputes.where((d) => d.status == AdminReviewStatus.pending),
    );
  }

  @override
  Future<void> resolveDispute(
    String id, {
    required bool approve,
    required String note,
  }) async {
    _validateNote(note, required: true);
    await _wait('/admin/price-disputes/$id/resolve');
    final index = _disputes.indexWhere(
      (d) => d.id == id && d.status == AdminReviewStatus.pending,
    );
    if (index < 0) {
      throw const AdminException('Tranh chấp đã được xử lý. Vui lòng tải lại.');
    }
    final dispute = _disputes[index];
    final orderIndex = _orders.indexWhere((o) => o.id == dispute.orderId);
    if (orderIndex < 0) throw const AdminException('Không tìm thấy đơn hàng.');
    _disputes[index] = dispute.resolve(approve, note.trim());
    _orders[orderIndex] = _orders[orderIndex].withFinalPrice(
      approve ? dispute.proposedPrice : dispute.originalPrice,
      resolution:
          '${approve ? 'Chấp nhận' : 'Bác'} đề xuất ${dispute.id}. Ghi chú Admin: ${note.trim()}',
      resolvedAt: clock(),
    );
    // Resolving a price proposal never silently collects/refunds real money.
  }

  @override
  Future<List<AdminWithdrawal>> pendingWithdrawals() async {
    await _wait('/admin/withdrawals/pending');
    return List.unmodifiable(
      _withdrawals.where((w) => w.status == AdminReviewStatus.pending),
    );
  }

  @override
  Future<AdminWallet> wallet(String providerId) async {
    await _wait('wallet/$providerId');
    return _wallets[providerId] ??
        (throw const AdminException('Không tìm thấy ví thợ.'));
  }

  @override
  Future<void> resolveWithdrawal(
    String id, {
    required bool approve,
    required String note,
  }) async {
    _validateNote(note, required: !approve);
    await _wait('/admin/withdrawals/$id/resolve');
    final index = _withdrawals.indexWhere(
      (w) => w.id == id && w.status == AdminReviewStatus.pending,
    );
    if (index < 0) {
      throw const AdminException('Yêu cầu rút tiền đã được xử lý.');
    }
    final request = _withdrawals[index];
    final wallet = _wallets[request.providerId];
    if (wallet == null || wallet.locked < request.amount) {
      throw const AdminException('Số dư đang khóa không đủ. Cần đối chiếu ví.');
    }
    _wallets[request.providerId] = AdminWallet(
      providerId: wallet.providerId,
      available: wallet.available + (approve ? 0 : request.amount),
      locked: wallet.locked - request.amount,
      history: List.unmodifiable([
        ...wallet.history,
        AdminWalletEntry(
          'SB-${request.id}-${approve ? 'PAID' : 'RELEASE'}',
          approve
              ? 'Đã rút ${request.id}'
              : 'Mở khóa ${request.id}: ${note.trim()}',
          approve ? -request.amount : request.amount,
          clock(),
        ),
      ]),
    );
    _withdrawals[index] = request.resolve(approve, note.trim());
  }

  List<AdminMetric> _moneyMetrics(
    List<AdminOrder> orders,
    AdminDateRange? range,
  ) {
    int sum(int Function(AdminOrder) value) =>
        orders.fold(0, (sum, o) => sum + value(o));
    final withdrawals = _withdrawals.where(
      (w) => range == null || range.contains(w.createdAt),
    );
    return [
      AdminMetric('Khách chuyển', sum((o) => o.collected), isMoney: true),
      AdminMetric(
        'Revo đang giữ',
        sum((o) => o.collected - o.refunded - o.credited),
        isMoney: true,
      ),
      AdminMetric('Đã hoàn khách', sum((o) => o.refunded), isMoney: true),
      AdminMetric(
        'Đã quyết toán ví thợ',
        sum((o) => o.credited),
        isMoney: true,
      ),
      AdminMetric(
        'Đang khóa chờ rút',
        withdrawals
            .where((w) => w.status == AdminReviewStatus.pending)
            .fold(0, (sum, w) => sum + w.amount),
        isMoney: true,
      ),
      AdminMetric(
        'Đã rút',
        withdrawals
            .where((w) => w.status == AdminReviewStatus.approved)
            .fold(0, (sum, w) => sum + w.amount),
        isMoney: true,
      ),
    ];
  }

  @override
  Future<AdminDashboardSummary> dashboardSummary(AdminDateRange range) async {
    await _wait('/admin/dashboard/summary');
    final orders = _orders.where((o) => range.contains(o.createdAt)).toList();
    int count(AdminOrderStatus status) =>
        orders.where((o) => o.status == status).length;
    final finance = _moneyMetrics(orders, range);
    return AdminDashboardSummary(
      List.unmodifiable([
        AdminMetric('Tổng khách', empty ? 0 : 1248),
        AdminMetric(
          'Tổng thợ',
          empty
              ? 0
              : 86 +
                    _providers
                        .where((p) => p.status == AdminReviewStatus.approved)
                        .length,
        ),
        AdminMetric(
          'Thợ chờ duyệt',
          _providers.where((p) => p.status == AdminReviewStatus.pending).length,
        ),
        AdminMetric('Thợ online', empty ? 0 : 24),
        AdminMetric('Tổng đơn', orders.length),
        AdminMetric('Đơn tìm thợ', count(AdminOrderStatus.searching)),
        AdminMetric('Đơn đang làm', count(AdminOrderStatus.working)),
        AdminMetric('Đơn hoàn thành', count(AdminOrderStatus.completed)),
        AdminMetric('Đơn đã hủy', count(AdminOrderStatus.cancelled)),
        ...List.generate(
          6,
          (i) => AdminMetric(
            [
              'Đã thu',
              'Đang giữ / chưa quyết toán',
              'Đã hoàn',
              'Đã cộng ví thợ',
              'Đang chờ rút',
              'Đã rút',
            ][i],
            finance[i].value,
            isMoney: true,
          ),
        ),
      ]),
    );
  }

  @override
  Future<List<AdminTimeseriesPoint>> dashboardTimeseries(
    AdminDateRange range,
  ) async {
    await _wait('/admin/dashboard/timeseries');
    final points = <AdminTimeseriesPoint>[];
    for (
      var day = range.start;
      day.isBefore(range.end);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final bucket = _orders.where(
        (o) => AdminDateRange(
          day,
          DateTime(day.year, day.month, day.day + 1),
        ).contains(o.createdAt),
      );
      int sum(int Function(AdminOrder) value) =>
          bucket.fold(0, (sum, o) => sum + value(o));
      points.add(
        AdminTimeseriesPoint(
          day,
          bucket.length,
          sum((o) => o.collected),
          sum((o) => o.refunded),
          sum((o) => o.credited),
        ),
      );
    }
    return List.unmodifiable(points);
  }

  @override
  Future<List<AdminReconciliation>> reconciliation() async {
    await _wait('/admin/reconciliation');
    return List.unmodifiable(
      _orders.map((o) {
        final expected = o.finalPrice ?? o.estimatedPrice;
        final unallocated = o.collected - o.refunded - o.credited;
        final anomaly =
            unallocated < 0 ||
            (o.payment == AdminPaymentStatus.settled &&
                (unallocated != 0 || o.collected - o.refunded != expected));
        return AdminReconciliation(
          order: o,
          status: anomaly
              ? AdminMatchStatus.anomaly
              : o.status == AdminOrderStatus.cancelled && o.collected == 0
              ? AdminMatchStatus.excluded
              : o.payment == AdminPaymentStatus.settled ||
                    o.payment == AdminPaymentStatus.refunded
              ? AdminMatchStatus.matched
              : AdminMatchStatus.pending,
          reason: anomaly
              ? 'Tổng thu − hoàn − cộng ví hoặc giá cuối chưa khớp. Cần kiểm tra thanh toán.'
              : o.warning,
        );
      }),
    );
  }
}
