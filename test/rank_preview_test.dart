import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/demo_controls_screen.dart';
import 'package:motocare_mechanic/screens/rank_screen.dart';
import 'package:motocare_mechanic/screens/weekly_summary_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/theme/rank_theme.dart';
import 'package:motocare_mechanic/widgets/income_chart.dart';

void main() {
  final boundary = GlobalKey();
  setUp(() {
    rankPreview.clear();
    appState.profile = MockData.profile();
    appState.history
      ..clear()
      ..addAll(MockData.history());
    appState.transactions
      ..clear()
      ..addAll(MockData.transactions());
    appState.balance = 1250000;
  });
  tearDown(rankPreview.clear);

  Future<void> host(WidgetTester t,
      {Widget page = const WeeklySummaryScreen(),
      Size size = const Size(412, 915),
      double scale = 1,
      bool reduce = false}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          theme: buildAppTheme(),
          builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: reduce),
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

  /// The colour actually painted right now (not the animation's target).
  Color bg(WidgetTester t) {
    final box = t.widget<DecoratedBox>(find
        .descendant(
            of: k('weekly-rank-panel'), matching: find.byType(DecoratedBox))
        .first);
    return ((box.decoration as BoxDecoration).gradient! as LinearGradient)
        .colors
        .first;
  }

  String tier(WidgetTester t) => t
      .widget<Text>(k('weekly-tier-name').last)
      .data!; // newest child during a switch

  testWidgets('Preview Đồng / Bạc / Vàng use their own colours and layout',
      (t) async {
    await host(t);
    final size = t.getRect(k('weekly-rank-panel')).size;
    for (final (state, name, color, progress) in [
      (
        rankPreviewBronze,
        'Đồng',
        const Color(0xFFF6E4D7),
        const Color(0xFFB87945)
      ),
      (
        rankPreviewSilver,
        'Bạc',
        const Color(0xFFE8EDF2),
        const Color(0xFF317CBB)
      ),
      (
        rankPreviewGold,
        'Vàng',
        const Color(0xFFFFF3D6),
        const Color(0xFFC69427)
      ),
    ]) {
      rankPreview.show(state);
      await t.pumpAndSettle();
      expect(tier(t), name);
      expect(bg(t), color);
      expect(t.widget<LinearProgressIndicator>(k('weekly-rank-progress')).color,
          progress);
      expect(k('weekly-rank-simulated'), findsOneWidget);
      expect(find.text('Mô phỏng'), findsOneWidget);
      expect(t.getRect(k('weekly-rank-panel')).size.width,
          closeTo(size.width, .5));
      // The income panel always stays REVO blue.
      final hero = t.widget<Container>(k('weekly-income-hero'));
      expect(
          ((hero.decoration! as BoxDecoration).gradient! as LinearGradient)
              .colors
              .first,
          const Color(0xFF317CBB));
      expect(k('weekly-income-total'), findsOneWidget);
      await shot(t, 'rank-$name');
    }
    expect(find.text('Vàng · Hạng cao nhất'), findsOneWidget);
    expect(find.textContaining('Kim cương'), findsNothing);
  });

  testWidgets('The colour transition is animated, not a jump', (t) async {
    await host(t);
    rankPreview.show(rankPreviewBronze);
    await t.pumpAndSettle();
    final from = bg(t);
    rankPreview.show(rankPreviewGold);
    await t.pump();
    await t.pump(const Duration(milliseconds: 150));
    final mid = bg(t);
    expect(mid, isNot(from));
    expect(mid, isNot(const Color(0xFFFFF3D6)));
    await t.pumpAndSettle();
    expect(bg(t), const Color(0xFFFFF3D6));
    // Progress also tweens (never snaps to zero).
    rankPreview.show(rankPreviewBronze);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    final v =
        t.widget<LinearProgressIndicator>(k('weekly-rank-progress')).value!;
    expect(v, inExclusiveRange(rankPreviewBronze.progress, 1.0));
    await t.pumpAndSettle();
  });

  testWidgets('Demo run goes Đồng → Bạc → Vàng, stops, and can be re-run',
      (t) async {
    await host(t);
    await t.tap(k('weekly-rank-try'));
    await t.pump();
    expect(tier(t), 'Đồng');
    await t.pump(const Duration(milliseconds: 1500));
    await t.pump(const Duration(milliseconds: 400));
    expect(tier(t), 'Bạc');
    await t.pump(const Duration(milliseconds: 1500));
    await t.pump(const Duration(milliseconds: 400));
    expect(tier(t), 'Vàng');
    // Nothing keeps running or looping after Vàng.
    await t.pump(const Duration(seconds: 10));
    await t.pumpAndSettle();
    expect(tier(t), 'Vàng');
    expect(rankPreview.running, isFalse);
    // Run again from the demo controls: restarts from Đồng.
    rankPreview.runDemo();
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(tier(t), 'Đồng');
    await t.pump(const Duration(milliseconds: 3000));
    await t.pumpAndSettle();
    expect(tier(t), 'Vàng');
  });

  testWidgets('Pressing run repeatedly never stacks runs', (t) async {
    await host(t);
    for (var i = 0; i < 4; i++) {
      rankPreview.runDemo();
      await t.pump(const Duration(milliseconds: 500));
    }
    // Only the last run is alive: Bạc appears 1.4s after it began, not earlier.
    expect(tier(t), 'Đồng');
    await t.pump(const Duration(milliseconds: 1000));
    await t.pump(const Duration(milliseconds: 300));
    expect(tier(t), 'Bạc');
    await t.pumpAndSettle(const Duration(seconds: 1));
    expect(tier(t), 'Vàng');
  });

  testWidgets(
      'Ending the preview returns to the real rank without changing data',
      (t) async {
    final profile = appState.profile;
    final before = (
      profile.tierName,
      profile.tierOrders,
      appState.balance,
      appState.history.length,
      appState.transactions.length
    );
    await host(t);
    rankPreview.show(rankPreviewGold);
    await t.pumpAndSettle();
    expect(tier(t), 'Vàng');
    await t.tap(k('weekly-rank-preview-end'));
    await t.pumpAndSettle();
    expect(tier(t), 'Bạc');
    expect(k('weekly-rank-simulated'), findsNothing);
    expect(
        find.text(
            'Còn ${appState.profile.ordersToNextTier} đơn hợp lệ để đạt mốc tiếp theo'),
        findsOneWidget);
    expect(identical(appState.profile, profile), isTrue);
    expect((
      appState.profile.tierName,
      appState.profile.tierOrders,
      appState.balance,
      appState.history.length,
      appState.transactions.length
    ), before);
  });

  testWidgets('Leaving the weekly screen drops any simulated rank', (t) async {
    await host(t);
    rankPreview.runDemo();
    await t.pump();
    await t.pumpWidget(const SizedBox());
    expect(rankPreview.state, isNull);
    expect(rankPreview.running, isFalse);
    await t.pump(const Duration(seconds: 5));
    expect(t.takeException(), isNull);
  });

  testWidgets('Rank link still opens the rank screen during a preview',
      (t) async {
    await host(t);
    rankPreview.show(rankPreviewBronze);
    await t.pumpAndSettle();
    await t.ensureVisible(k('weekly-rank-link'));
    await t.tap(k('weekly-rank-link'));
    await t.pumpAndSettle();
    expect(find.byType(RankBenefitsScreen), findsOneWidget);
  });

  testWidgets('Reduced motion switches instantly', (t) async {
    await host(t, reduce: true);
    rankPreview.show(rankPreviewGold);
    await t.pump();
    expect(bg(t), const Color(0xFFFFF3D6));
    expect(tier(t), 'Vàng');
  });

  testWidgets('Demo controls drive the preview (and only the preview)',
      (t) async {
    final profile = appState.profile;
    await host(t, page: const DemoControlsScreen());
    await t.ensureVisible(k('demo-rank-Bạc'));
    await t.tap(k('demo-rank-Bạc'));
    await t.pumpAndSettle();
    expect(rankPreview.state, rankPreviewSilver);
    await t.ensureVisible(k('demo-rank-run'));
    await t.tap(k('demo-rank-run'));
    await t.pump();
    expect(rankPreview.state, rankPreviewBronze);
    await t.pump(const Duration(seconds: 4));
    expect(rankPreview.state, rankPreviewGold);
    await t.ensureVisible(k('demo-rank-end'));
    await t.tap(k('demo-rank-end'));
    await t.pumpAndSettle();
    expect(rankPreview.state, isNull);
    expect(identical(appState.profile, profile), isTrue);
    expect(appState.profile.tierName, 'Bạc');
  });

  group('period switch', () {
    testWidgets('wide enough: one row, switch on the right, wider and lower',
        (t) async {
      await host(t);
      final sw = t.getRect(k('weekly-period-switch'));
      expect(sw.height, inInclusiveRange(40, 44));
      expect(sw.width, inInclusiveRange(168, 220));
      final title = t.getRect(find.text('Biểu đồ thu nhập'));
      expect(sw.left - title.right, greaterThanOrEqualTo(10));
      expect(title.center.dy, closeTo(sw.center.dy, 4));
      // Right aligned with the card content.
      final card = t.getRect(find.byType(IncomeLineChart));
      expect(sw.right, closeTo(card.right, 2));
      final a = t.getRect(k('weekly-tab-week'));
      final b = t.getRect(k('weekly-tab-month'));
      expect(a.width, closeTo(b.width, .5));
      await shot(t, 'period-switch');
    });

    testWidgets('narrow or big text: switch moves below, still right-aligned',
        (t) async {
      await host(t, size: const Size(320, 640), scale: 1.3);
      final sw = t.getRect(k('weekly-period-switch'));
      final title = t.getRect(find.text('Biểu đồ thu nhập'));
      expect(sw.top, greaterThanOrEqualTo(title.bottom));
      final card = t.getRect(find.byType(IncomeLineChart));
      expect(sw.right, closeTo(card.right, 2));
      expect(sw.height, inInclusiveRange(40, 44));
      expect(t.takeException(), isNull);
    });

    testWidgets('week and month still switch the chart data', (t) async {
      await host(t);
      final week =
          t.widget<IncomeLineChart>(find.byType(IncomeLineChart)).values.length;
      await t.tap(k('weekly-tab-month'));
      await t.pumpAndSettle();
      final month =
          t.widget<IncomeLineChart>(find.byType(IncomeLineChart)).values.length;
      expect(week, 7);
      expect(month,
          DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day);
      expect(
          (t.widget<AnimatedContainer>(k('weekly-tab-month')).decoration!
                  as BoxDecoration)
              .color,
          const Color(0xFF111111));
      await t.tap(k('weekly-tab-week'));
      await t.pumpAndSettle();
      expect(
          t.widget<IncomeLineChart>(find.byType(IncomeLineChart)).values.length,
          7);
    });
  });

  for (final c in [
    (const Size(412, 915), 1.0),
    (const Size(360, 780), 1.3),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets('No overflow during a preview ${c.$1} at ${c.$2}', (t) async {
      await host(t, size: c.$1, scale: c.$2);
      rankPreview.show(rankPreviewBronze);
      await t.pump(const Duration(milliseconds: 200));
      expect(t.takeException(), isNull);
      rankPreview.show(rankPreviewGold);
      await t.pump(const Duration(milliseconds: 200));
      expect(t.takeException(), isNull);
      await t.pumpAndSettle();
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
