import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:motocare_mechanic/screens/all_services_screen.dart';
import 'package:motocare_mechanic/screens/nearby_jobs_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/home_catalog.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/incoming_order_popup.dart';
import 'package:motocare_mechanic/screens/mechanic_home_screen.dart';
import 'package:motocare_mechanic/screens/service_management_screen.dart';
import 'package:motocare_mechanic/services/home_feed_repository.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/home_components.dart';
import 'package:motocare_mechanic/widgets/revo_brand.dart';

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
        'revo_hero_engine.jpg',
        'home_battery_car.png',
        'home_tire_suv.png',
        'home_service_flood.png',
        'home_service_tow.png',
        'home_service_repair.png'
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

  testWidgets(
      'Vector wordmark has exactly three separate blue E bars, navy RVO and no extra blue marks',
      (t) async {
    final key = GlobalKey();
    await t.pumpWidget(MaterialApp(
        home: Center(
            child: RepaintBoundary(
                key: key,
                child: const ColoredBox(
                    color: Colors.white,
                    child: RevoLogo(
                        size: 32,
                        color: Color(0xFF152438),
                        eColor: Color(0xFF317CBB)))))));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      final png = await (key.currentContext!.findRenderObject()!
              as RenderRepaintBoundary)
          .toImage(pixelRatio: 3);
      final bytes = (await png.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      final rows = <int>{};
      var navy = 0;
      var blue = 0;
      for (var y = 0; y < png.height; y++) {
        for (var x = 0; x < png.width; x++) {
          final i = (y * png.width + x) * 4;
          if (bytes[i] == 0x31 &&
              bytes[i + 1] == 0x7c &&
              bytes[i + 2] == 0xbb) {
            blue++;
            rows.add(y);
            expect(x / png.width, inInclusiveRange(.28, .47));
          }
          if (bytes[i] == 0x15 &&
              bytes[i + 1] == 0x24 &&
              bytes[i + 2] == 0x38) {
            navy++;
          }
        }
      }
      var bands = 0;
      var previous = -2;
      for (final y in rows.toList()..sort()) {
        if (y > previous + 1) bands++;
        previous = y;
      }
      expect(bands, 3);
      expect(blue, greaterThan(100));
      expect(navy, greaterThan(100));
      png.dispose();
    });
    await close(t);
  });

  testWidgets(
      'Four photo cards form the required 2 by 2 order and every card opens its actual mechanic destination',
      (t) async {
    await host(t);
    final ids = ['battery', 'tire', 'repair', 'all'];
    final tiles =
        t.widgetList<HomeServiceTile>(find.byType(HomeServiceTile)).toList();
    expect(tiles.map((s) => s.service.id), ids);
    expect(tiles.where((s) => s.service.image != null), hasLength(3));
    final rects = [
      for (final id in ids) t.getRect(find.byKey(ValueKey('home-service-$id')))
    ];
    expect(rects[0].top, rects[1].top);
    expect(rects[2].top, rects[3].top);
    expect(rects[2].top, greaterThan(rects[0].bottom));
    expect(rects[0].size, rects[3].size);
    expect(find.byTooltip('Xem tất cả dịch vụ'), findsNothing);
    expect(find.text('Khám phá 7 dịch vụ'), findsOneWidget);
    for (final id in ids) {
      await click(t, find.byKey(ValueKey('home-service-$id')));
      if (id == 'all') {
        expect(find.byType(AllServicesScreen), findsOneWidget);
        expect(find.byType(ServiceManagementScreen), findsNothing);
        await click(t, find.byTooltip('Quay lại'));
      } else {
        expect(find.byType(NearbyJobsScreen), findsOneWidget);
        final chip =
            t.widget<ChoiceChip>(find.byKey(ValueKey('nearby-chip-$id')));
        expect(chip.selected, isTrue, reason: 'serviceId $id is preselected');
        expect(appState.activeOrder, isNull);
        await click(t, find.byTooltip('Quay lại'));
      }
      expect(appState.balance, 1250000);
    }
    expect(find.byType(HomeCommitments), findsNothing);
    await close(t);
  });

  testWidgets(
      'Horizontal nearby list reveals third request and previews that exact id without automatic acceptance',
      (t) async {
    await host(t);
    final list = find.byKey(const ValueKey('home-nearby-carousel'));
    await t.ensureVisible(list);
    await t.pumpAndSettle();
    await t.drag(list, const Offset(-370, 0));
    await t.pumpAndSettle();
    final card = find.byKey(const ValueKey('nearby-#DEMO-H003'));
    expect(card, findsOneWidget);
    await click(t, card);
    final popup = t.widget<IncomingOrderPopup>(find.byType(IncomingOrderPopup));
    expect(popup.offer.orderId, '#DEMO-H003');
    expect(popup.offer.price, 350000);
    expect(popup.offer.address, '321 Lê Hồng Phong, Quận 10, TP.HCM');
    expect(appState.activeOrder, isNull);
    expect(appState.balance, 1250000);
    await click(t, find.text('Từ chối'));
    await close(t);
  });

  testWidgets(
      'Completed and cancelled requests are absent from receivable Home cards',
      (t) async {
    final fixtures = demoHomeRequests(DateTime.now());
    HomeRequest withStatus(HomeRequest r, HomeRequestStatus status) =>
        HomeRequest(
            offer: r.offer,
            serviceId: r.serviceId,
            title: r.title,
            image: r.image,
            requestedAt: r.requestedAt,
            availableUntil: r.availableUntil,
            status: status);
    await host(t,
        page: Scaffold(
            body: MechanicHomeScreen(
                repository: HomeFeedRepository(appState, requests: [
          fixtures[0],
          withStatus(fixtures[1], HomeRequestStatus.completed),
          withStatus(fixtures[2], HomeRequestStatus.cancelled),
        ]))));
    expect(find.byType(NearbyRequestCard), findsOneWidget);
    expect(
        t
            .widget<NearbyRequestCard>(find.byType(NearbyRequestCard))
            .request
            .offer
            .orderId,
        fixtures[0].offer.orderId);
    await close(t);
  });

  testWidgets(
      'Hero receive preserves confirmation and schedule leaves orders and ledger untouched',
      (t) async {
    await host(t);
    // Tap directly: ensureVisible would drag the endless hero PageView sideways.
    await t.tap(find.descendant(
        of: find.byType(HomeHeroCarousel), matching: find.text('Nhận đơn')));
    await t.pumpAndSettle();
    expect(find.byType(IncomingOrderPopup), findsOneWidget);
    expect(appState.activeOrder, isNull);
    expect(appState.balance, 1250000);
    await click(t, find.text('Từ chối'));
    await t.tap(find.text('Xem lịch'));
    await t.pumpAndSettle();
    expect(find.text('Lịch công việc'), findsOneWidget);
    expect(appState.activeOrder, isNull);
    expect(appState.balance, 1250000);
    await close(t);
  });

  testWidgets(
      'Both all links work and the nearby screen supports the distance filter',
      (t) async {
    await host(t);
    await click(t, find.byKey(const ValueKey('home-service-all')));
    expect(find.byType(AllServicesScreen), findsOneWidget);
    expect(find.byType(ServiceManagementScreen), findsNothing);
    await click(t, find.byTooltip('Quay lại'));
    await click(t, find.byTooltip('Xem tất cả đơn gần bạn'));
    expect(find.byType(NearbyJobsScreen), findsOneWidget);
    expect(find.text('Kéo xe'), findsWidgets);
    await click(t, find.byTooltip('Bộ lọc đơn gần bạn').last);
    await click(t, find.widgetWithText(ChoiceChip, '3 km'));
    await click(t, find.text('Áp dụng bộ lọc'));
    final cards = find.descendant(
        of: find.byType(NearbyJobsScreen),
        matching: find.byType(NearbyRequestCard));
    expect(
        t
            .widgetList<NearbyRequestCard>(cards)
            .every((c) => c.request.offer.distanceKm <= 3),
        isTrue);
    expect(
        t.widgetList<NearbyRequestCard>(cards).map((c) => c.request.serviceId),
        isNot(contains('tow')));
    await close(t);
  });

  testWidgets(
      'Four shell tabs retain the same active order while Home and notification navigation change',
      (t) async {
    final repo = HomeFeedRepository(appState);
    final order = appState.acceptOffer(repo.proposalFor(repo.requests.first));
    await host(t);
    for (final label in ['Đơn hàng', 'Ví', 'Tài khoản', 'Trang chủ']) {
      final nav = find.byType(AppBottomNav);
      await click(t, find.descendant(of: nav, matching: find.text(label)));
      expect(appState.activeOrder, same(order));
    }
    await click(t, find.byTooltip('Thông báo'));
    expect(find.text('Thông báo'), findsOneWidget);
    expect(appState.activeOrder, same(order));
    await close(t);
  });

  for (final config in [
    (const Size(412, 915), 1.0),
    (const Size(412, 915), 1.3),
    (const Size(412, 915), 1.6),
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 1.3),
    (const Size(320, 568), 1.6)
  ]) {
    testWidgets(
        'Photo Home renders and scrolls without overflow ${config.$1} at ${config.$2}',
        (t) async {
      await host(t, size: config.$1, scale: config.$2);
      final title = t.widget<Text>(find.text('Dịch vụ phổ biến'));
      expect(title.style!.fontFamily, 'Montserrat');
      await shot(t, 'home-${config.$1.width.toInt()}-${config.$2}-top');
      final list = find.byKey(const ValueKey('home-nearby-carousel'));
      await t.ensureVisible(list);
      await t.pumpAndSettle();
      await t.drag(list, const Offset(-350, 0));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byType(AppBottomNav), findsOneWidget);
      final clipped = <String>[];
      for (final e in find.byType(RichText).evaluate()) {
        final r = e.renderObject;
        if (r is RenderParagraph && r.didExceedMaxLines) {
          clipped.add(r.text.toPlainText());
        }
      }
      expect(clipped, isEmpty, reason: 'Truncated Home labels');
      await shot(t, 'home-${config.$1.width.toInt()}-${config.$2}-bottom');
      await close(t);
    });
  }
}
