import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/incoming_order_popup.dart';
import 'package:motocare_mechanic/screens/nearby_jobs_screen.dart';
import 'package:motocare_mechanic/screens/order_received_screen.dart';
import 'package:motocare_mechanic/services/home_feed_repository.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/home_components.dart';

void main() {
  final boundary = GlobalKey();
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
    appState.saveServices([true, true, true, true, true, false, false]);
    appState.setTab(0);
  });

  Future<void> host(WidgetTester t,
      {Size size = const Size(412, 915),
      double scale = 1,
      Widget? page}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: page ?? const MechanicShell(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
        )));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      for (final asset in [
        'home_battery_car.png',
        'home_tire_suv.png',
        'home_service_tow.png',
        'home_service_flood.png',
        'home_service_repair.png',
      ]) {
        await precacheImage(
            AssetImage('assets/images/$asset'), boundary.currentContext!);
      }
    });
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  Future<void> close(WidgetTester t) => t.pumpWidget(const SizedBox());
  Future<void> click(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
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

  Finder cards() => find.descendant(
      of: find.byType(NearbyJobsScreen),
      matching: find.byType(NearbyRequestCard));
  List<String> codes(WidgetTester t) => [
        for (final c in t.widgetList<NearbyRequestCard>(cards()))
          c.request.offer.code
      ];
  Widget screen(HomeFeedRepository repo, {String service = 'all'}) =>
      NearbyJobsScreen(repository: repo, initialServiceId: service);
  HomeFeedRepository expiredRepo() => HomeFeedRepository(appState,
      now: DateTime.now().subtract(const Duration(hours: 1)));
  Future<void> chip(WidgetTester t, String id) async {
    final f = find.byKey(ValueKey('nearby-chip-$id'));
    await t.scrollUntilVisible(f, 80,
        scrollable: find.descendant(
            of: find.byKey(const ValueKey('nearby-service-chips')),
            matching: find.byType(Scrollable)));
    await click(t, f);
  }

  Future<void> openFilters(WidgetTester t) =>
      click(t, find.byTooltip('Bộ lọc đơn gần bạn'));
  Future<void> search(WidgetTester t, String text) async {
    await t.enterText(find.byKey(const ValueKey('nearby-search')), text);
    await t.pumpAndSettle();
  }

  testWidgets(
      'Home link opens the full screen, lists real data and Back returns',
      (t) async {
    await host(t);
    await click(t, find.byTooltip('Xem tất cả đơn gần bạn'));
    expect(find.byType(NearbyJobsScreen), findsOneWidget);
    expect(find.text('Đơn gần bạn'), findsOneWidget);
    expect(find.text('3 đơn phù hợp'), findsOneWidget);
    expect(codes(t), ['#DEMO-H001', '#DEMO-H002', '#DEMO-H003']);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(t.widget<Text>(find.text('Đơn gần bạn')).style!.fontFamily,
        'Montserrat');
    await shot(t, 'nearby-default');
    await click(t, find.byTooltip('Quay lại'));
    expect(find.byType(NearbyJobsScreen), findsNothing);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(appState.balance, 1250000);
    await close(t);
  });

  testWidgets(
      'Search matches service and address, with a recoverable empty state',
      (t) async {
    await host(t, page: screen(HomeFeedRepository(appState)));
    expect(find.text('Tìm theo dịch vụ, địa chỉ...'), findsOneWidget);
    await search(t, 'vo van kiet');
    expect(codes(t), ['#DEMO-H002']);
    await search(t, 'kéo xe');
    expect(codes(t), ['#DEMO-H003']);
    await search(t, 'NO_MATCH');
    expect(cards(), findsNothing);
    expect(find.text('Chưa có đơn phù hợp'), findsOneWidget);
    expect(find.text('Thử thay đổi dịch vụ, từ khóa hoặc khoảng cách.'),
        findsOneWidget);
    await click(t, find.widgetWithText(TextButton, 'Xóa bộ lọc').first);
    expect(codes(t), hasLength(3));
    await close(t);
  });

  testWidgets(
      'Service chips filter for real and preselect the incoming serviceId',
      (t) async {
    await host(t, page: screen(HomeFeedRepository(appState), service: 'tire'));
    expect(
        t
            .widget<ChoiceChip>(find.byKey(const ValueKey('nearby-chip-tire')))
            .selected,
        isTrue);
    expect(codes(t), ['#DEMO-H002']);
    await chip(t, 'tow');
    expect(codes(t), ['#DEMO-H003']);
    await chip(t, 'flood');
    expect(cards(), findsNothing);
    expect(find.text('Chưa có đơn phù hợp'), findsOneWidget);
    await chip(t, 'all');
    expect(codes(t), hasLength(3));
    await close(t);
  });

  testWidgets(
      'Filter chips cover all seven services; new ones show an empty state',
      (t) async {
    await host(t, page: screen(HomeFeedRepository(appState)));
    for (final id in [
      'all',
      'battery',
      'tire',
      'flood',
      'repair',
      'tow',
      'fuel',
      'maintenance'
    ]) {
      expect(find.byKey(ValueKey('nearby-chip-$id')), findsOneWidget);
    }
    expect(find.text('Tiếp nhiên liệu'), findsOneWidget);
    expect(find.text('Thay nhớt, bảo dưỡng'), findsOneWidget);
    for (final id in ['fuel', 'maintenance']) {
      await chip(t, id);
      expect(cards(), findsNothing);
      expect(find.text('Chưa có đơn phù hợp'), findsOneWidget);
      expect(find.byType(IncomingOrderPopup), findsNothing);
    }
    await chip(t, 'all');
    expect(codes(t), hasLength(3));
    expect(appState.activeOrder, isNull);
    await close(t);
  });

  testWidgets('Distance, status and sort filters work and show removable chips',
      (t) async {
    await host(t, page: screen(HomeFeedRepository(appState)));
    await openFilters(t);
    await click(t, find.widgetWithText(ChoiceChip, '3 km'));
    await click(t, find.text('Áp dụng bộ lọc'));
    expect(codes(t), ['#DEMO-H001', '#DEMO-H002']);
    expect(find.widgetWithText(InputChip, '≤ 3 km'), findsOneWidget);
    t.widget<InputChip>(find.widgetWithText(InputChip, '≤ 3 km')).onDeleted!();
    await t.pumpAndSettle();
    expect(codes(t), hasLength(3));

    await openFilters(t);
    await click(t, find.widgetWithText(ChoiceChip, 'Thu nhập cao nhất'));
    await click(t, find.text('Áp dụng bộ lọc'));
    expect(codes(t), ['#DEMO-H003', '#DEMO-H002', '#DEMO-H001']);

    await openFilters(t);
    await click(t, find.widgetWithText(ChoiceChip, 'Mới nhất'));
    await click(t, find.text('Áp dụng bộ lọc'));
    expect(codes(t), ['#DEMO-H001', '#DEMO-H002', '#DEMO-H003']);

    await openFilters(t);
    await click(t, find.widgetWithText(ChoiceChip, 'Hết hạn'));
    await click(t, find.text('Áp dụng bộ lọc'));
    expect(cards(), findsNothing);
    expect(find.text('Không có đơn hết hạn khớp bộ lọc này.'), findsOneWidget);
    await click(t, find.text('Xem mọi trạng thái'));
    expect(codes(t), hasLength(3));
    expect(appState.balance, 1250000);
    await close(t);
  });

  testWidgets(
      'Opening a card shows the same order and accepts nothing until confirmed',
      (t) async {
    final repo = HomeFeedRepository(appState);
    await host(t, page: screen(repo));
    await click(t, cards().at(1));
    final popup = t.widget<IncomingOrderPopup>(find.byType(IncomingOrderPopup));
    expect(popup.offer.code, '#DEMO-H002');
    expect(appState.activeOrder, isNull);
    expect(appState.balance, 1250000);
    await click(t, find.text('Từ chối'));
    expect(appState.activeOrder, isNull);
    expect(appState.balance, 1250000);
    expect(appState.history.length, MockData.history().length);

    await click(t, cards().at(1));
    await click(
        t,
        find.descendant(
            of: find.byType(IncomingOrderPopup),
            matching: find.text('Nhận đơn')));
    expect(appState.activeOrder?.offer.code, '#DEMO-H002');
    expect(find.byType(OrderReceivedScreen), findsOneWidget);
    expect(appState.balance, 1250000);
    await close(t);
  });

  testWidgets('Expired requests are labelled and cannot be accepted',
      (t) async {
    final repo = expiredRepo();
    await host(t, page: screen(repo));
    expect(codes(t), hasLength(3));
    expect(find.text('Hết hạn'), findsNWidgets(3));
    expect(find.text('Đã hết hạn'), findsNWidgets(3));
    for (final c in t.widgetList<NearbyRequestCard>(cards())) {
      expect(c.onAction, isNull);
    }
    await t.tap(cards().first, warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.byType(IncomingOrderPopup), findsNothing);
    expect(appState.activeOrder, isNull);

    await openFilters(t);
    await click(t, find.widgetWithText(ChoiceChip, 'Đang chờ'));
    await click(t, find.text('Áp dụng bộ lọc'));
    expect(cards(), findsNothing);
    expect(find.text('Các đơn khớp bộ lọc đã hết hạn hoặc đã có người nhận.'),
        findsOneWidget);
    await close(t);
  });

  testWidgets('Completed requests leave the list and history is untouched',
      (t) async {
    final repo = HomeFeedRepository(appState);
    final order = appState.acceptOffer(repo.proposalFor(repo.requests.first));
    appState.beginNavigation(orderId: order.orderId);
    appState.markArrived(orderId: order.orderId);
    expect(
        appState.startRepair(
            orderId: order.orderId, code: order.offer.verificationCode),
        isTrue);
    while (order.repairStage < 3) {
      appState.advanceRepair(orderId: order.orderId);
    }
    appState.completeOrder(orderId: order.orderId);
    final balance = appState.balance;
    final history = appState.history.length;
    await host(t, page: screen(repo));
    expect(codes(t), ['#DEMO-H002', '#DEMO-H003']);
    expect(appState.balance, balance);
    expect(appState.history.length, history);
    await close(t);
  });

  testWidgets('Empty states distinguish no data from no filter match',
      (t) async {
    await host(t,
        page: screen(HomeFeedRepository(appState, requests: const [])));
    expect(find.text('Chưa có đơn phù hợp'), findsOneWidget);
    expect(find.text('Hiện chưa có đơn nào để nhận trong khu vực của bạn.'),
        findsOneWidget);
    expect(find.text('Xóa bộ lọc'), findsNothing);
    await close(t);
  });

  testWidgets('Active order survives tab changes while browsing the list',
      (t) async {
    final repo = HomeFeedRepository(appState);
    final order = appState.acceptOffer(repo.proposalFor(repo.requests.first));
    await host(t);
    await click(t, find.byTooltip('Xem tất cả đơn gần bạn'));
    expect(find.text('Tiếp tục'), findsWidgets);
    await click(t, find.byTooltip('Quay lại'));
    for (final tab in [1, 2, 3, 0]) {
      appState.setTab(tab);
      await t.pumpAndSettle();
      expect(appState.activeOrder, same(order));
    }
    await close(t);
  });

  for (final config in [
    (const Size(412, 915), 1.0),
    (const Size(412, 915), 1.3),
    (const Size(412, 915), 1.6),
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 1.3),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets(
        'Nearby jobs fits without overflow or truncation ${config.$1} at ${config.$2}',
        (t) async {
      await host(t,
          size: config.$1,
          scale: config.$2,
          page: screen(HomeFeedRepository(appState)));
      await shot(t, 'nearby-${config.$1.width.toInt()}-${config.$2}-top');
      await openFilters(t);
      await shot(t, 'nearby-${config.$1.width.toInt()}-${config.$2}-filters');
      await click(t, find.text('Áp dụng bộ lọc'));
      await t.drag(
          find.byKey(const ValueKey('nearby-list')), const Offset(0, -600));
      await t.pumpAndSettle();
      await shot(t, 'nearby-${config.$1.width.toInt()}-${config.$2}-bottom');
      expect(t.takeException(), isNull);
      final clipped = <String>[];
      for (final e in find.byType(RichText).evaluate()) {
        final r = e.renderObject;
        if (r is RenderParagraph && r.didExceedMaxLines) {
          clipped.add(r.text.toPlainText());
        }
      }
      expect(clipped, isEmpty, reason: 'Truncated labels');
      await close(t);
    });
  }
}
