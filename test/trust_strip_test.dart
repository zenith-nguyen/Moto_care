import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/weekly_summary_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';

void main() {
  final boundary = GlobalKey();
  setUp(() {
    appState.history
      ..clear()
      ..addAll(MockData.history());
    appState.transactions
      ..clear()
      ..addAll(MockData.transactions());
    appState.balance = 1250000;
  });

  Future<void> host(WidgetTester t, Size size, double scale) async {
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
          home: const WeeklySummaryScreen(),
        )));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
        find.byKey(const ValueKey('weekly-trust-strip')), 200,
        scrollable: find.byType(Scrollable).first);
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

  const labels = ['Uy tín', 'Tiến trình', 'Minh bạch', 'Hỗ trợ'];
  const icons = [
    Icons.verified_user_outlined,
    Icons.visibility_outlined,
    Icons.lock_outline,
    Icons.headset_mic_outlined
  ];
  final strip = find.byKey(const ValueKey('weekly-trust-strip'));

  testWidgets('Same four items, bigger navy Montserrat Medium text, blue icons',
      (t) async {
    await host(t, const Size(412, 915), 1);
    for (var i = 0; i < 4; i++) {
      final text = t.widget<Text>(
          find.descendant(of: strip, matching: find.text(labels[i])));
      expect(text.style!.fontSize, 13);
      expect(text.style!.fontWeight, FontWeight.w500);
      expect(text.style!.fontFamily, 'Montserrat');
      expect(text.style!.color, const Color(0xFF172638));
      final icon = t.widget<Icon>(
          find.descendant(of: strip, matching: find.byIcon(icons[i])));
      expect(icon.size, 20);
      expect(icon.color, const Color(0xFF317CBB));
    }
    expect(find.descendant(of: strip, matching: find.byType(VerticalDivider)),
        findsNWidgets(3));
    // Display only: nothing tappable inside the strip.
    expect(find.descendant(of: strip, matching: find.byType(InkWell)),
        findsNothing);
    expect(find.descendant(of: strip, matching: find.byType(TextButton)),
        findsNothing);
    // Not too tall.
    expect(t.getSize(strip).height, lessThan(80));
    await shot(t, 'trust-412');
  });

  testWidgets('Four equal columns, icon and text centred', (t) async {
    await host(t, const Size(412, 915), 1);
    final rects = [
      for (final l in labels)
        t.getRect(find.descendant(of: strip, matching: find.text(l)))
    ];
    final iconRects = [
      for (final i in icons)
        t.getRect(find.descendant(of: strip, matching: find.byIcon(i)))
    ];
    for (var i = 0; i < 4; i++) {
      // Icon centre and text centre share the same vertical band / column.
      expect(
          (iconRects[i].center.dx - rects[i].center.dx).abs() < 2 ||
              (iconRects[i].center.dy - rects[i].center.dy).abs() < 2,
          isTrue);
      final gap = rects[i].top - iconRects[i].bottom;
      final inlineGap = rects[i].left - iconRects[i].right;
      expect(gap >= 5 && gap <= 9 || inlineGap >= 6 && inlineGap <= 8, isTrue,
          reason: 'gap between icon and label');
    }
    final centres = rects.map((r) => r.center.dx).toList();
    for (var i = 1; i < 4; i++) {
      expect(centres[i] - centres[i - 1], closeTo(centres[1] - centres[0], 3));
    }
  });

  for (final c in [
    (const Size(412, 915), 1.0),
    (const Size(360, 780), 1.0),
    (const Size(320, 568), 1.0),
    (const Size(412, 915), 1.3),
    (const Size(360, 780), 1.6),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets('Fits without clipping ${c.$1} at ${c.$2}', (t) async {
      await host(t, c.$1, c.$2);
      expect(t.takeException(), isNull);
      for (final l in labels) {
        final r = t.getRect(find.descendant(of: strip, matching: find.text(l)));
        expect(r.left, greaterThanOrEqualTo(t.getRect(strip).left));
        expect(r.right, lessThanOrEqualTo(t.getRect(strip).right));
        final p = t.renderObject<RenderParagraph>(
            find.descendant(of: strip, matching: find.text(l)));
        expect(p.didExceedMaxLines, isFalse);
        // Real font size is not shrunk.
        expect(
            t
                .widget<Text>(
                    find.descendant(of: strip, matching: find.text(l)))
                .style!
                .fontSize,
            13);
      }
      await shot(t, 'trust-${c.$1.width.toInt()}-${c.$2}');
    });
  }
}
