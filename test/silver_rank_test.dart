import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/rank_screen.dart';
import 'package:motocare_mechanic/screens/weekly_summary_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';

void main() {
  final boundary = GlobalKey();
  setUp(() {
    appState.profile = MockData.profile();
    appState.history
      ..clear()
      ..addAll(MockData.history());
    appState.transactions
      ..clear()
      ..addAll(MockData.transactions());
    appState.balance = 1250000;
  });

  MechanicProfile tier(String name, String next, int orders, int target) {
    final b = MockData.profile();
    return MechanicProfile(
        name: b.name,
        bio: b.bio,
        tierName: name,
        nextTierName: next,
        tierOrders: orders,
        nextTierTarget: target,
        experienceYears: b.experienceYears,
        radiusKm: b.radiusKm,
        rating: b.rating,
        ratingCount: b.ratingCount,
        area: b.area,
        skills: b.skills,
        documents: b.documents);
  }

  Future<void> host(WidgetTester t,
      {Size size = const Size(412, 915), double scale = 1}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    // Fresh tree each time so a changed profile is picked up.
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          theme: buildAppTheme(),
          builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: const WeeklySummaryScreen(),
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

  testWidgets(
      'Silver tier: silver panel, navy title, blue progress; income stays blue',
      (t) async {
    await host(t);
    final panel = t.widget<AnimatedContainer>(k('weekly-rank-panel'));
    final deco = panel.decoration! as BoxDecoration;
    expect((deco.gradient! as LinearGradient).colors,
        [const Color(0xFFE8EDF2), const Color(0xFFDCE2E9)]);
    expect((deco.border! as Border).left.color, const Color(0xFFCBD5DF));
    final name = t.widget<Text>(k('weekly-tier-name'));
    expect(name.data, 'Bạc');
    expect(name.style!.color, const Color(0xFF172638));
    expect(name.style!.fontFamily, 'Montserrat');
    expect(name.style!.fontWeight, FontWeight.w700);
    final bar = t.widget<LinearProgressIndicator>(k('weekly-rank-progress'));
    expect(bar.color, const Color(0xFF317CBB));
    expect(bar.backgroundColor, const Color(0xFFB9C6D3));
    expect(bar.value, appState.profile.tierProgress);
    final badge = t.widget<Icon>(find.byIcon(Icons.workspace_premium_outlined));
    expect(badge.color, const Color(0xFF66788B));
    expect(t.widget<Text>(find.text('Xem lộ trình lên hạng →')).style!.color,
        const Color(0xFF317CBB));
    // Income side untouched: blue banner, white text, real amount.
    final hero = t.widget<Container>(k('weekly-income-hero'));
    expect(
        ((hero.decoration! as BoxDecoration).gradient! as LinearGradient)
            .colors
            .first,
        const Color(0xFF317CBB));
    final income = t.widget<Text>(k('weekly-income-total'));
    expect(income.style!.color, Colors.white);
    expect(income.data, '253.000đ');
    expect(
        find.text(
            'Còn ${appState.profile.ordersToNextTier} đơn hợp lệ để đạt mốc tiếp theo'),
        findsOneWidget);
    await shot(t, 'silver-banner');
  });

  testWidgets('Gold tier uses the gold theme with the same layout', (t) async {
    await host(t);
    final silverRect = t.getRect(k('weekly-rank-panel'));
    appState.profile = tier('Vàng', 'Kim cương', 30, 60);
    await host(t);
    final deco = t.widget<AnimatedContainer>(k('weekly-rank-panel')).decoration!
        as BoxDecoration;
    expect((deco.gradient! as LinearGradient).colors,
        [const Color(0xFFFFF3D6), const Color(0xFFFBE6B0)]);
    expect((deco.border! as Border).left.color, const Color(0xFFF0D58A));
    final name = t.widget<Text>(k('weekly-tier-name'));
    expect(name.data, 'Vàng');
    expect(name.style!.color, const Color(0xFF5C4300));
    final bar = t.widget<LinearProgressIndicator>(k('weekly-rank-progress'));
    expect(bar.color, const Color(0xFFC69427));
    expect(bar.backgroundColor, const Color(0xFFEAD59C));
    expect(bar.value, .5);
    expect(t.widget<Icon>(find.byIcon(Icons.workspace_premium_outlined)).color,
        const Color(0xFFC69427));
    expect(find.text('Còn 30 đơn hợp lệ để đạt mốc tiếp theo'), findsOneWidget);
    expect(find.text('Vàng → Kim cương'), findsOneWidget);
    expect(t.getRect(k('weekly-rank-panel')).size, silverRect.size);
    await shot(t, 'gold-banner');
  });

  testWidgets('Bronze theme for "Đồng"; unknown tiers keep the standard look',
      (t) async {
    appState.profile = tier('Đồng', 'Bạc', 5, 10);
    await host(t);
    var deco = t.widget<AnimatedContainer>(k('weekly-rank-panel')).decoration!
        as BoxDecoration;
    expect((deco.gradient! as LinearGradient).colors.first,
        const Color(0xFFF6E4D7));
    expect(t.widget<LinearProgressIndicator>(k('weekly-rank-progress')).color,
        const Color(0xFFB87945));
    appState.profile = tier('Kim cương', 'Huyền thoại', 1, 2);
    await host(t);
    deco = t.widget<AnimatedContainer>(k('weekly-rank-panel')).decoration!
        as BoxDecoration;
    expect(deco.gradient, isNull);
    expect(t.widget<Text>(k('weekly-tier-name')).style!.color, Colors.white);
  });

  testWidgets('Theme and numbers follow the profile when it changes live',
      (t) async {
    await host(t);
    expect(t.widget<Text>(k('weekly-tier-name')).data, 'Bạc');
    appState.profile = tier('Vàng', 'Kim cương', 30, 60);
    appState.setTab(0); // notifies listeners -> the screen rebuilds
    await t.pumpAndSettle();
    expect(t.widget<Text>(k('weekly-tier-name')).data, 'Vàng');
    expect(t.widget<LinearProgressIndicator>(k('weekly-rank-progress')).color,
        const Color(0xFFC69427));
  });

  testWidgets('Highest tier does not promise a non-existent next tier',
      (t) async {
    appState.profile = tier('Vàng', '', 100, 100);
    await host(t);
    expect(find.text('Vàng · Hạng cao nhất'), findsOneWidget);
    expect(find.text('Bạn đang ở hạng cao nhất'), findsOneWidget);
    expect(
        t.widget<LinearProgressIndicator>(k('weekly-rank-progress')).value, 1);
    expect(find.textContaining('đơn hợp lệ để đạt mốc'), findsNothing);
  });

  testWidgets(
      'Both panels exist; they stack on very large text and stay usable',
      (t) async {
    await host(t, size: const Size(320, 568), scale: 1.6);
    expect(k('weekly-income-total'), findsOneWidget);
    expect(k('weekly-rank-panel'), findsOneWidget);
    expect(k('weekly-rank-progress'), findsOneWidget);
    final incomeBottom = t.getBottomLeft(k('weekly-income-total')).dy;
    final panel = t.getRect(k('weekly-rank-panel'));
    expect(panel.top, greaterThanOrEqualTo(incomeBottom));
    expect(panel.width, closeTo(t.getRect(k('weekly-income-hero')).width, .5));
    await t.ensureVisible(k('weekly-rank-link'));
    await t.tap(k('weekly-rank-link'));
    await t.pumpAndSettle();
    expect(find.byType(RankBenefitsScreen), findsOneWidget);
  });

  testWidgets('Rank link still opens the rank screen; nothing else changes',
      (t) async {
    final balance = appState.balance;
    final history = appState.history.length;
    await host(t);
    await t.ensureVisible(k('weekly-rank-link'));
    await t.tap(k('weekly-rank-link'));
    await t.pumpAndSettle();
    expect(find.byType(RankBenefitsScreen), findsOneWidget);
    expect(appState.balance, balance);
    expect(appState.history.length, history);
  });

  for (final c in [
    (const Size(412, 915), 1.0),
    (const Size(360, 780), 1.0),
    (const Size(320, 568), 1.0),
    (const Size(412, 915), 1.3),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets('Banner fits ${c.$1} at ${c.$2}', (t) async {
      await host(t, size: c.$1, scale: c.$2);
      expect(t.takeException(), isNull);
      final hero = t.getRect(k('weekly-income-hero'));
      final panel = t.getRect(k('weekly-rank-panel'));
      expect(panel.right, closeTo(hero.right, .5));
      expect(panel.bottom, closeTo(hero.bottom, .5));
      final clipped = <String>[];
      for (final e in find.byType(RichText).evaluate()) {
        final r = e.renderObject;
        if (r is RenderParagraph && r.didExceedMaxLines) {
          clipped.add(r.text.toPlainText());
        }
      }
      expect(clipped, isEmpty);
      await shot(t, 'banner-${c.$1.width.toInt()}-${c.$2}');
    });
  }
}
