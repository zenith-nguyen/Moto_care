import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/order_history_detail_screen.dart';
import 'package:motocare_mechanic/utils/format.dart';
import 'support/current_week_fixtures.dart';
import 'package:motocare_mechanic/screens/weekly_summary_screen.dart';
import 'package:motocare_mechanic/services/weekly_summary_data.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/income_chart.dart';

final friday = DateTime(2026, 10, 16, 16);
WalletTransaction credit(String id, int amount, DateTime time,
        {TxType type = TxType.credit, WithdrawStatus? status}) =>
    WalletTransaction(
        code: id,
        txnId: 'TX-$id',
        orderCode: id,
        type: type,
        amount: amount,
        time: time,
        withdrawStatus: status);
OrderHistoryItem order(String id, DateTime time,
        {OrderStatus status = OrderStatus.completed, int? stars}) =>
    OrderHistoryItem(
        code: id,
        issue: 'Kích bình',
        vehicle: 'Toyota Vios',
        plate: '51A-12345',
        customerName: 'Khách thử',
        customerPhone: '0900000000',
        address: 'Quận 1, TP.HCM',
        status: status,
        time: time,
        initialPrice: 150000,
        finalPrice: 150000,
        fee: 9000,
        timeline: [],
        customerRating: stars,
        rating: 1);

