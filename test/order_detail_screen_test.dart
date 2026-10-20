import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/order_chat_screen.dart';
import 'package:motocare_mechanic/screens/order_history_detail_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/utils/format.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';

void main() {
  final boundary = GlobalKey();
  const navy = Color(0xFF172638);
  const blue = Color(0xFF317CBB);
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
    appState.setShowcaseOrders(false);
    appState.setTab(0);
  });

  OrderHistoryItem showcase(String code) =>
      appState.showcaseOrders.firstWhere((o) => o.code == code);
  OrderHistoryItem real(String code) =>
      appState.history.firstWhere((o) => o.code == code);

  Future<void> host(WidgetTester t, Widget page,
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
          home: page,
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

  Finder inWalletButton(Finder f) => find.descendant(
      of: find.byKey(const ValueKey('detail-wallet')), matching: f);

  testWidgets('Completed demo order renders the reference layout from its data',
      (t) async {
    final item = showcase('#DEMO-S001');
    await host(t, OrderHistoryDetailScreen(item: item));
    expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
    expect(find.text('Hoàn thành'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text(formatDayTime(item.time)), findsOneWidget);
    expect(find.text('Lê Thị Hạnh'), findsOneWidget);
    expect(find.text('#DEMO-S001'), findsOneWidget);
    expect(find.text('LH'), findsOneWidget);
    expect(find.text('Xe máy'), findsOneWidget);
    expect(find.text('Xẹp lốp'), findsOneWidget);
    expect(find.text('56 Nguyễn Tri Phương, P.4, Q.10'), findsOneWidget);
    expect(find.byIcon(Icons.two_wheeler_rounded), findsOneWidget);
    expect(find.text('Thu nhập'), findsOneWidget);
    expect(find.text('Thông tin bổ sung'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    await shot(t, 'detail-S001');
  });

  testWidgets('Income comes from the order and is navy Montserrat bold',
      (t) async {
    for (final code in ['#DEMO-S001', '#DEMO-S002', '#DEMO-S004']) {
      final item = showcase(code);
      await host(t, OrderHistoryDetailScreen(item: item));
      final amount =
          t.widget<Text>(find.byKey(const ValueKey('detail-income-amount')));
      expect(amount.data, formatVnd(item.earning), reason: code);
      expect(amount.style!.color, navy);
      expect(amount.style!.fontFamily, 'Montserrat');
      expect(amount.style!.fontWeight, FontWeight.w700);
      expect(amount.style!.color, isNot(blue));
    }
    expect(
        t.widget<Icon>(find.byKey(const ValueKey('detail-income-icon'))).color,
        const Color(0xFF12A15B));
  });

  testWidgets('Xem trong ví keeps icon, text and chevron in #317CBB',
      (t) async {
    await host(t, OrderHistoryDetailScreen(item: real('#RVO2298')));
    final button = find.byKey(const ValueKey('detail-wallet'));
    expect(button, findsOneWidget);
    final icons =
        t.widgetList<Icon>(inWalletButton(find.byType(Icon))).toList();
    expect(icons.map((i) => i.icon),
        [Icons.account_balance_wallet_outlined, Icons.chevron_right_rounded]);
    expect(icons.every((i) => i.color == blue), isTrue);
    final text = t.widget<Text>(inWalletButton(find.text('Xem trong ví')));
    expect(text.style!.color, blue);
    expect(text.style!.fontFamily, 'Montserrat');
    // White action card, not a filled button.
    final material = t.widget<Material>(
        find.ancestor(of: button, matching: find.byType(Material)).first);
    expect(material.color, Colors.white);
  });

  testWidgets('Wallet link opens the wallet only when a transaction exists',
      (t) async {
    final tx = appState.transactions.length;
    await host(t, const MechanicShell());
    appState.setTab(1);
    await t.pumpAndSettle();
    Navigator.of(t.element(find.byType(MechanicShell))).push(MaterialPageRoute(
        builder: (_) => OrderHistoryDetailScreen(item: real('#RVO2298'))));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('detail-wallet')));
    await t.pumpAndSettle();
    expect(find.byType(OrderHistoryDetailScreen), findsNothing);
    expect(appState.tabIndex, 2);
    expect(appState.transactions.length, tx);
    expect(appState.balance, 1250000);
  });

  testWidgets('Showcase orders explain they are not in the wallet', (t) async {
    final tx = appState.transactions.length;
    await host(t, OrderHistoryDetailScreen(item: showcase('#DEMO-S002')));
    await t.tap(find.byKey(const ValueKey('detail-wallet')));
    await t.pumpAndSettle();
    expect(find.byType(OrderHistoryDetailScreen), findsOneWidget);
    expect(find.textContaining('không ghi vào Ví'), findsOneWidget);
    expect(appState.transactions.length, tx);
    expect(appState.balance, 1250000);
    expect(appState.tabIndex, 0);
  });

  testWidgets('Rating card shows real data only; extra info is its own card',
      (t) async {
    final rated = real('#RVO2298');
    await host(t, OrderHistoryDetailScreen(item: rated));
    expect(find.text('Đánh giá từ khách'), findsOneWidget);
    expect(find.text('${rated.customerRating!.toStringAsFixed(1)} '),
        findsOneWidget);
    expect(find.text('“${rated.customerReview}”'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(t.widget<Icon>(find.byIcon(Icons.star_rounded)).color,
        const Color(0xFFFFA81F));
    // Extra info: its own white card with a document icon and chevron.
    final extra = find.byKey(const ValueKey('detail-extra'));
    expect(
        find.descendant(
            of: extra, matching: find.byIcon(Icons.description_outlined)),
        findsOneWidget);
    expect(find.text('Thông tin bổ sung'), findsOneWidget);
    await shot(t, 'detail-RVO2298');
    // No fabricated rating on orders without one.
    await host(t, OrderHistoryDetailScreen(item: showcase('#DEMO-S002')));
    expect(find.text('Đánh giá từ khách'), findsNothing);
  });

  testWidgets('Cancelled orders show no income or wallet link', (t) async {
    final item = showcase('#DEMO-S003');
    await host(t, OrderHistoryDetailScreen(item: item));
    expect(find.text('Đã hủy'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-income')), findsNothing);
    expect(find.byKey(const ValueKey('detail-wallet')), findsNothing);
    expect(find.text('Hết xăng'), findsOneWidget);
  });

  testWidgets('Extra info expands, chat opens read-only and Back pops',
      (t) async {
    final item = real('#RVO2287');
    await host(t, const Scaffold());
    Navigator.of(t.element(find.byType(Scaffold))).push(MaterialPageRoute(
        builder: (_) => OrderHistoryDetailScreen(item: item)));
    await t.pumpAndSettle();
    final collapsed =
        t.getSize(find.byKey(const ValueKey('detail-extra'))).height;
    await t.tap(find.byKey(const ValueKey('detail-extra')));
    await t.pumpAndSettle();
    expect(find.text('Biển số'), findsOneWidget);
    expect(find.text('Chiết khấu'), findsOneWidget);
    expect(t.getSize(find.byKey(const ValueKey('detail-extra'))).height,
        greaterThan(collapsed + 100));
    await t.tap(find.text('Thông tin bổ sung'));
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const ValueKey('detail-extra'))).height,
        collapsed);
    await t.tap(find.byTooltip('Lịch sử trò chuyện'));
    await t.pumpAndSettle();
    expect(find.byType(OrderChatScreen), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    expect(find.byType(OrderHistoryDetailScreen), findsNothing);
  });

  for (final config in [
    (const Size(412, 915), 1.0),
    (const Size(412, 915), 1.3),
    (const Size(412, 915), 1.6),
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 1.3),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets('Detail fits without overflow ${config.$1} at ${config.$2}',
        (t) async {
      await host(t, OrderHistoryDetailScreen(item: showcase('#DEMO-S005')),
          size: config.$1, scale: config.$2);
      final tag = '${config.$1.width.toInt()}-${config.$2}';
      await shot(t, 'detail-$tag');
      await t.scrollUntilVisible(
          find.byKey(const ValueKey('detail-extra')), 120,
          scrollable: find.byType(Scrollable).first);
      await t.tap(find.byKey(const ValueKey('detail-extra')));
      await t.pumpAndSettle();
      await t.drag(find.byType(ListView).first, const Offset(0, -1500));
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
