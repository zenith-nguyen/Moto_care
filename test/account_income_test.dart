import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/mechanic_account_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/utils/format.dart';

void main() {
  setUp(() {
    appState.transactions
      ..clear()
      ..addAll(MockData.transactions());
    appState.balance = 1250000;
  });

  Future<void> host(WidgetTester t,
      {Size size = const Size(412, 915), double scale = 1}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        builder: (c, child) => MediaQuery(
            data:
                MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: const Scaffold(body: MechanicAccountScreen())));
    await t.pumpAndSettle();
  }

  testWidgets('Monthly income shows the full amount from the ledger, in navy',
      (t) async {
    await host(t);
    final income = appState.monthIncome;
    expect(income, greaterThan(0));
    final text = formatVnd(income);
    expect(text, matches(RegExp(r'^\d{1,3}(\.\d{3})*đ$')));
    expect(find.text(text), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d[kKM]\b')), findsNothing);
    final style = t.widget<Text>(find.text(text)).style!;
    expect(style.fontFamily, 'Montserrat');
    expect(style.color, const Color(0xFF172638));
    expect(find.text('Thu nhập tháng'), findsOneWidget);
    expect(find.text('Đơn hoàn thành'), findsOneWidget);
    expect(find.text('Điểm đánh giá'), findsOneWidget);
    // Follows the ledger: no hardcoded value.
    appState.transactions.clear();
    appState.setTab(3);
    appState.notifyListeners();
    await t.pumpAndSettle();
    expect(find.text('0đ'), findsOneWidget);
    expect(appState.balance, 1250000);
  });

  for (final c in [(const Size(320, 568), 1.6), (const Size(412, 915), 1.0)]) {
    testWidgets('Stats row does not overflow ${c.$1} at ${c.$2}', (t) async {
      await host(t, size: c.$1, scale: c.$2);
      expect(t.takeException(), isNull);
      expect(find.text(formatVnd(appState.monthIncome)), findsOneWidget);
    });
  }
}
