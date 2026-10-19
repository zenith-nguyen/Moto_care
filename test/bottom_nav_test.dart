import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/mechanic_account_screen.dart';
import 'package:motocare_mechanic/screens/mechanic_home_screen.dart';
import 'package:motocare_mechanic/screens/mechanic_wallet_screen.dart';
import 'package:motocare_mechanic/screens/order_history_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';

void main() {
  final boundary = GlobalKey();
  setUp(() {
    appState.activeOrder = null;
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
    appState.setShowcaseOrders(false);
    appState.setTab(0);
  });

  Future<void> host(WidgetTester t,
      {Size size = const Size(412, 915), double scale = 1}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    t.view.padding = const FakeViewPadding(bottom: 24);
    t.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(t.view.reset);
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

  Finder pill(String label) => find.byKey(ValueKey('nav-pill-$label'));
  const labels = ['Trang chủ', 'Đơn hàng', 'Ví', 'Tài khoản'];

  testWidgets('A single floating capsule dock with side margins on every tab',
      (t) async {
    await host(t);
    for (var tab = 0; tab < 4; tab++) {
      appState.setTab(tab);
      await t.pumpAndSettle();
      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      final rect = t.getRect(find.byType(AppBottomNav));
      expect(rect.left, 0, reason: 'SafeArea wrapper spans the width');
      final dock = t.getRect(find
          .descendant(
              of: find.byType(AppBottomNav),
              matching: find.byType(DecoratedBox))
          .first);
      expect(dock.left, greaterThanOrEqualTo(12));
      expect(412 - dock.right, greaterThanOrEqualTo(12));
      // Gap above the system gesture area.
      expect(915 - dock.bottom, greaterThanOrEqualTo(24 + 8));
      final decoration = t
          .widget<DecoratedBox>(find
              .descendant(
                  of: find.byType(AppBottomNav),
                  matching: find.byType(DecoratedBox))
              .first)
          .decoration as BoxDecoration;
      expect(decoration.color, Colors.white);
      expect((decoration.borderRadius! as BorderRadius).topLeft.x,
          greaterThanOrEqualTo(30));
      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
      expect(decoration.gradient, isNull);
    }
  });

  testWidgets('Four tabs, one active at a time, brand colours and Montserrat',
      (t) async {
    await host(t);
    for (final l in labels) {
      expect(find.text(l), findsWidgets);
    }
    for (var tab = 0; tab < 4; tab++) {
      appState.setTab(tab);
      await t.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        final active = i == tab;
        final decoration = t
            .widget<AnimatedContainer>(pill(labels[i]))
            .decoration as BoxDecoration;
        expect(decoration.color,
            active ? const Color(0xFFEAF4FC) : Colors.transparent);
        final text = t.widget<Text>(find.descendant(
            of: find.byType(AppBottomNav), matching: find.text(labels[i])));
        expect(text.style!.color,
            active ? const Color(0xFF317CBB) : const Color(0xFF71839E));
        expect(text.style!.fontFamily, 'Montserrat');
        expect(
            text.style!.fontWeight, active ? FontWeight.w600 : FontWeight.w400);
        final icon = t.widget<Icon>(
            find.descendant(of: pill(labels[i]), matching: find.byType(Icon)));
        expect(icon.color, text.style!.color);
        expect(icon.size, 23);
      }
    }
  });

  testWidgets('Tabs switch, keep state and never touch orders or money',
      (t) async {
    final order = appState.acceptOffer(appState.nextOffer(serviceIndex: 0));
    final history = appState.history.length;
    final tx = appState.transactions.length;
    await host(t);
    for (final (label, type) in <(String, Type)>[
      ('Đơn hàng', OrderHistoryScreen),
      ('Ví', MechanicWalletScreen),
      ('Tài khoản', MechanicAccountScreen),
      ('Trang chủ', MechanicHomeScreen),
    ]) {
      await t.tap(find.descendant(
          of: find.byType(AppBottomNav), matching: find.text(label)));
      await t.pumpAndSettle();
      expect(find.byType(type), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);
    }
    expect(appState.tabIndex, 0);
    expect(appState.activeOrder, same(order));
    expect(appState.history.length, history);
    expect(appState.transactions.length, tx);
    expect(appState.balance, 1250000);
  });

  testWidgets('Dock does not hide the end of the scrolling content', (t) async {
    await host(t);
    for (final tab in [0, 1, 2]) {
      appState.setTab(tab);
      await t.pumpAndSettle();
      final scrollable = find
          .descendant(
              of: find.byType(IndexedStack), matching: find.byType(Scrollable))
          .evaluate()
          .firstWhere((e) =>
              e.renderObject!.attached &&
              (e.renderObject! as RenderBox).hasSize);
      final box = scrollable.renderObject! as RenderBox;
      final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
      final dockTop = t.getTopLeft(find.byType(AppBottomNav)).dy;
      expect(bottom, lessThanOrEqualTo(dockTop + 1),
          reason: 'tab $tab content ends above the dock');
    }
  });

  for (final config in [
    (const Size(412, 915), 1.0),
    (const Size(360, 780), 1.0),
    (const Size(320, 568), 1.0),
    (const Size(412, 915), 1.6),
    (const Size(320, 568), 1.3),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets('Dock fits without overflow ${config.$1} at ${config.$2}',
        (t) async {
      await host(t, size: config.$1, scale: config.$2);
      final tag = '${config.$1.width.toInt()}-${config.$2}';
      for (var tab = 0; tab < 4; tab++) {
        appState.setTab(tab);
        await t.pumpAndSettle();
        final dock = t.getRect(find
            .descendant(
                of: find.byType(AppBottomNav),
                matching: find.byType(DecoratedBox))
            .first);
        expect(dock.left, greaterThanOrEqualTo(12));
        expect(config.$1.width - dock.right, greaterThanOrEqualTo(12));
        expect(dock.bottom, lessThanOrEqualTo(config.$1.height - 24));
        expect(t.takeException(), isNull);
        await shot(t, 'dock-$tag-tab$tab');
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
