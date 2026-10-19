import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/screens/terms_and_commitment_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';

void main() {
  final boundary = GlobalKey();
  bool? result;
  var opened = false;

  Future<void> host(WidgetTester t,
      {Size size = const Size(412, 915),
      double scale = 1,
      bool readOnly = false}) async {
    result = null;
    opened = false;
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: Builder(
              builder: (context) => Scaffold(
                  body: Center(
                      child: TextButton(
                          onPressed: () async {
                            opened = true;
                            result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                    builder: (_) => TermsAndCommitmentScreen(
                                        readOnly: readOnly)));
                          },
                          child: const Text('open'))))),
        )));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.byType(TermsAndCommitmentScreen), findsOneWidget);
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

  Finder k(String key) => find.byKey(ValueKey(key));

  FilledButton agree(WidgetTester t) =>
      t.widget<FilledButton>(k('terms-agree'));

  testWidgets('Four plain numbered items; blue numbers, no cards or badges',
      (t) async {
    await host(t);
    expect(find.text('Điều khoản & cam kết'), findsOneWidget);
    expect(
        find.text(
            'Để cùng xây dựng cộng đồng thợ uy tín và chuyên nghiệp, anh vui lòng đọc kỹ các cam kết dưới đây trước khi nhận đơn.'),
        findsOneWidget);
    const expected = [
      (
        'Tư cách và trách nhiệm',
        'Cung cấp thông tin chính xác, giấy tờ hợp lệ và chịu trách nhiệm về chất lượng dịch vụ.'
      ),
      (
        'An toàn và chuyên nghiệp',
        'Tuân thủ quy trình cứu hộ, bảo đảm an toàn cho khách hàng và phương tiện.'
      ),
      (
        'Thanh toán và chi phí',
        'Báo rõ chi phí trước khi sửa. Chỉ làm hạng mục phát sinh khi khách đã đồng ý.'
      ),
      (
        'Bảo mật thông tin',
        'Không chia sẻ thông tin cá nhân, vị trí hoặc dữ liệu của khách hàng cho bên thứ ba.'
      ),
    ];
    expect(k('term-4'), findsNothing);
    for (var i = 0; i < expected.length; i++) {
      final row = k('term-$i');
      expect(row, findsOneWidget);
      expect(find.descendant(of: row, matching: find.text(expected[i].$1)),
          findsOneWidget);
      expect(find.descendant(of: row, matching: find.text(expected[i].$2)),
          findsOneWidget);
      // Number: plain #317CBB text, a little larger than the title, same line.
      final n = find.descendant(of: row, matching: find.text('${i + 1}'));
      final ns = t.widget<Text>(n).style!;
      final ts = t.widget<Text>(find.text(expected[i].$1)).style!;
      expect(ns.color, const Color(0xFF317CBB));
      expect(ns.fontFamily, 'Montserrat');
      expect(ns.fontWeight, FontWeight.w700);
      expect(ns.fontSize!, greaterThan(ts.fontSize!));
      expect(t.getRect(n).center.dy,
          closeTo(t.getRect(find.text(expected[i].$1)).center.dy, 2));
      // No card frame, circle, shadow or icon.
      expect(
          find.descendant(
              of: row,
              matching: find.byWidgetPredicate(
                  (w) => w is DecoratedBox || w is Card || w is Icon)),
          findsNothing);
    }
    expect(t.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
        Colors.white);
    await shot(t, 'terms-unchecked');
  });

  testWidgets('Fonts and colours', (t) async {
    await host(t);
    final title = t.widget<Text>(find.text('Điều khoản & cam kết')).style!;
    expect(title.fontFamily, 'Montserrat');
    expect(title.fontWeight, FontWeight.w700);
    expect(title.color, const Color(0xFF000000));
    final intro = t
        .widget<Text>(find.textContaining('Để cùng xây dựng cộng đồng'))
        .style!;
    expect(intro.fontFamily, 'Montserrat');
    expect(intro.color, const Color(0xFF6B7280));
    final item = t.widget<Text>(find.text('Tư cách và trách nhiệm')).style!;
    expect(item.color, const Color(0xFF000000));
    expect(
        t
            .widget<Text>(find.textContaining('Cung cấp thông tin chính xác'))
            .style!
            .color,
        const Color(0xFF6B7280));
    final label = t
        .widget<Text>(find
            .text('Tôi đã đọc và đồng ý với các điều khoản, cam kết ở trên.'))
        .style!;
    expect(label.color, const Color(0xFF000000));
    expect(label.fontFamily, 'Montserrat');
    expect(
        find.descendant(
            of: k('terms-agree'),
            matching: find.byWidgetPredicate((w) =>
                w is DecoratedBox &&
                (w.decoration as BoxDecoration).gradient != null)),
        findsNothing);
  });

  testWidgets('Checkbox starts empty; Đồng ý disabled, then #317CBB',
      (t) async {
    await host(t);
    BoxDecoration box() =>
        t.widget<AnimatedContainer>(k('terms-box')).decoration!
            as BoxDecoration;
    expect(box().color, Colors.white);
    expect((box().border! as Border).top.color, const Color(0xFF9CA3AF));
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(agree(t).onPressed, isNull);
    expect(agree(t).style!.backgroundColor!.resolve({WidgetState.disabled}),
        const Color(0xFFDDE3EA));
    await t.tap(find.text('Đồng ý'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(result, isNull);
    expect(find.byType(TermsAndCommitmentScreen), findsOneWidget);

    await t.tap(k('terms-consent'));
    await t.pumpAndSettle();
    expect(box().color, const Color(0xFF317CBB));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(agree(t).onPressed, isNotNull);
    expect(
        agree(t).style!.backgroundColor!.resolve({}), const Color(0xFF317CBB));
    expect(t.widget<Text>(find.text('Đồng ý')).style!.color, Colors.white);
    await shot(t, 'terms-checked');

    await t.tap(
        find.text('Tôi đã đọc và đồng ý với các điều khoản, cam kết ở trên.'));
    await t.pumpAndSettle();
    expect(agree(t).onPressed, isNull);
    expect(box().color, Colors.white);
    expect(result, isNull, reason: 'ticking alone records nothing');
  });

  testWidgets('A fresh visit is never pre-ticked, even after consenting once',
      (t) async {
    await host(t);
    await t.tap(k('terms-consent'));
    await t.pumpAndSettle();
    await t.tap(k('terms-agree'));
    await t.pumpAndSettle();
    expect(result, isTrue);
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(agree(t).onPressed, isNull);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('Consent and button stay reachable on a small, large-text screen',
      (t) async {
    await host(t, size: const Size(320, 568), scale: 1.6);
    final btn = t.getRect(k('terms-agree'));
    expect(btn.bottom, lessThanOrEqualTo(568));
    expect(t.getRect(k('terms-consent')).bottom, lessThan(btn.top));
    await t.scrollUntilVisible(k('term-3'), 150,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    expect(t.getRect(k('term-3')).bottom, lessThanOrEqualTo(btn.top + 1));
  });

  testWidgets('Đồng ý returns consent and touches no app data', (t) async {
    final balance = appState.balance;
    final history = appState.history.length;
    await host(t);
    await t.tap(k('terms-consent'));
    await t.pumpAndSettle();
    await t.tap(k('terms-agree'));
    await t.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byType(TermsAndCommitmentScreen), findsNothing);
    expect(appState.balance, balance);
    expect(appState.history.length, history);
  });

  testWidgets('Back returns without consent', (t) async {
    await host(t);
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    expect(opened, isTrue);
    expect(result, isNull);
    expect(find.byType(TermsAndCommitmentScreen), findsNothing);
  });

  testWidgets('Read-only entry uses the same Đồng ý flow, never "Đã hiểu"',
      (t) async {
    await host(t, readOnly: true);
    expect(find.text('Đã hiểu'), findsNothing);
    expect(agree(t).onPressed, isNull);
    await t.tap(k('terms-consent'));
    await t.pumpAndSettle();
    await t.tap(find.text('Đồng ý'));
    await t.pumpAndSettle();
    expect(result, isTrue);
  });

  for (final config in [
    (const Size(320, 568), 1.0),
    (const Size(360, 780), 1.3),
    (const Size(393, 851), 1.0),
    (const Size(412, 915), 1.6),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets('Terms fits without overflow ${config.$1} at ${config.$2}',
        (t) async {
      await host(t, size: config.$1, scale: config.$2);
      await t.scrollUntilVisible(k('term-3'), 150,
          scrollable: find.byType(Scrollable).first);
      await t.pumpAndSettle();
      await t.tap(k('terms-consent'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
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
