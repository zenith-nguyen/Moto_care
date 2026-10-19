import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/mechanic_account_screen.dart';
import 'package:motocare_mechanic/screens/rank_screen.dart';
import 'package:motocare_mechanic/screens/weekly_summary_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';

void main() {
  final boundary = GlobalKey();
  setUp(() {
    appState.activeOrder = null;
    appState.profile = MockData.profile();
    appState.history
      ..clear()
      ..addAll(MockData.history());
    appState.transactions
      ..clear()
      ..addAll(MockData.transactions());
    appState.balance = 1250000;
    appState.setTab(3);
  });

  Future<void> host(WidgetTester t, Widget page,
      {Size size = const Size(412, 915), double scale = 1}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          theme: buildAppTheme(),
          builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: page,
        )));
    await t.pumpAndSettle();
  }

  Future<void> shot(WidgetTester t, String name) async {
    const output = String.fromEnvironment('REVO_HOME_PIXELS_CAPTURE');
    if (output.isEmpty) return;
    await t.runAsync(() async {
      final r =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final png = await r.toImage(pixelRatio: 2);
      final b = await png.toByteData(format: ui.ImageByteFormat.png);
      Directory(output).createSync(recursive: true);
      File('$output/$name.png').writeAsBytesSync(b!.buffer.asUint8List());
    });
  }

  Finder k(String key) => find.byKey(ValueKey(key));

  testWidgets('Weekly summary has exactly two equal metric cards', (t) async {
    await host(t, const WeeklySummaryScreen());
    expect(find.text('Thời gian hoạt động'), findsNothing);
    expect(find.text('Tỉ lệ hoàn thành'), findsNothing);
    final a = t.getRect(k('weekly-metric-orders'));
    final b = t.getRect(k('weekly-metric-rating'));
    expect(a.top, b.top);
    expect(a.width, closeTo(b.width, .01));
    expect(a.height, closeTo(b.height, .01));
    expect(find.text('Đơn hoàn thành'), findsOneWidget);
    expect(find.text('Trong tuần này'), findsOneWidget);
    expect(find.text('Đánh giá trung bình'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_turned_in_outlined), findsOneWidget);
    final icon =
        t.widget<Icon>(find.byIcon(Icons.assignment_turned_in_outlined));
    expect(icon.color, const Color(0xFF317CBB));
  });

  testWidgets('Without ratings the card says so instead of showing 5.0',
      (t) async {
    appState.history
      ..clear()
      ..addAll(MockData.history().map((o) => o)); // fixtures have 5.0 reviews
    await host(t, const WeeklySummaryScreen());
    // Demo week has ratings -> value is real, never a made-up default.
    final rating = appState.history
        .where((o) => o.customerRating != null)
        .map((o) => o.customerRating!);
    if (rating.isEmpty) {
      expect(find.text('Chưa có đánh giá'), findsOneWidget);
    }
    appState.history.clear();
    appState.setTab(3);
    await host(t, const WeeklySummaryScreen());
    expect(find.text('Chưa có đánh giá'), findsOneWidget);
    expect(find.text('5.0'), findsNothing);
  });

  testWidgets(
      'Banner shows tier progress from the profile and opens the rank screen',
      (t) async {
    await host(t, const WeeklySummaryScreen());
    final p = appState.profile;
    expect(find.text('${p.tierName} → ${p.nextTierName}'), findsOneWidget);
    expect(
        find.text('Còn ${p.ordersToNextTier} đơn hợp lệ để đạt mốc tiếp theo'),
        findsOneWidget);
    final bar = t.widget<LinearProgressIndicator>(k('weekly-rank-progress'));
    expect(bar.value, p.tierProgress);
    await t.ensureVisible(k('weekly-rank-link'));
    await t.tap(k('weekly-rank-link'));
    await t.pumpAndSettle();
    expect(find.byType(RankBenefitsScreen), findsOneWidget);
  });

  testWidgets('Account row opens the same rank screen', (t) async {
    await host(t, const Scaffold(body: MechanicAccountScreen()));
    await t.ensureVisible(find.text('Hạng thợ & Quyền lợi'));
    await t.pumpAndSettle();
    await t.tap(find.text('Hạng thợ & Quyền lợi'));
    await t.pumpAndSettle();
    expect(find.byType(RankBenefitsScreen), findsOneWidget);
  });

  testWidgets('Rank screen shows only real data and labels the rest honestly',
      (t) async {
    await host(t, const RankBenefitsScreen());
    final p = appState.profile;
    expect(find.text('Hạng thợ & Quyền lợi'), findsOneWidget);
    expect(t.widget<Text>(k('rank-tier-name')).data, p.tierName);
    expect(find.text('Tiến tới Hạng ${p.nextTierName}'), findsOneWidget);
    expect(t.widget<LinearProgressIndicator>(k('rank-progress')).value,
        p.tierProgress);
    expect(t.widget<Text>(k('rank-recorded')).data,
        '${p.tierOrders}/${p.nextTierTarget} đơn đã ghi nhận');
    expect(t.widget<Text>(k('rank-remaining')).data,
        'Còn ${p.ordersToNextTier} đơn hợp lệ');
    expect(find.text('Demo'), findsOneWidget);
    // Only the real condition (order count) is listed; no invented ones.
    expect(
        find.text('Hoàn thành ${p.nextTierTarget} đơn hợp lệ'), findsOneWidget);
    expect(find.textContaining('chưa có thêm tiêu chí'), findsOneWidget);
    // Benefits are not invented.
    expect(find.textContaining('chưa được REVO công bố'), findsOneWidget);
    // Demo history is too short to forecast.
    expect(find.textContaining('Chưa đủ dữ liệu'), findsOneWidget);
    await shot(t, 'rank');
  });

  group('forecast', () {
    OrderHistoryItem order(int daysAgo) {
      final base = MockData.history().first;
      return OrderHistoryItem(
          code: '#T$daysAgo',
          issue: base.issue,
          vehicle: base.vehicle,
          plate: base.plate,
          customerName: base.customerName,
          customerPhone: base.customerPhone,
          address: base.address,
          status: OrderStatus.completed,
          time: DateTime(2026, 10, 20).subtract(Duration(days: daysAgo)),
          initialPrice: 1,
          finalPrice: 1,
          fee: 0,
          timeline: base.timeline);
    }

    final now = DateTime(2026, 10, 20);
    test('null without enough history', () {
      expect(
          RankForecast.compute(
              history: [order(3), order(2), order(1)], now: now, remaining: 5),
          isNull);
      expect(
          RankForecast.compute(
              history: [order(20), order(1)], now: now, remaining: 5),
          isNull);
      expect(
          RankForecast.compute(
              history: [order(20), order(10), order(1)],
              now: now,
              remaining: 0),
          isNull);
    });
    test('uses the real weekly pace', () {
      final f = RankForecast.compute(
          history: [order(28), order(21), order(14), order(7)],
          now: now,
          remaining: 6)!;
      expect(f.weeklyAverage, closeTo(1.0, .01));
      expect(f.weeks, 6);
      expect(f.span, 28);
    });
  });

  testWidgets(
      'Rank screen with enough history shows an estimate, not a promise',
      (t) async {
    final base = MockData.history().first;
    for (final d in [30, 20, 10, 2]) {
      appState.history.add(OrderHistoryItem(
          code: '#F$d',
          issue: base.issue,
          vehicle: base.vehicle,
          plate: base.plate,
          customerName: base.customerName,
          customerPhone: base.customerPhone,
          address: base.address,
          status: OrderStatus.completed,
          time: DateTime.now().subtract(Duration(days: d)),
          initialPrice: 1,
          finalPrice: 1,
          fee: 0,
          timeline: base.timeline));
    }
    await host(t, const RankBenefitsScreen());
    expect(t.widget<Text>(k('rank-forecast-text')).data,
        contains('chỉ là ước tính'));
  });

  for (final c in [
    (const Size(412, 915), 1.0),
    (const Size(320, 568), 1.6),
    (const Size(360, 780), 1.3),
  ]) {
    testWidgets('No overflow ${c.$1} at ${c.$2}', (t) async {
      await host(t, const WeeklySummaryScreen(), size: c.$1, scale: c.$2);
      expect(t.takeException(), isNull);
      await host(t, const RankBenefitsScreen(), size: c.$1, scale: c.$2);
      expect(t.takeException(), isNull);
      final clipped = <String>[];
      for (final e in find.byType(RichText).evaluate()) {
        final r = e.renderObject;
        if (r is RenderParagraph && r.didExceedMaxLines) {
          clipped.add(r.text.toPlainText());
        }
      }
      expect(clipped, isEmpty);
    });
  }
}
