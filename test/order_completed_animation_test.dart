import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/order_completed_screen.dart';
import 'package:motocare_mechanic/screens/order_history_detail_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/utils/format.dart';

void main() {
  final boundary = GlobalKey();
  late OrderHistoryItem item;
  setUp(() {
    appState.activeOrder = null;
    appState.history
      ..clear()
      ..addAll(MockData.history());
    appState.transactions
      ..clear()
      ..addAll(MockData.transactions());
    appState.balance = 1250000;
    appState.setTab(2);
    item = appState.history.firstWhere((o) => o.code == '#RVO2298');
  });

  Future<void> host(WidgetTester t,
      {bool reduce = false,
      Size size = const Size(412, 915),
      double scale = 1}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  disableAnimations: reduce,
                  textScaler: TextScaler.linear(scale)),
              child: child!),
          home: Scaffold(
              body: Builder(
                  builder: (context) => Center(
                      child: TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      OrderCompletedScreen(item: item))),
                          child: const Text('open'))))),
        )));
    await t.tap(find.text('open'));
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

  Animation<double> scale(WidgetTester t) => t
      .widget<ScaleTransition>(find.byKey(const ValueKey('completed-circle')))
      .scale;
  double opacityOf(WidgetTester t, String text) => t
      .widget<FadeTransition>(find
          .ancestor(of: find.text(text), matching: find.byType(FadeTransition))
          .first)
      .opacity
      .value;
  final burst = find.byKey(const ValueKey('completed-burst'));

  testWidgets('Pop, bounce, burst, then titles and card follow the timeline',
      (t) async {
    await host(t);
    await t.pump(); // route built, t = 0
    await t.pump(const Duration(milliseconds: 16));
    expect(scale(t).value, inInclusiveRange(.64, .8));
    expect(opacityOf(t, 'Hoàn thành đơn hàng!'), 0);
    expect(opacityOf(t, 'Thu nhập'), 0);
    // ~180ms: circle at its peak (never beyond 1.08).
    await t.pump(const Duration(milliseconds: 170));
    expect(scale(t).value, inInclusiveRange(1.05, 1.0801));
    await shot(t, 'anim-180ms');
    // Burst is visible while it plays.
    expect(burst, findsOneWidget);
    // ~300ms: bouncing back toward 1.0; title is fading in.
    await t.pump(const Duration(milliseconds: 120));
    expect(scale(t).value, inInclusiveRange(.99, 1.08));
    expect(opacityOf(t, 'Hoàn thành đơn hàng!'), inExclusiveRange(0, 1));
    await shot(t, 'anim-300ms');
    // ~500ms: card entering, burst nearly gone.
    await t.pump(const Duration(milliseconds: 200));
    expect(opacityOf(t, 'Thu nhập'), inExclusiveRange(0, 1));
    // End of the timeline: everything settled, rays removed from the tree.
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    expect(scale(t).value, 1);
    expect(burst, findsNothing);
    expect(opacityOf(t, 'Hoàn thành đơn hàng!'), 1);
    expect(
        opacityOf(
            t, 'Cảm ơn bạn đã mang lại\ntrải nghiệm an toàn cho khách hàng.'),
        1);
    expect(opacityOf(t, 'Thu nhập'), 1);
    expect(opacityOf(t, 'Xem chi tiết'), 1);
    expect(find.text(formatVnd(item.earning)), findsOneWidget);
    expect(find.text('${item.customerRating!.toStringAsFixed(1)} '),
        findsOneWidget);
    await shot(t, 'anim-final');
    // No loop: nothing is scheduled any more.
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('Scale never exceeds 1.08 and the tick draws in', (t) async {
    await host(t);
    await t.pump();
    var peak = 0.0;
    for (var i = 0; i < 60; i++) {
      await t.pump(const Duration(milliseconds: 15));
      final v = scale(t).value;
      if (v > peak) peak = v;
      expect(v, lessThanOrEqualTo(1.0801));
      expect(v, greaterThanOrEqualTo(.64));
    }
    expect(peak, greaterThan(1.07));
    expect(scale(t).value, 1);
  });

  testWidgets('Replaying does not happen on rebuilds or text-scale changes',
      (t) async {
    await host(t);
    await t.pumpAndSettle();
    expect(burst, findsNothing);
    t.view.physicalSize = const Size(360, 800);
    await t.pump();
    appState.setTab(2);
    await t.pump();
    expect(burst, findsNothing);
    expect(scale(t).value, 1);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('Buttons work during the animation and nothing is re-completed',
      (t) async {
    final balance = appState.balance;
    final tx = appState.transactions.length;
    final history = appState.history.length;
    await host(t);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('Xem chi tiết'));
    await t.pumpAndSettle();
    expect(find.byType(OrderHistoryDetailScreen), findsOneWidget);
    expect(appState.balance, balance);
    expect(appState.transactions.length, tx);
    expect(appState.history.length, history);
    expect(appState.activeOrder, isNull);
  });

  testWidgets('Reduced motion shows the final state immediately', (t) async {
    await host(t, reduce: true);
    await t.pumpAndSettle();
    expect(scale(t).value, 1);
    expect(burst, findsNothing);
    expect(opacityOf(t, 'Hoàn thành đơn hàng!'), 1);
    expect(opacityOf(t, 'Thu nhập'), 1);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('Leaving the screen mid-animation disposes cleanly', (t) async {
    await host(t);
    await t.pump();
    await t.pump(const Duration(milliseconds: 150));
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.byType(OrderCompletedScreen), findsNothing);
  });

  for (final c in [
    (const Size(412, 915), 1.0),
    (const Size(360, 780), 1.3),
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets('No overflow mid and end of animation ${c.$1} at ${c.$2}',
        (t) async {
      await host(t, size: c.$1, scale: c.$2);
      await t.pump();
      await t.pump(const Duration(milliseconds: 250));
      expect(t.takeException(), isNull);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text(formatVnd(item.earning)), findsOneWidget);
    });
  }
}
