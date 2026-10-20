import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/incoming_order_popup.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/home_components.dart';

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
    appState.startDemoSession();
    appState.setNetworkAvailable(true);
    appState.setGps(true);
    appState.setOnline(true);
    appState.saveServices([true, true, true, true, true, false, false]);
    appState.setTab(0);
  });

  Future<void> host(WidgetTester t,
      {Size size = const Size(412, 915), double scale = 1}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const MechanicShell(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
        )));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      for (final asset in [
        'revo_hero_engine.jpg',
        'revo_hero_tools.jpg',
        'revo_hero_teamwork.jpg',
        'home_battery_car.png',
        'home_tire_suv.png',
        'home_service_tow.png',
        'home_service_flood.png',
        'home_service_repair.png',
      ]) {
        await precacheImage(
            AssetImage('assets/images/$asset'), boundary.currentContext!);
      }
    });
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  Future<void> shot(WidgetTester t, String name) async {
    const output = String.fromEnvironment('REVO_HOME_PIXELS_CAPTURE');
    if (output.isEmpty) return;
    await t.runAsync(() async {
      final renderer =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final png = await renderer.toImage(pixelRatio: 2);
      final bytes = await png.toByteData(format: ui.ImageByteFormat.png);
      Directory(output).createSync(recursive: true);
      File('$output/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      png.dispose();
    });
  }

  Future<void> tapTip(WidgetTester t, String tip) async {
    await t.tap(find.byTooltip(tip));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  final hero = find.byType(HomeHeroCarousel);
  final heroImages = find.descendant(of: hero, matching: find.byType(Image));
  String shownImage(WidgetTester t) {
    // The page that is fully on screen.
    final visible = t
        .widgetList<Image>(heroImages)
        .where((i) => t.getRect(find.byWidget(i)).left.abs() < 40)
        .toList();
    expect(visible, hasLength(1));
    return (visible.single.image as AssetImage).assetName;
  }

  /// Which dot is active, read from the semantics `selected` flag.
  int activeDot(WidgetTester t) {
    var active = -1;
    for (var i = 0; i < 3; i++) {
      final node = t.getSemantics(find.byTooltip('Banner ${i + 1}'));
      if (node.flagsCollection.isSelected == ui.Tristate.isTrue) {
        expect(active, -1, reason: 'only one dot may be active');
        active = i;
      }
    }
    return active;
  }

  testWidgets('Three real slides start on the unchanged engine banner',
      (t) async {
    final handle = t.ensureSemantics();
    await host(t);
    expect(find.byTooltip('Banner 1'), findsOneWidget);
    expect(find.byTooltip('Banner 2'), findsOneWidget);
    expect(find.byTooltip('Banner 3'), findsOneWidget);
    expect(find.byTooltip('Banner 4'), findsNothing);
    expect(shownImage(t), 'assets/images/revo_hero_engine.jpg');
    expect(find.text('Cứu hộ nhanh'), findsOneWidget);
    expect(find.text('có mặt kịp thời'), findsOneWidget);
    expect(find.text('Nhận đơn'), findsWidgets);
    expect(activeDot(t), 0);
    await shot(t, 'hero-1');
    handle.dispose();
  });

  testWidgets('Arrows move through all slides and wrap in both directions',
      (t) async {
    final handle = t.ensureSemantics();
    await host(t);
    const engine = 'assets/images/revo_hero_engine.jpg';
    const tools = 'assets/images/revo_hero_tools.jpg';
    const team = 'assets/images/revo_hero_teamwork.jpg';
    await tapTip(t, 'Banner tiếp theo');
    expect(shownImage(t), tools);
    expect(activeDot(t), 1);
    expect(find.text('Chủ động công việc'), findsOneWidget);
    await shot(t, 'hero-2');
    await tapTip(t, 'Banner tiếp theo');
    expect(shownImage(t), team);
    expect(activeDot(t), 2);
    expect(find.text('Sẵn sàng cứu hộ'), findsOneWidget);
    await shot(t, 'hero-3');
    await tapTip(t, 'Banner tiếp theo');
    expect(shownImage(t), engine);
    expect(activeDot(t), 0);
    await tapTip(t, 'Banner trước');
    expect(shownImage(t), team);
    expect(activeDot(t), 2);
    await tapTip(t, 'Banner trước');
    expect(shownImage(t), tools);
    await tapTip(t, 'Banner trước');
    expect(shownImage(t), engine);
    expect(activeDot(t), 0);
    handle.dispose();
  });

  testWidgets('Swipe and dots stay in sync with the arrows', (t) async {
    final handle = t.ensureSemantics();
    await host(t);
    await t.drag(
        find.byKey(const ValueKey('hero-pages')), const Offset(-300, 0));
    await t.pumpAndSettle();
    expect(activeDot(t), 1);
    await t.drag(
        find.byKey(const ValueKey('hero-pages')), const Offset(300, 0));
    await t.pumpAndSettle();
    expect(activeDot(t), 0);
    // Swipe backwards from the first slide wraps to the last.
    await t.drag(
        find.byKey(const ValueKey('hero-pages')), const Offset(300, 0));
    await t.pumpAndSettle();
    expect(activeDot(t), 2);
    await tapTip(t, 'Banner 1');
    expect(activeDot(t), 0);
    await tapTip(t, 'Banner 3');
    expect(activeDot(t), 2);
    await tapTip(t, 'Banner tiếp theo');
    expect(activeDot(t), 0);
    await tapTip(t, 'Banner 2');
    expect(activeDot(t), 1);
    handle.dispose();
  });

  testWidgets('Rapid arrow taps never stack animations or skip slides',
      (t) async {
    final handle = t.ensureSemantics();
    await host(t);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.byTooltip('Banner tiếp theo'));
      await t.pump(const Duration(milliseconds: 40));
    }
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(activeDot(t), 1);
    handle.dispose();
  });

  testWidgets('CTAs keep their actions and the rest of Home is unchanged',
      (t) async {
    await host(t);
    expect(find.byType(HomeServiceTile), findsNWidgets(4));
    expect(find.byType(AppBottomNav), findsOneWidget);
    await t.tap(find.descendant(of: hero, matching: find.text('Nhận đơn')));
    await t.pumpAndSettle();
    expect(find.byType(IncomingOrderPopup), findsOneWidget);
    expect(appState.activeOrder, isNull);
    await t.tap(find.text('Từ chối'));
    await t.pumpAndSettle();
    await tapTip(t, 'Banner tiếp theo');
    await t.tap(find.descendant(of: hero, matching: find.text('Đơn hàng')));
    await t.pumpAndSettle();
    expect(appState.tabIndex, 1);
    expect(appState.balance, 1250000);
    expect(appState.activeOrder, isNull);
  });

  for (final config in [
    (const Size(412, 915), 1.0),
    (const Size(412, 915), 1.3),
    (const Size(412, 915), 1.6),
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 1.3),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets(
        'Hero arrows fit, stay tappable and never cover CTAs ${config.$1} at ${config.$2}',
        (t) async {
      await host(t, size: config.$1, scale: config.$2);
      for (var slide = 0; slide < 3; slide++) {
        final tag = '${config.$1.width.toInt()}-${config.$2}-${slide + 1}';
        await shot(t, 'hero-$tag');
        final prev = t.getRect(find.byKey(const ValueKey('hero-prev')));
        final next = t.getRect(find.byKey(const ValueKey('hero-next')));
        expect(prev.width, greaterThanOrEqualTo(44));
        expect(next.height, greaterThanOrEqualTo(44));
        final visibleButtons = find
            .descendant(of: hero, matching: find.bySubtype<ButtonStyleButton>())
            .evaluate()
            .map((e) => t.getRect(find.byWidget(e.widget)))
            .where((r) =>
                r.left >= 0 &&
                r.right <= config.$1.width &&
                r != prev &&
                r != next);
        expect(visibleButtons, isNotEmpty);
        for (final r in visibleButtons) {
          expect(r.overlaps(prev), isFalse, reason: 'prev $prev covers CTA $r');
          expect(r.overlaps(next), isFalse, reason: 'next $next covers CTA $r');
        }
        expect(t.takeException(), isNull);
        await tapTip(t, 'Banner tiếp theo');
      }
      final clipped = <String>[];
      for (final e in find.byType(RichText).evaluate()) {
        final r = e.renderObject;
        if (r is RenderParagraph && r.didExceedMaxLines) {
          clipped.add(r.text.toPlainText());
        }
      }
      expect(clipped, isEmpty, reason: 'Truncated labels');
    });
  }
}
