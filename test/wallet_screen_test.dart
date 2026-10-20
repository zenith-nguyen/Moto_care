import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/wallet_transaction_detail_screen.dart';
import 'package:motocare_mechanic/screens/weekly_summary_screen.dart';
import 'package:motocare_mechanic/screens/withdraw_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';

void main() {
  final boundary = GlobalKey();
  const navy = Color(0xFF172638);
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
    appState.setShowcaseOrders(false);
    appState.setTab(2);
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
  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(k(key));
    await t.pumpAndSettle();
    await t.tap(k(key));
    await t.pumpAndSettle();
  }

  testWidgets('Balance card is left-aligned with no empty space on the right',
      (t) async {
    await host(t);
    final card = t.getRect(find
        .ancestor(of: k('wallet-balance'), matching: find.byType(Container))
        .last);
    final balance = t.getRect(k('wallet-balance'));
    expect(balance.left - card.left, closeTo(20, 1));
    expect(find.text('Số dư khả dụng'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.text('Sẵn sàng cho các giao dịch của bạn'), findsOneWidget);
    expect(card.height, lessThan(150));
    expect(t.widget<Text>(k('wallet-balance')).data, '1.250.000đ');
  });

  testWidgets('Header, balance from AppState and brand colours', (t) async {
    await host(t);
    expect(find.text('Ví của tôi'), findsOneWidget);
    expect(
        find.text(
            'Quản lý số dư và theo dõi các giao dịch thu nhập từ công việc.'),
        findsOneWidget);
    final title = t.widget<Text>(find.text('Ví của tôi'));
    expect(title.style!.fontFamily, 'Montserrat');
    expect(title.style!.color, navy);
    expect(t.widget<Text>(k('wallet-balance')).data, '1.250.000đ');
    expect(t.widget<Text>(k('wallet-balance')).style!.color, Colors.white);
    // Emerald luxury card: deep green gradient, no flat brand blue.
    final card = t.widget<Container>(find
        .ancestor(of: k('wallet-balance'), matching: find.byType(Container))
        .last);
    final colors =
        ((card.decoration! as BoxDecoration).gradient! as LinearGradient)
            .colors;
    expect(colors.first, const Color(0xFF1F9877));
    expect(colors.last, const Color(0xFF05433F));
    expect(colors.contains(const Color(0xFF317CBB)), isFalse);
    // Decorative wallet art is present and the coin carries no glyph.
    expect(k('wallet-card-art'), findsOneWidget);
    expect(find.text('đ'), findsNothing);
    expect(find.text('Sẵn sàng cho các giao dịch của bạn'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
    await shot(t, 'wallet');
  });

  testWidgets('Balance shown is whatever AppState holds', (t) async {
    appState.balance = 987000;
    await host(t);
    expect(t.widget<Text>(k('wallet-balance')).data, '987.000đ');
    appState.balance = 1250000;
  });

  testWidgets('Exactly three quick actions on one row with equal sizes',
      (t) async {
    await host(t);
    for (final (key, title, sub) in const [
      ('wallet-action-topup', 'Nạp tiền', 'Qua ngân hàng'),
      ('wallet-action-withdraw', 'Rút tiền', 'Về tài khoản'),
      ('wallet-action-stats', 'Thống kê', 'Thu nhập'),
    ]) {
      expect(k(key), findsOneWidget);
      expect(find.descendant(of: k(key), matching: find.text(title)),
          findsOneWidget);
      expect(find.descendant(of: k(key), matching: find.text(sub)),
          findsOneWidget);
      final icon = t.widget<Icon>(
          find.descendant(of: k(key), matching: find.byType(Icon)));
      expect(icon.color, const Color(0xFF317CBB));
    }
    // The redundant "Lịch sử" tile is gone; the history section remains.
    expect(k('wallet-action-history'), findsNothing);
    expect(find.text('Xem giao dịch'), findsNothing);
    expect(find.text('Lịch sử giao dịch'), findsOneWidget);
    final r = [
      for (final key in [
        'wallet-action-topup',
        'wallet-action-withdraw',
        'wallet-action-stats'
      ])
        t.getRect(k(key))
    ];
    expect(r[0].top, r[1].top);
    expect(r[1].top, r[2].top);
    for (final x in r) {
      expect(x.width, closeTo(r[0].width, .01));
      expect(x.height, closeTo(r[0].height, .01));
    }
    expect(r[1].left - r[0].right, inInclusiveRange(10, 12));
    expect(r[2].left - r[1].right, inInclusiveRange(10, 12));
  });

  testWidgets(
      'Withdraw buttons open the existing flow; stats opens summary; '
      'top-up is honestly unavailable and moves no money', (t) async {
    final tx = appState.transactions.length;
    await host(t);
    // The duplicate button inside the blue balance card is gone.
    expect(k('wallet-withdraw'), findsNothing);
    expect(
        find.descendant(
            of: find
                .ancestor(
                    of: k('wallet-balance'), matching: find.byType(Container))
                .last,
            matching: find.text('Rút tiền')),
        findsNothing);
    expect(find.text('Rút tiền'), findsOneWidget); // only the quick action
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    await tapKey(t, 'wallet-action-withdraw');
    expect(find.byType(WithdrawScreen), findsOneWidget);
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    await tapKey(t, 'wallet-action-stats');
    expect(find.byType(WeeklySummaryScreen), findsOneWidget);
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    // The header no longer carries a duplicate statistics button.
    expect(find.byTooltip('Tổng kết tuần'), findsNothing);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    await tapKey(t, 'wallet-action-topup');
    expect(find.textContaining('Nạp tiền chưa khả dụng'), findsOneWidget);
    expect(appState.balance, 1250000);
    expect(appState.transactions.length, tx);
  });

  testWidgets('Transactions come from AppState; amounts are navy; kinds differ',
      (t) async {
    await host(t);
    final all = appState.transactions;
    for (final tx in all) {
      final amount = t.widget<Text>(k('wallet-amount-${tx.txnId}'));
      expect(amount.style!.color, navy, reason: tx.txnId);
      expect(amount.style!.fontFamily, 'Montserrat');
      expect(amount.data!.startsWith(tx.isCredit ? '+ ' : '- '), isTrue);
    }
    expect(find.text('Rút tiền · Đang xử lý'), findsOneWidget);
    expect(find.text('Rút tiền thành công'), findsOneWidget);
    expect(find.text('Hoàn thành đơn #RVO2298'), findsOneWidget);
    expect(find.text('Hoàn thành đơn #RVO2287'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.north_east_rounded), findsNWidgets(2));
    // The pending withdrawal stays pending.
    expect(all.firstWhere((x) => x.code == '#RT0032').withdrawStatus,
        WithdrawStatus.pending);
  });

  testWidgets('Sort by time works and changes no data', (t) async {
    await host(t);
    List<String> order() => [
          for (final tx in appState.transactions)
            if (k('wallet-tx-${tx.txnId}').evaluate().isNotEmpty) tx.txnId
        ];
    double top(String id) => t.getTopLeft(k('wallet-tx-$id')).dy;
    final ids = appState.transactions.map((e) => e.txnId).toList();
    final newest = [...ids]..sort((a, b) => top(a).compareTo(top(b)));
    expect(newest.first, 'TX-88190');
    final before = [...appState.transactions.map((e) => e.txnId)];
    await t.ensureVisible(k('wallet-sort'));
    await t.tap(k('wallet-sort'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cũ nhất').last);
    await t.pumpAndSettle();
    final oldest = [...ids]..sort((a, b) => top(a).compareTo(top(b)));
    expect(oldest, newest.reversed.toList());
    expect(appState.transactions.map((e) => e.txnId), before);
    expect(order(), isNotEmpty);
    expect(appState.balance, 1250000);
  });

  testWidgets('Opening a transaction shows its own detail and changes nothing',
      (t) async {
    final tx = appState.transactions.length;
    await host(t);
    final target =
        appState.transactions.firstWhere((x) => x.code == '#RVO2287');
    await t.ensureVisible(k('wallet-tx-${target.txnId}'));
    await t.pumpAndSettle();
    await t.tap(k('wallet-tx-${target.txnId}'));
    await t.pumpAndSettle();
    expect(
        t
            .widget<WalletTransactionDetailScreen>(
                find.byType(WalletTransactionDetailScreen))
            .tx
            .txnId,
        target.txnId);
    expect(appState.balance, 1250000);
    expect(appState.transactions.length, tx);
  });

  for (final config in [
    (const Size(412, 915), 1.0),
    (const Size(412, 915), 1.3),
    (const Size(412, 915), 1.6),
    (const Size(360, 780), 1.0),
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 1.3),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets('Wallet fits without overflow ${config.$1} at ${config.$2}',
        (t) async {
      await host(t, size: config.$1, scale: config.$2);
      final tag = '${config.$1.width.toInt()}-${config.$2}';
      await shot(t, 'wallet-$tag-top');
      await t.scrollUntilVisible(k('wallet-action-topup'), 120,
          scrollable: find.byType(Scrollable).first);
      await t.pumpAndSettle();
      final tiles = [
        for (final key in [
          'wallet-action-topup',
          'wallet-action-withdraw',
          'wallet-action-stats'
        ])
          t.getRect(k(key))
      ];
      expect(tiles[0].top, tiles[2].top, reason: 'three tiles on one row');
      expect(tiles[0].width, closeTo(tiles[2].width, .01));
      expect(tiles[0].height, closeTo(tiles[2].height, .01));
      await t.drag(find.byType(ListView).first, const Offset(0, -2000));
      await t.pumpAndSettle();
      await shot(t, 'wallet-$tag-bottom');
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
