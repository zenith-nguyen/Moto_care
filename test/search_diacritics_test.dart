import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/home_catalog.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/ui.dart';

void main() {
  group('homeSearchKey', () {
    test('maps accented, upper-case and đ/Đ letters to plain ASCII', () {
      expect(homeSearchKey('Xẹp lốp'), 'xep lop');
      expect(homeSearchKey('XẸP LỐP'), 'xep lop');
      expect(homeSearchKey('Kích bình'), 'kich binh');
      expect(homeSearchKey('Hết xăng'), 'het xang');
      expect(homeSearchKey('Ngập nước'), 'ngap nuoc');
      expect(homeSearchKey('Sửa xe, Kéo xe'), 'sua xe, keo xe');
      expect(homeSearchKey('Nguyễn Tri Phương'), 'nguyen tri phuong');
      expect(homeSearchKey('đ'), 'd');
      expect(homeSearchKey('Đ'), 'd');
      expect(homeSearchKey('Đường Võ Văn Kiệt'), 'duong vo van kiet');
    });

    test('also handles decomposed (NFD) Unicode and is idempotent', () {
      // e + dot below + circumflex etc. as separate combining marks.
      expect(homeSearchKey('xẹp lốp'), 'xep lop');
      expect(homeSearchKey('Người'), 'nguoi');
      expect(homeSearchKey('Kéo xe'), 'keo xe');
      expect(homeSearchKey('xep lop'), 'xep lop');
      expect(homeSearchKey(homeSearchKey('Ngập nước')), 'ngap nuoc');
    });
  });

  group('orders search field', () {
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
      appState.setShowcaseOrders(true);
      appState.setTab(1);
    });
    tearDown(() => appState.setShowcaseOrders(false));

    Future<void> host(WidgetTester t) async {
      t.view.physicalSize = const Size(412, 2600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
          MaterialApp(theme: buildAppTheme(), home: const MechanicShell()));
      await t.pumpAndSettle();
    }

    Finder field() => find.byKey(const ValueKey('orders-search'));
    TextEditingController controller(WidgetTester t) =>
        t.widget<TextField>(field()).controller!;
    List<String> codes(WidgetTester t) => [
          for (final c in t.widgetList<ShadowCard>(find.byType(ShadowCard)))
            (c.key! as ValueKey<String>).value
        ];
    Future<void> type(WidgetTester t, String text) async {
      await t.enterText(field(), text);
      await t.pumpAndSettle();
    }

    testWidgets(
        'accented and plain input find the same orders and the field '
        'keeps exactly what was typed', (t) async {
      await host(t);
      for (final (typed, expected) in const [
        ('xẹp lốp', ['#DEMO-S001']),
        ('xep lop', ['#DEMO-S001']),
        ('XẸP LỐP', ['#DEMO-S001']),
        ('kích bình', ['#DEMO-S002']),
        ('kich binh', ['#DEMO-S002']),
        ('hết xăng', ['#DEMO-S003']),
        ('het xang', ['#DEMO-S003']),
        ('kéo xe', ['#DEMO-S004']),
        ('ngập nước', ['#DEMO-S005']),
        ('ngap nuoc', ['#DEMO-S005']),
        ('Nguyễn Tri Phương', ['#DEMO-S001']),
        ('nguyen tri phuong', ['#DEMO-S001']),
        ('Nguyễn Thị Minh Khai', ['#DEMO-S002']),
      ]) {
        await type(t, typed);
        expect(controller(t).text, typed, reason: 'field text for "$typed"');
        expect(codes(t), expected, reason: 'results for "$typed"');
      }
    });

    testWidgets('decomposed Unicode input is matched as well', (t) async {
      await host(t);
      await type(t, 'xẹp lốp');
      expect(codes(t), ['#DEMO-S001']);
      expect(controller(t).text, 'xẹp lốp');
    });

    testWidgets('đ and Đ behave like d and never crash or rewrite the field',
        (t) async {
      await host(t);
      await type(t, 'đ');
      final lower = codes(t);
      await type(t, 'Đ');
      expect(codes(t), lower);
      expect(controller(t).text, 'Đ');
      await type(t, 'd');
      expect(codes(t), lower);
      await type(t, 'đường');
      expect(controller(t).text, 'đường');
      expect(t.takeException(), isNull);
    });

    testWidgets('IME composing text and cursor are left untouched', (t) async {
      await host(t);
      await t.tap(field());
      await t.pumpAndSettle();
      // Telex-style: "xe" is still being composed, then becomes "xẹ".
      t.testTextInput.updateEditingValue(const TextEditingValue(
          text: 'xe',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 2)));
      await t.pumpAndSettle();
      expect(controller(t).value.composing, const TextRange(start: 0, end: 2));
      t.testTextInput.updateEditingValue(const TextEditingValue(
          text: 'xẹ',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 2)));
      await t.pumpAndSettle();
      expect(controller(t).text, 'xẹ');
      expect(controller(t).selection, const TextSelection.collapsed(offset: 2));
      expect(controller(t).value.composing, const TextRange(start: 0, end: 2));
      // Commit the rest of the word; focus stays on the field.
      t.testTextInput.updateEditingValue(const TextEditingValue(
          text: 'xẹp lốp',
          selection: TextSelection.collapsed(offset: 7),
          composing: TextRange.empty));
      await t.pumpAndSettle();
      expect(controller(t).text, 'xẹp lốp');
      expect(controller(t).selection, const TextSelection.collapsed(offset: 7));
      expect(t.widget<TextField>(field()).focusNode!.hasFocus, isTrue);
      expect(codes(t), ['#DEMO-S001']);
    });

    testWidgets(
        'search works on the real history when demo mode is off, '
        'and never mixes in the demo orders', (t) async {
      appState.setShowcaseOrders(false);
      await host(t);
      await type(t, 'xẹp lốp');
      expect(codes(t), ['#RVO2298', '#RVO2271']);
      await type(t, 'xep lop');
      expect(codes(t), ['#RVO2298', '#RVO2271']);
      await type(t, 'ngập nước');
      expect(codes(t), isEmpty);
      await type(t, 'hết xăng');
      expect(codes(t), ['#RVO2279']);
      // Switching the mode re-evaluates the same keyword on the other source.
      appState.setShowcaseOrders(true);
      await t.pumpAndSettle();
      expect(codes(t), ['#DEMO-S003']);
      await type(t, '');
      expect(codes(t), hasLength(5));
    });

    testWidgets('vehicle names, "đơn hàng" and sorting combine with search',
        (t) async {
      await host(t);
      await type(t, 'Yamaha Exciter');
      expect(codes(t), ['#DEMO-S001']);
      await type(t, 'yamaha');
      expect(codes(t), ['#DEMO-S001', '#DEMO-S003']);
      await t.tap(find.byKey(const ValueKey('orders-sort')));
      await t.pumpAndSettle();
      await t.tap(find.text('Cũ nhất').last);
      await t.pumpAndSettle();
      expect(codes(t), ['#DEMO-S003', '#DEMO-S001']);
      // "đ" is kept in the field and simply matches nothing here.
      await type(t, 'đơn hàng');
      expect(controller(t).text, 'đơn hàng');
      expect(codes(t), isEmpty);
    });

    testWidgets('clear button, filters and sort still combine correctly',
        (t) async {
      await host(t);
      await type(t, 'xẹp lốp');
      expect(codes(t), ['#DEMO-S001']);
      await t.tap(find.byTooltip('Xóa từ khóa'));
      await t.pumpAndSettle();
      expect(controller(t).text, isEmpty);
      expect(codes(t), hasLength(5));
      await t.tap(find.byKey(const ValueKey('orders-chip-cancelled')));
      await t.pumpAndSettle();
      await type(t, 'hết xăng');
      expect(codes(t), ['#DEMO-S003']);
      await type(t, 'kéo xe');
      expect(codes(t), isEmpty);
      await t.tap(find.byKey(const ValueKey('orders-chip-all')));
      await t.pumpAndSettle();
      expect(codes(t), ['#DEMO-S004']);
      // Data untouched.
      expect(appState.balance, 1250000);
      expect(appState.history.length, MockData.history().length);
    });
  });
}
