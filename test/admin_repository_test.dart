import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revo/features/admin/models/admin_models.dart';
import 'package:revo/features/admin/models/admin_dashboard_models.dart';
import 'package:revo/features/admin/models/admin_finance_models.dart';
import 'package:revo/features/admin/providers/admin_providers.dart';
import 'package:revo/features/admin/services/mock_admin_repository.dart';

void main() {
  final now = DateTime(2026, 10, 13, 14);
  const session = AdminSession(
    id: 'admin-1',
    name: 'Admin',
    email: 'admin@example.test',
    role: 'ADMIN',
  );
  MockAdminRepository repository() =>
      MockAdminRepository(clock: () => now, latency: Duration.zero);

  test(
    'Application decisions preserve mechanic profile and photo metadata',
    () async {
      final application = (await repository().pendingProviders()).first;
      final resolved = application.resolve(true, 'Đã kiểm tra hồ sơ');
      expect(resolved.status, AdminReviewStatus.approved);
      expect(resolved.workshopAddress, application.workshopAddress);
      expect(resolved.citizenIdMasked, application.citizenIdMasked);
      expect(resolved.workshopPhoto, same(application.workshopPhoto));
      expect(resolved.portraitPhoto, same(application.portraitPhoto));
      expect(resolved.identityFrontPhoto, application.identityFrontPhoto);
      expect(resolved.identityBackPhoto, application.identityBackPhoto);
      expect(resolved.additionalPhotos, application.additionalPhotos);
      expect(resolved.identityVerified, isFalse);
    },
  );

  test(
    'Finance snapshot derives balances and the latest recorded transaction',
    () async {
      final container = ProviderContainer(
        overrides: [
          adminSessionProvider.overrideWith(
            () => AdminSessionController(initialSession: session),
          ),
          adminClockProvider.overrideWithValue(() => now),
          adminRepositoryProvider.overrideWithValue(repository()),
        ],
      );
      addTearDown(container.dispose);
      final data = await container.read(adminFinanceProvider.future);
      expect(data.collected, 1350000);
      expect(data.held, 910000);
      expect(data.credited, 280000);
      expect(
        data.latestTransactionAt,
        now.subtract(const Duration(minutes: 24)),
      );
      expect(data.isEmpty, isFalse);
      final empty = AdminFinanceSnapshot(
        summary: const AdminDashboardSummary([]),
        invoices: [],
      );
      expect(empty.latestTransactionAt, isNull);
      expect(empty.isEmpty, isTrue);
    },
  );

  test(
    'Summary has 15 metrics; chart totals match selected order cohort',
    () async {
      final repo = repository();
      final range = AdminDateRange(
        DateTime(2026, 10, 7),
        DateTime(2026, 10, 14),
      );
      final summary = await repo.dashboardSummary(range);
      final series = await repo.dashboardTimeseries(range);
      expect(summary.metrics, hasLength(15));
      expect(series, hasLength(7));
      expect(
        series.fold<int>(0, (sum, p) => sum + p.orders),
        summary.metrics[4].value,
      );
      expect(
        series.fold<int>(0, (sum, p) => sum + p.collected),
        summary.metrics[9].value,
      );
      expect(
        summary.metrics[9].value -
            summary.metrics[11].value -
            summary.metrics[12].value,
        summary.metrics[10].value,
      );
      final today = await repo.dashboardSummary(
        AdminDateRange(DateTime(2026, 10, 13), DateTime(2026, 10, 14)),
      );
      expect(today.metrics[4].value, lessThan(summary.metrics[4].value));
      expect(today.metrics[0].value, summary.metrics[0].value);
    },
  );

  test(
    'Dashboard comparison uses the preceding calendar interval across New Year',
    () {
      final previous = AdminDashboardHighlights.previousRange(
        AdminDateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 8)),
      );
      expect(previous.start, DateTime(2025, 12, 25));
      expect(previous.end, DateTime(2026, 1, 1));
      expect(previous.contains(DateTime(2026, 1, 1)), false);
    },
  );

  test('Dashboard aggregates the selected cohort and keeps the previous cohort separate', () async {
    final container = ProviderContainer(
      overrides: [
        adminSessionProvider.overrideWith(
          () => AdminSessionController(initialSession: session),
        ),
        adminRepositoryProvider.overrideWithValue(repository()),
      ],
    );
    addTearDown(container.dispose);
    final range = AdminDateRange(DateTime(2026, 10, 7), DateTime(2026, 10, 14));
    final data = await container.read(
      adminDashboardHighlightsProvider(range).future,
    );
    expect(data.orders, data.metric('Tổng đơn'));
    expect(data.collected, data.metric('Đã thu'));
    expect(data.dailyAverage, data.collected / 7);
    expect(data.dailyOrdersAverage, data.orders / 7);
    expect(data.previousOrders, 0);
    expect(data.previousPoints.last.day, DateTime(2026, 10, 6));
    expect(data.metric('Thợ chờ duyệt'), 3);
  });

  test(
    'Reconciliation distinguishes all four states and missing settlement',
    () async {
      final rows = await repository().reconciliation();
      expect(
        rows.map((r) => r.status).toSet(),
        AdminMatchStatus.values.toSet(),
      );
      final anomaly = rows.singleWhere((r) => r.order.id == 'MC-2606');
      expect(anomaly.status, AdminMatchStatus.anomaly);
      expect(anomaly.reason, isNotEmpty);
    },
  );

  test(
    'Provider rejection requires a trimmed reason and cannot run twice',
    () async {
      final repo = repository();
      await expectLater(
        repo.resolveProvider('P-101', approve: false, note: '  '),
        throwsA(isA<AdminException>()),
      );
      expect(await repo.pendingProviders(), hasLength(3));
      await repo.resolveProvider(
        'P-101',
        approve: false,
        note: '  Thiếu thông tin xe  ',
      );
      expect(await repo.pendingProviders(), hasLength(2));
      await expectLater(
        repo.resolveProvider('P-101', approve: true, note: ''),
        throwsA(isA<AdminException>()),
      );
    },
  );

  test(
    'Dispute resolution stores note and updates price without charging',
    () async {
      final repo = repository();
      await expectLater(
        repo.resolveDispute('DP-01', approve: true, note: ''),
        throwsA(isA<AdminException>()),
      );
      await repo.resolveDispute(
        'DP-01',
        approve: true,
        note: 'Đã đối chiếu quãng đường',
      );
      final order = (await repo.orders()).singleWhere((o) => o.id == 'MC-2604');
      expect(order.finalPrice, 420000);
      expect(order.collected, 350000);
      expect(order.dispute, contains('Đã đối chiếu quãng đường'));
      expect(order.timeline.last.at, now);
      expect(await repo.pendingDisputes(), hasLength(1));
    },
  );

  test(
    'Withdrawal approval consumes only the locked balance exactly once',
    () async {
      final repo = repository();
      final before = await repo.wallet('P-01');
      await repo.resolveWithdrawal('WD-01', approve: true, note: '');
      final after = await repo.wallet('P-01');
      expect(after.available, before.available);
      expect(after.locked, before.locked - 200000);
      expect(after.balance, before.balance - 200000);
      expect(after.history.last.id, startsWith('SB-'));
      await expectLater(
        repo.resolveWithdrawal('WD-01', approve: true, note: ''),
        throwsA(isA<AdminException>()),
      );
      final range = AdminDateRange(
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 14),
      );
      final summary = await repo.dashboardSummary(range);
      expect(summary.metrics.last.value, 200000);
    },
  );

  test(
    'Rejecting withdrawal unlocks funds without changing total balance',
    () async {
      final repo = repository();
      final before = await repo.wallet('P-02');
      await expectLater(
        repo.resolveWithdrawal('WD-02', approve: false, note: ' '),
        throwsA(isA<AdminException>()),
      );
      await repo.resolveWithdrawal(
        'WD-02',
        approve: false,
        note: 'Sai thông tin nhận tiền',
      );
      final after = await repo.wallet('P-02');
      expect(after.available, before.available + 150000);
      expect(after.locked, 0);
      expect(after.balance, before.balance);
      expect(after.history.last.label, contains('Sai thông tin nhận tiền'));
    },
  );

  test('Failed submission preserves records and can be retried', () async {
    final repo = repository()..nextError = const AdminException('Lỗi kết nối');
    await expectLater(
      repo.resolveWithdrawal('WD-01', approve: true, note: ''),
      throwsA(isA<AdminException>()),
    );
    expect(await repo.pendingWithdrawals(), hasLength(2));
    expect((await repo.wallet('P-01')).locked, 200000);
    await repo.resolveWithdrawal('WD-01', approve: true, note: '');
    expect(await repo.pendingWithdrawals(), hasLength(1));
  });

  test('Missing session blocks reads and actions', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await expectLater(
      container.read(adminOrdersProvider.future),
      throwsA(
        isA<AdminException>().having((e) => e.forbidden, 'forbidden', true),
      ),
    );
    expect(
      await container
          .read(adminActionProvider.notifier)
          .resolve(AdminActionKind.provider, 'P-101', approve: true, note: ''),
      false,
    );
    expect(container.read(adminActionProvider).hasError, true);
  });

  test(
    'Pending badge combines both refund sources and refreshes after action',
    () async {
      final container = ProviderContainer(
        overrides: [
          adminSessionProvider.overrideWith(
            () => AdminSessionController(initialSession: session),
          ),
          adminRepositoryProvider.overrideWithValue(repository()),
        ],
      );
      addTearDown(container.dispose);
      expect(
        (await container.read(adminPendingCountsProvider.future)).total,
        7,
      );
      expect(
        await container
            .read(adminActionProvider.notifier)
            .resolve(
              AdminActionKind.dispute,
              'DP-01',
              approve: false,
              note: 'Không đủ bằng chứng',
            ),
        true,
      );
      expect(
        (await container.read(adminPendingCountsProvider.future)).total,
        6,
      );
    },
  );

  test(
    'Concurrent submissions are ignored while the first is in progress',
    () async {
      final container = ProviderContainer(
        overrides: [
          adminSessionProvider.overrideWith(
            () => AdminSessionController(initialSession: session),
          ),
          adminRepositoryProvider.overrideWithValue(repository()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(adminActionProvider.notifier);
      final first = controller.resolve(
        AdminActionKind.provider,
        'P-101',
        approve: true,
        note: '',
      );
      expect(
        await controller.resolve(
          AdminActionKind.provider,
          'P-101',
          approve: true,
          note: '',
        ),
        false,
      );
      expect(await first, true);
    },
  );

  test(
    'Late operation cannot report success into a signed-out session',
    () async {
      final container = ProviderContainer(
        overrides: [
          adminSessionProvider.overrideWith(
            () => AdminSessionController(initialSession: session),
          ),
          adminRepositoryProvider.overrideWithValue(repository()),
        ],
      );
      addTearDown(container.dispose);
      final result = container
          .read(adminActionProvider.notifier)
          .resolve(AdminActionKind.provider, 'P-101', approve: true, note: '');
      container.read(adminSessionProvider.notifier).signOut();
      expect(await result, false);
      expect(container.read(adminSessionProvider), isNull);
    },
  );

  test(
    'Signing out and starting a new session resets mock wallet and filters',
    () async {
      final container = ProviderContainer(
        overrides: [adminClockProvider.overrideWithValue(() => now)],
      );
      addTearDown(container.dispose);
      container.read(adminSessionProvider.notifier).setSession(session);
      final first = container.read(adminRepositoryProvider);
      await first.resolveWithdrawal('WD-01', approve: true, note: '');
      container
          .read(adminOrderFilterProvider.notifier)
          .update(const AdminOrderFilter(search: 'MC-2601'));
      container.read(adminSessionProvider.notifier).signOut();
      container
          .read(adminSessionProvider.notifier)
          .setSession(
            const AdminSession(
              id: 'admin-2',
              name: 'Khác',
              email: 'other@example.test',
              role: 'ADMIN',
            ),
          );
      final second = container.read(adminRepositoryProvider);
      expect(identical(first, second), false);
      expect((await second.wallet('P-01')).locked, 200000);
      expect(container.read(adminOrderFilterProvider).search, isEmpty);
    },
  );
}
