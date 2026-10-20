import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/order_history_detail_screen.dart';
import 'package:motocare_mechanic/screens/wallet_transaction_detail_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/utils/format.dart';

void main() {
  setUp(() {
    appState.history
      ..clear()
      ..addAll(MockData.history());
    appState.transactions
      ..clear()
      ..addAll(MockData.transactions());
    appState.balance = 1250000;
  });

  test('each completed order has its own customer, avatar and phone', () {
    final a = appState.history.firstWhere((o) => o.code == '#RVO2298');
    final b = appState.history.firstWhere((o) => o.code == '#RVO2287');
    expect(
        [a.customerName, initialsOf(a.customerName)], ['Trần Văn Khách', 'TK']);
    expect(
        [b.customerName, initialsOf(b.customerName)], ['Lê Minh Quân', 'LQ']);
    expect(a.customerPhone, isNot(b.customerPhone));
    // The two orders no longer share a customer.
    expect(a.customerName, isNot(b.customerName));
    // Untouched order data.
    expect(
        [a.issue, a.vehicle, a.earning], ['Xẹp lốp', 'Honda Vision', 112000]);
    expect(
        [b.issue, b.vehicle, b.earning], ['Chết máy', 'Toyota Vios', 141000]);
  });

  test('wallet transactions agree with their order customers', () {
    for (final o in appState.history.where((o) => o.earning > 0)) {
      final tx = appState.transactions.firstWhere((t) => t.orderCode == o.code);
      expect(tx.customerName, o.customerName, reason: o.code);
      expect(tx.customerPhone, o.customerPhone, reason: o.code);
      expect(tx.amount, o.earning, reason: o.code);
    }
  });

  test('other orders are unchanged', () {
    expect(
        MockData.offers.map((e) => e.customerName), ['Thùy An', 'Lê Thị Hạnh']);
    expect(
        appState.history
            .where((o) => o.code == '#RVO2279' || o.code == '#RVO2271')
            .map((o) => o.customerName),
        ['Phạm Đức Anh', 'Phạm Đức Anh']);
    expect(appState.showcaseOrders.map((o) => o.customerName), [
      'Lê Thị Hạnh',
      'Thùy An',
      'Phạm Đức Anh',
      'Trần Văn Khách',
      'Trần Văn Khách'
    ]);
  });

  Future<void> host(WidgetTester t, Widget page) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(theme: buildAppTheme(), home: page));
    await t.pumpAndSettle();
  }

  testWidgets('order detail shows the right customer and avatar per order',
      (t) async {
    for (final (code, name, initials) in const [
      ('#RVO2298', 'Trần Văn Khách', 'TK'),
      ('#RVO2287', 'Lê Minh Quân', 'LQ'),
    ]) {
      await host(
          t,
          OrderHistoryDetailScreen(
              item: appState.history.firstWhere((o) => o.code == code)));
      expect(find.text(name), findsOneWidget, reason: code);
      expect(find.text(initials), findsOneWidget, reason: code);
      expect(find.text(code), findsOneWidget);
    }
    expect(find.text('Trần Văn Khách'), findsNothing);
  });

  testWidgets('wallet transaction detail uses the same per-order customer',
      (t) async {
    for (final (code, name) in const [
      ('#RVO2298', 'Trần Văn Khách'),
      ('#RVO2287', 'Lê Minh Quân'),
    ]) {
      await host(
          t,
          WalletTransactionDetailScreen(
              tx: appState.transactions
                  .firstWhere((x) => x.orderCode == code)));
      await t.pumpAndSettle();
      expect(find.text(name), findsOneWidget, reason: code);
    }
    expect(appState.balance, 1250000);
  });
}
