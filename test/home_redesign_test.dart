import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/home_catalog.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/services/home_feed_repository.dart';
import 'package:motocare_mechanic/screens/incoming_order_popup.dart';
import 'package:motocare_mechanic/screens/mechanic_home_screen.dart';
import 'package:motocare_mechanic/screens/service_management_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/home_components.dart';

void main() {
  group('Home request repository', () {
    late AppState state;
    late HomeFeedRepository repo;
    final now = DateTime(2026, 10, 16, 12);
    setUp(() {
      state = AppState(demoEnabled: true);
      repo = HomeFeedRepository(state, now: now);
    });
    tearDown(() => state.dispose());

    test(
        'Search accepts Vietnamese without accents, service, radius and ordering',
        () {
      expect(repo.search(query: 'kich BINH').single.title, 'Kích bình xe ô tô');
      expect(repo.search(query: 'vo van kiet').single.offer.price, 200000);
      expect(repo.search(serviceId: 'tire').single.serviceId, 'tire');
      expect(repo.search(radiusKm: 1), isEmpty);
      expect(repo.search(radiusKm: 2).single.serviceId, 'battery');
      expect(repo.search(newestFirst: true).first.serviceId, 'battery');
      expect(repo.search(serviceId: 'oil'), isEmpty);
    });
    test(
        'Preview preserves the exact card order and never creates or credits an order',
        () {
      final before = state.balance;
      final seq = state.offerSeq;
      final r = repo.requests.first;
      final proposal = repo.proposalFor(r, now: now);
      expect(proposal.orderId, r.offer.orderId);
      expect(proposal.vehicle, r.offer.vehicle);
      expect(proposal.price, r.offer.price);
      expect(proposal.expiresAt, now.add(const Duration(seconds: 30)));
      expect(state.activeOrder, isNull);
      expect(state.balance, before);
      expect(state.offerSeq, seq);
    });
    test(
        'Expired, assigned elsewhere, offline and disabled-service requests cannot be offered',
        () {
      final base = repo.requests.first;
      expect(repo.canOffer(base, now: base.availableUntil), isFalse);
      expect(() => repo.proposalFor(base, now: base.availableUntil),
          throwsStateError);
      final assigned = HomeRequest(
          offer: base.offer,
          serviceId: base.serviceId,
          title: base.title,
          image: base.image,
          requestedAt: base.requestedAt,
          availableUntil: base.availableUntil,
          status: HomeRequestStatus.assignedElsewhere);
      final assignedRepo = HomeFeedRepository(state, requests: [assigned]);
      expect(assignedRepo.statusOf(assigned, now: now),
          HomeRequestStatus.assignedElsewhere);
      expect(
          () => assignedRepo.proposalFor(assigned, now: now), throwsStateError);
      state.setOnline(false);
      expect(repo.canOffer(base, now: now), isFalse);
      state.setOnline(true);
      state.saveServices([false, true, true, true, true, false, false]);
      expect(repo.canOffer(base, now: now), isFalse);
    });
    test(
        'Shared active/history state prevents a completed request from being offered again',
        () {
      repo = HomeFeedRepository(state);
      final r = repo.requests.first;
      final o = state.acceptOffer(repo.proposalFor(r));
      expect(repo.statusOf(r), HomeRequestStatus.active);
      expect(repo.canOffer(repo.requests.last), isFalse);
      state.beginNavigation(orderId: o.orderId);
      state.markArrived(orderId: o.orderId);
      state.startRepair(orderId: o.orderId, code: '2847');
      for (var i = 0; i < 3; i++) {
        state.advanceRepair(orderId: o.orderId);
      }
      final item = state.completeOrder(orderId: o.orderId);
      expect(repo.statusOf(r), HomeRequestStatus.completed);
      expect(() => repo.proposalFor(r), throwsStateError);
      final balance = state.balance;
      expect(state.completeOrder(orderId: o.orderId), same(item));
      expect(state.balance, balance);
    });
    test('Production has no demo feed and preview cannot bypass the demo guard',
        () {
      final production = AppState(demoEnabled: false);
      expect(HomeFeedRepository(production).requests, isEmpty);
      final injected = HomeFeedRepository(production, requests: repo.requests);
      expect(injected.canOffer(injected.requests.first, now: now), isFalse);
      production.dispose();
    });
  });

  group('Home widgets', () {
    final boundary = GlobalKey();
    setUpAll(() async {
      await (FontLoader('Montserrat')
            ..addFont(rootBundle.load('assets/fonts/Montserrat.ttf')))
          .load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    });
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
        {Size size = const Size(390, 844),
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
                  child: child!))));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        for (final image in [
          'revo_hero_engine.jpg',
          'home_service_flood.png',
          'home_service_tow.png',
          'home_service_repair.png',
          'home_battery_car.png',
          'home_tire_suv.png'
        ]) {
          await precacheImage(
              AssetImage('assets/images/$image'), boundary.currentContext!);
        }
      });
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }

    Future<void> tap(WidgetTester t, String label, {bool first = false}) async {
      var target = first ? find.text(label).first : find.text(label).last;
      if (find.text(label).evaluate().isEmpty) {
        await t.scrollUntilVisible(find.text(label), 160,
            scrollable: find.byType(Scrollable).first);
        target = first ? find.text(label).first : find.text(label).last;
      }
      await t.ensureVisible(target);
      await t.pumpAndSettle();
      await t.tap(target);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }

    Future<void> shot(WidgetTester t, String name) async {
      const output = String.fromEnvironment('REVO_HOME_CAPTURE_DIR');
      if (output.isEmpty) return;
      await t.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final picture = await render.toImage(pixelRatio: 2);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        final f = File('$output/$name.png');
        await f.parent.create(recursive: true);
        await f.writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }

    Future<void> close(WidgetTester t) => t.pumpWidget(const SizedBox());

    testWidgets(
        'Four photo services retain Montserrat and a single Home navigation',
        (t) async {
      await host(t);
      expect(find.byType(HomeServiceTile), findsNWidgets(4));
      final tiles =
          t.widgetList<HomeServiceTile>(find.byType(HomeServiceTile)).toList();
      expect(
          tiles.map((s) => s.service.id), ['battery', 'tire', 'repair', 'all']);
      expect(tiles.where((s) => s.service.image != null), hasLength(3));
      final all = find.byKey(const ValueKey('home-service-all'));
      expect(
          t
              .widget<HomeServiceGridIcon>(find.descendant(
                  of: all, matching: find.byType(HomeServiceGridIcon)))
              .color,
          const Color(0xFF317CBB));
      final label = t.widget<Text>(find.text('Dịch vụ phổ biến'));
      expect(label.style!.fontFamily, 'Montserrat');
      expect(find.byKey(const ValueKey('home-online-toggle')), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);
      // Home uses the same floating dock as every other tab (no flat bar).
      expect(t.getSize(find.byType(AppBottomNav)).width, lessThan(412));
      await shot(t, 'home-top');
      await t.ensureVisible(find.byKey(const ValueKey('home-nearby-carousel')));
      await t.pumpAndSettle();
      await shot(t, 'home-bottom');
      await tap(t, 'Ví');
      expect(find.byType(AppBottomNav), findsOneWidget);
      await close(t);
    });
    testWidgets(
        'Search and category filters produce results and a recoverable empty state',
        (t) async {
      await host(t);
      await t.enterText(find.byKey(const ValueKey('home-search')), 'kich binh');
      await t.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      expect(find.byType(HomeServiceTile), findsOneWidget);
      expect(find.byType(NearbyRequestCard), findsOneWidget);
      await t.enterText(find.byKey(const ValueKey('home-search')), 'NO_MATCH');
      await t.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await tap(t, 'Xóa bộ lọc');
      expect(find.byType(HomeServiceTile), findsNWidgets(4));
      await t.tap(find.byTooltip('Bộ lọc đơn gần bạn'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ChoiceChip, 'Thay nhớt, bảo dưỡng'));
      await tap(t, 'Áp dụng bộ lọc');
      await tap(t, 'Chưa có đơn phù hợp.');
      expect(find.text('Chưa có yêu cầu nào cho dịch vụ này.'), findsOneWidget);
      expect(appState.activeOrder, isNull);
      await close(t);
    });
    testWidgets('Filter distance updates actual request results', (t) async {
      await host(t);
      await t.tap(find.byTooltip('Bộ lọc đơn gần bạn'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ChoiceChip, '1 km'));
      await t.pumpAndSettle();
      await tap(t, 'Áp dụng bộ lọc');
      expect(find.byType(NearbyRequestCard), findsNothing);
      await tap(t, 'Xóa bộ lọc');
      expect(find.byType(NearbyRequestCard), findsWidgets);
      await close(t);
    });
    testWidgets(
        'Real carousel pages navigate to services and work schedule without creating orders',
        (t) async {
      await host(t);
      final seq = appState.offerSeq;
      await t.tap(find.byTooltip('Banner 3'));
      await t.pumpAndSettle();
      await tap(t, 'Dịch vụ');
      expect(find.byType(ServiceManagementScreen), findsOneWidget);
      await t.tap(find.byTooltip('Quay lại'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Banner 2'));
      await t.pumpAndSettle();
      await tap(t, 'Lịch công việc');
      expect(find.text('Chưa có công việc hôm nay.'), findsOneWidget);
      expect(appState.activeOrder, isNull);
      expect(appState.offerSeq, seq);
      await close(t);
    });
    testWidgets('Online control and area dropdown update shared state',
        (t) async {
      await host(t);
      await t.tap(find.byKey(const ValueKey('home-online-toggle')));
      await t.pumpAndSettle();
      expect(appState.isOnline, isFalse);
      expect(find.text('Đang ngoại tuyến'), findsWidgets);
      await t.tap(find.byKey(const ValueKey('home-online-toggle')));
      await t.pumpAndSettle();
      expect(appState.isOnline, isTrue);
      await tap(t, 'Quận 1, TP.HCM');
      await tap(t, 'Quận 3, TP.HCM');
      expect(appState.profile.area, 'Quận 3, TP.HCM');
      await close(t);
    });
    testWidgets(
        'Leaving Home search dismisses keyboard and preserves the query',
        (t) async {
      await host(t);
      final field = find.byKey(const ValueKey('home-search'));
      await t.showKeyboard(field);
      await t.enterText(field, 'kich binh');
      await t.pumpAndSettle();
      expect(t.testTextInput.isVisible, isTrue);
      await tap(t, 'Ví');
      expect(t.testTextInput.isVisible, isFalse);
      await tap(t, 'Trang chủ');
      expect(t.widget<TextField>(field).controller!.text, 'kich binh');
      await close(t);
    });
    testWidgets(
        'Nearby card preview uses exact data; decline leaves order and wallet untouched',
        (t) async {
      await host(t);
      final card = find.byType(NearbyRequestCard).first;
      await t.ensureVisible(card);
      await t.pumpAndSettle();
      await t.tap(card);
      await t.pumpAndSettle();
      final popup =
          t.widget<IncomingOrderPopup>(find.byType(IncomingOrderPopup));
      expect(popup.offer.orderId, '#DEMO-H001');
      expect(popup.offer.price, 150000);
      expect(popup.offer.vehicle, 'Toyota Vios');
      expect(appState.activeOrder, isNull);
      await tap(t, 'Từ chối');
      expect(appState.activeOrder, isNull);
      expect(appState.balance, 1250000);
      await close(t);
    });
    testWidgets(
        'Expired and assigned cards display status instead of an accept action',
        (t) async {
      final base = demoHomeRequests(DateTime.now()).first;
      for (final item in [
        (HomeRequestStatus.waiting, 'Đã hết hạn'),
        (HomeRequestStatus.assignedElsewhere, 'Đã có thợ nhận'),
      ]) {
        final unavailable = HomeRequest(
            offer: base.offer,
            serviceId: base.serviceId,
            title: base.title,
            image: base.image,
            requestedAt: base.requestedAt,
            availableUntil: DateTime.now().subtract(const Duration(seconds: 1)),
            status: item.$1);
        await host(t,
            page: Scaffold(
                body: MechanicHomeScreen(
                    repository: HomeFeedRepository(appState,
                        requests: [unavailable]))));
        final card =
            t.widget<NearbyRequestCard>(find.byType(NearbyRequestCard));
        expect(card.actionLabel, item.$2);
        expect(card.onAction, isNull);
        await close(t);
      }
    });
    for (final scale in [1.0, 1.6]) {
      testWidgets(
          'Compact 320px Home fits text scale $scale including bottom sections',
          (t) async {
        await host(t, size: const Size(320, 568), scale: scale);
        await t
            .ensureVisible(find.byKey(const ValueKey('home-nearby-carousel')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await shot(t, 'home-compact-$scale');
        await close(t);
      });
    }
    testWidgets('Full Home page for visual review', (t) async {
      await host(t, size: const Size(390, 1135));
      expect(
          find.byKey(const ValueKey('home-nearby-carousel')), findsOneWidget);
      await shot(t, 'home-full');
      await close(t);
    });
  });
}