void main() {
  test('Income and zero-based daily buckets use net Wallet credits only', () {
    final data = WeeklySummaryData(history: [], transactions: [
      credit('a', 141000, DateTime(2026, 10, 12)),
      credit('b', 112000, DateTime(2026, 10, 16, 15)),
      credit('withdraw', 500000, friday, type: TxType.debit),
      credit('failed-withdraw', 300000, friday,
          type: TxType.debit, status: WithdrawStatus.failed),
      credit('previous', 90000, DateTime(2026, 10, 11, 23, 59)),
      credit('future', 600000, DateTime(2026, 10, 16, 17)),
      credit('next', 800000, DateTime(2026, 10, 19)),
    ], anchor: friday, now: friday);
    expect(data.income, 253000);
    expect(data.dailyIncome, [141000, 0, 0, 0, 112000, null, null]);
    expect(data.dailyIncome.whereType<int>().fold<int>(0, (a, b) => a + b),
        data.income);
  });

  test(
      'Weekly customer ratings, completed count and ratio use actual closed orders',
      () {
    final data = WeeklySummaryData(history: [
      order('a', friday, stars: 5),
      order('b', friday, stars: 4),
      order('c', friday, status: OrderStatus.cancelled, stars: 1),
      order('d', friday, status: OrderStatus.active),
      order('old', DateTime(2026, 10, 11), stars: 1),
    ], transactions: [], anchor: friday, now: friday);
    expect(data.orders.length, 2);
    expect(data.closedCount, 3);
    expect(data.completionRate, 2 / 3);
    expect(data.averageRating,
        4.5); // Never use the mechanic's rating of customer.
    expect(data.ratingCount, 2);
  });

  test('Monday/Sunday and year/month boundaries retain the same reporting week',
      () {
    for (final anchor in [DateTime(2026, 12, 28), DateTime(2027, 1, 3)]) {
      final data = WeeklySummaryData(
          history: [],
          transactions: [],
          anchor: anchor,
          now: DateTime(2027, 1, 4));
      expect(data.start, DateTime(2026, 12, 28));
      expect(data.end, DateTime(2027, 1, 4));
      expect(data.days.length, 7);
      expect(data.days.last, DateTime(2027, 1, 3));
    }
    final feb = WeeklySummaryData(
        history: [],
        transactions: [],
        anchor: DateTime(2028, 2, 2),
        now: DateTime(2028, 3, 1),
        monthly: true);
    expect(feb.days.length, 29);
  });

  test('Empty and future periods have no invented ratings, rate or income', () {
    final data = WeeklySummaryData(
        history: [],
        transactions: [],
        anchor: friday,
        now: DateTime(2026, 10, 1));
    expect(data.income, 0);
    expect(data.averageRating, isNull);
    expect(data.completionRate, isNull);
    expect(data.dailyIncome.every((v) => v == null), isTrue);
  });

  test(
      'Order-ID lookup uses ledger credit, discloses missing detail and missing credit',
      () {
    final data = WeeklySummaryData(history: [
      order('a', friday),
      order('unpaid', friday)
    ], transactions: [
      credit('a', 140000, friday),
      credit('other', 20000, friday)
    ], anchor: friday, now: friday);
    expect(
        data.incomeForOrder('a'), 140000); // Does not invent finalPrice - fee.
    expect(data.incomeForOrder('unpaid'), isNull);
    expect(data.unmatchedIncome, 20000);
    expect(data.income, 160000);
  });

  test('Monthly chart total agrees with existing Wallet month income', () {
    final state = AppState(demoEnabled: true);
    final now = DateTime.now();
    final data = WeeklySummaryData(
        history: state.history,
        transactions: state.transactions,
        anchor: now,
        now: now,
        monthly: true);
    expect(data.income, state.monthIncome);
    expect(data.dailyIncome.whereType<int>().fold<int>(0, (a, b) => a + b),
        state.monthIncome);
    state.dispose();
  });

  test(
      'Completing an order changes report by one credit; opening reports is read-only',
      () {
    final state = AppState(demoEnabled: true);
    WeeklySummaryData report() => WeeklySummaryData(
        history: state.history,
        transactions: state.transactions,
        anchor: DateTime.now(),
        now: DateTime.now());
    final before = report().income;
    final balance = state.balance;
    final o = state.acceptOffer(state.nextOffer(serviceIndex: 0));
    state.beginNavigation(orderId: o.orderId);
    state.markArrived(orderId: o.orderId);
    state.startRepair(orderId: o.orderId, code: o.offer.verificationCode);
    while (o.repairStage < 3) {
      state.advanceRepair(orderId: o.orderId);
    }
    final item = state.completeOrder(orderId: o.orderId);
    final after = report();
    expect(after.income, before + item.earning);
    expect(after.incomeForOrder(item.code), item.earning);
    expect(state.balance, balance + item.earning);
    expect(state.completeOrder(orderId: o.orderId), same(item));
    expect(report().income, after.income);
    expect(state.balance, balance + item.earning);
    state.dispose();
  });

  Future<void> host(WidgetTester tester,
      {Size size = const Size(412, 915), double scale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appState.activeOrder = null;
    seedCurrentWeekFixtures();
    await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        home: const WeeklySummaryScreen(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!)));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Brand colors, black week tab, black see-all and Montserrat are exact',
      (tester) async {
    await host(tester);
    final hero = tester
        .widget<Container>(find.byKey(const ValueKey('weekly-income-hero')));
    expect((hero.decoration as BoxDecoration).gradient!.colors.first,
        const Color(0xFF317CBB));
    final tab = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('weekly-tab-week')));
    expect((tab.decoration as BoxDecoration).color, const Color(0xFF111111));
    final week = tester.widget<Text>(find.text('Tuần này'));
    expect(
        tester
            .widget<AnimatedDefaultTextStyle>(find
                .ancestor(
                    of: find.text('Tuần này'),
                    matching: find.byType(AnimatedDefaultTextStyle))
                .first)
            .style
            .color,
        Colors.white);
    expect(week.data, 'Tuần này');
    expect(tester.widget<Text>(find.text('Xem tất cả')).style!.color,
        const Color(0xFF111111));
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('weekly-income-total')))
            .data,
        '253.000đ');
    // The unreliable "activity time" and "completion rate" cards were removed.
    expect(find.text('Demo · chưa đo'), findsNothing);
    expect(find.text('Thời gian hoạt động'), findsNothing);
    expect(find.text('Tỉ lệ hoàn thành'), findsNothing);
    expect(find.textContaining('+12%'), findsNothing);
    expect(find.text('~18 giờ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Month tab and chart selection update real data without changing orders or money',
      (tester) async {
    await host(tester);
    final balance = appState.balance, count = appState.history.length;
    await tester.ensureVisible(find.text('Tháng này'));
    await tester.tap(find.text('Tháng này'));
    await tester.pumpAndSettle();
    var chart = tester.widget<IncomeLineChart>(find.byType(IncomeLineChart));
    expect(chart.values.length,
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day);
    expect(chart.values.whereType<int>().fold<int>(0, (a, b) => a + b),
        appState.monthIncome);
    await tester.tap(find.text('Tuần này'));
    await tester.pumpAndSettle();
    chart = tester.widget<IncomeLineChart>(find.byType(IncomeLineChart));
    expect(chart.values.length, 7);
    await tester
        .ensureVisible(find.byKey(const ValueKey('weekly-income-chart')));
    final rect =
        tester.getRect(find.byKey(const ValueKey('weekly-income-chart')));
    await tester.tapAt(Offset(rect.left + 38, rect.top + 80));
    await tester.pumpAndSettle();
    expect(
        find.text(
            '${chart.dates.first.day.toString().padLeft(2, '0')}/${chart.dates.first.month.toString().padLeft(2, '0')} · ${formatVnd(chart.values.first ?? 0)}'),
        findsOneWidget);
    expect(appState.balance, balance);
    expect(appState.history.length, count);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Calendar changes reporting week, with honest empty state',
      (tester) async {
    await host(tester);
    await tester.tap(find.byKey(const ValueKey('weekly-date-range')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('Xem tuần'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('weekly-income-total')))
            .data,
        '0đ');
    await tester
        .ensureVisible(find.text('Chưa có đơn hoàn thành trong tuần này.'));
    expect(find.text('Chưa có đơn hoàn thành trong tuần này.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Positive income in the weekly order list is success green',
      (tester) async {
    await host(tester);
    final texts = find.byWidgetPredicate((w) =>
        w is Text &&
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('weekly-money-'));
    expect(texts, findsWidgets);
    for (final e in tester.widgetList<Text>(texts)) {
      if (e.data!.startsWith('+')) {
        expect(e.style!.color, const Color(0xFF12B76A), reason: e.data);
        expect(e.style!.fontFamily, 'Montserrat');
        expect(e.style!.fontSize, 12);
        expect(e.style!.fontWeight, FontWeight.w700);
      } else {
        // "Chưa ghi có" keeps its previous colour.
        expect(e.style!.color, const Color(0xFF317CBB));
      }
    }
  });

  testWidgets('Weekly order row opens existing detail with the same order ID',
      (tester) async {
    await host(tester);
    final item =
        appState.history.firstWhere((o) => o.status == OrderStatus.completed);
    final row = find.byKey(ValueKey('weekly-order-${item.code}'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<OrderHistoryDetailScreen>(
                find.byType(OrderHistoryDetailScreen))
            .item,
        same(item));
    expect(find.text(item.code), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final config in [
    (const Size(320, 568), 1.6),
    (const Size(390, 844), 1.0)
  ]) {
    testWidgets(
        'All summary sections scroll without overflow at ${config.$1} text ${config.$2}',
        (tester) async {
      await host(tester, size: config.$1, scale: config.$2);
      for (var i = 0; i < 5; i++) {
        expect(tester.takeException(), isNull);
        await tester.drag(find.byKey(const ValueKey('weekly-summary-scroll')),
            const Offset(0, -350));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Chart handles empty and singleton source without invalid indexing',
      (tester) async {
    for (final values in <List<int?>>[
      [],
      [0],
      [null]
    ]) {
      await tester.pumpWidget(MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
              body: IncomeLineChart(
                  values: values,
                  dates: [for (var i = 0; i < values.length; i++) friday]))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
