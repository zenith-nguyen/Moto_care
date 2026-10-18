import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revo/core/theme/admin_tokens.dart';
import 'package:revo/features/admin/theme/admin_theme.dart';
import 'package:revo/features/admin/widgets/admin_date_range_picker_dialog.dart';

Finder _day(int year, int month, int day) =>
    find.byKey(ValueKey('admin-date-$year-$month-$day'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester, {
  DateTimeRange? initial,
  DateTime? first,
  DateTime? last,
  DateTime? today,
  Size size = const Size(390, 844),
  double scale = 1,
  ValueChanged<DateTimeRange?>? onResult,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AdminTheme.light,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final selected = await showDialog<DateTimeRange>(
                  context: context,
                  builder: (_) => AdminDateRangePickerDialog(
                    firstDate: first ?? DateTime(2025),
                    lastDate: last ?? DateTime(2027, 12, 31),
                    currentDate: today ?? DateTime(2026, 10, 16),
                    initialDateRange: initial,
                  ),
                );
                onResult?.call(selected);
              },
              child: const Text('Chọn ngày'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Chọn ngày'));
}

void main() {
  testWidgets(
    'Header, weekdays and range use the requested Montserrat styles',
    (tester) async {
      await _open(
        tester,
        initial: DateTimeRange(
          start: DateTime(2026, 10, 14, 9),
          end: DateTime(2026, 10, 16, 22),
        ),
      );
      final label = tester.widget<Text>(find.text('14 thg 10 – 16 thg 10'));
      expect(label.style?.fontSize, 22);
      expect(label.style?.fontWeight, FontWeight.bold);
      expect(label.style?.color, AdminTokens.text);
      expect(label.style?.fontFamily, startsWith('Montserrat'));
      expect(
        tester.widget<Text>(find.text('Tháng 10, 2026')).style?.fontWeight,
        FontWeight.bold,
      );
      for (final day in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']) {
        final style = tester.widget<Text>(find.text(day)).style;
        expect(style?.fontSize, 13);
        expect(style?.fontWeight, FontWeight.w500);
        expect(style?.color, const Color(0xFF8E8E93));
      }
      for (final date in [14, 16]) {
        final text = tester.widget<Text>(
          find.descendant(
            of: _day(2026, 10, date),
            matching: find.byType(Text),
          ),
        );
        expect(text.style?.color, Colors.white);
        expect(text.style?.fontWeight, FontWeight.bold);
      }
      final middle = _day(2026, 10, 15);
      expect(
        tester
            .widget<Text>(
              find.descendant(of: middle, matching: find.byType(Text)),
            )
            .style
            ?.color,
        AdminTokens.primaryBlue,
      );
      expect(
        tester
            .widgetList<DecoratedBox>(
              find.descendant(of: middle, matching: find.byType(DecoratedBox)),
            )
            .any(
              (box) =>
                  (box.decoration as BoxDecoration).color ==
                  AdminTokens.activePill,
            ),
        isTrue,
      );
      expect(
        tester.getCenter(_day(2026, 10, 1)).dx,
        closeTo(tester.getCenter(find.text('T5')).dx, .1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final sameDay in [false, true]) {
    testWidgets(
      'Range can be selected ${sameDay ? 'on one day' : 'in reverse order'} before applying',
      (tester) async {
        DateTimeRange? result;
        await _open(tester, onResult: (value) => result = value);
        final apply = find.widgetWithText(TextButton, 'Áp dụng');
        expect(tester.widget<TextButton>(apply).onPressed, isNull);
        await _tap(tester, _day(2026, 10, sameDay ? 14 : 16));
        expect(tester.widget<TextButton>(apply).onPressed, isNull);
        expect(result, isNull);
        await _tap(tester, _day(2026, 10, 14));
        expect(tester.widget<TextButton>(apply).onPressed, isNotNull);
        expect(result, isNull);
        await _tap(tester, apply);
        expect(result?.start, DateTime(2026, 10, 14));
        expect(result?.end, DateTime(2026, 10, sameDay ? 14 : 16));
        expect(find.byType(AdminDateRangePickerDialog), findsNothing);
      },
    );
  }

  testWidgets(
    'Swiping left goes back; swiping right and the arrows go forward across years',
    (tester) async {
      await _open(tester, today: DateTime(2026, 1, 16));
      final calendar = find.byKey(const ValueKey('admin-date-calendar'));
      await tester.timedDrag(
        calendar,
        const Offset(-140, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tháng 12, 2025'), findsOneWidget);
      await tester.timedDrag(
        calendar,
        const Offset(140, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tháng 1, 2026'), findsOneWidget);
      await _tap(tester, find.byTooltip('Tháng sau'));
      expect(find.text('Tháng 2, 2026'), findsOneWidget);
      await _tap(tester, find.byTooltip('Tháng trước'));
      expect(find.text('Tháng 1, 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Leap days and calendar bounds prevent invalid selection and navigation',
    (tester) async {
      DateTimeRange? result;
      await _open(
        tester,
        first: DateTime(2024, 2, 28),
        last: DateTime(2024, 3, 1),
        today: DateTime(2024, 2, 29),
        onResult: (value) => result = value,
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
            )
            .onPressed,
        isNull,
      );
      await _tap(tester, _day(2024, 2, 27));
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Áp dụng'))
            .onPressed,
        isNull,
      );
      await _tap(tester, _day(2024, 2, 29));
      await _tap(tester, find.byTooltip('Tháng sau'));
      expect(find.text('Tháng 3, 2024'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
            )
            .onPressed,
        isNull,
      );
      await tester.drag(
        find.byKey(const ValueKey('admin-date-calendar')),
        const Offset(140, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tháng 3, 2024'), findsOneWidget);
      await _tap(tester, _day(2024, 3, 1));
      await _tap(tester, find.text('Áp dụng'));
      expect(result?.start, DateTime(2024, 2, 29));
      expect(result?.end, DateTime(2024, 3, 1));
    },
  );

  testWidgets(
    'Range survives month navigation and labels both years at New Year',
    (tester) async {
      DateTimeRange? result;
      await _open(
        tester,
        today: DateTime(2025, 12, 16),
        onResult: (value) => result = value,
      );
      await _tap(tester, _day(2025, 12, 31));
      await _tap(tester, find.byTooltip('Tháng sau'));
      await _tap(tester, _day(2026, 1, 2));
      expect(find.text('31 thg 12, 2025 – 2 thg 1, 2026'), findsOneWidget);
      await _tap(tester, find.text('Áp dụng'));
      expect(result?.start, DateTime(2025, 12, 31));
      expect(result?.end, DateTime(2026, 1, 2));
    },
  );

  testWidgets(
    'Closing discards a replacement draft instead of returning the initial range',
    (tester) async {
      final results = <DateTimeRange?>[];
      await _open(
        tester,
        initial: DateTimeRange(
          start: DateTime(2026, 10, 14),
          end: DateTime(2026, 10, 16),
        ),
        onResult: results.add,
      );
      await _tap(tester, _day(2026, 10, 12));
      expect(find.text('12 thg 10 – Ngày kết thúc'), findsOneWidget);
      await _tap(tester, find.byTooltip('Đóng'));
      expect(results, [null]);
      expect(find.byType(AdminDateRangePickerDialog), findsNothing);
    },
  );

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('Calendar and fixed Apply action fit $size with large text', (
      tester,
    ) async {
      DateTimeRange? result;
      await _open(
        tester,
        size: size,
        scale: 1.5,
        onResult: (value) => result = value,
      );
      expect(tester.takeException(), isNull);
      await _tap(tester, _day(2026, 10, 14));
      await _tap(tester, _day(2026, 10, 16));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Áp dụng'));
      expect(result?.start, DateTime(2026, 10, 14));
      expect(result?.end, DateTime(2026, 10, 16));
      expect(tester.takeException(), isNull);
    });
  }
}
