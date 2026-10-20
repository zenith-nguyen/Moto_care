import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/all_services_screen.dart';
import 'package:motocare_mechanic/screens/incoming_order_popup.dart';
import 'package:motocare_mechanic/screens/mechanic_account_screen.dart';
import 'package:motocare_mechanic/screens/nearby_jobs_screen.dart';
import 'package:motocare_mechanic/screens/service_management_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/home_components.dart';
import 'package:motocare_mechanic/widgets/revo_switch.dart';

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
    await t.runAsync(() async {
      for (final asset in [
        'home_battery_car.png',
        'home_tire_suv.png',
        'home_service_tow.png',
        'home_service_flood.png',
        'home_service_repair.png',
        'home_service_maintenance.jpg',
        'home_service_fuel.jpg',
      ]) {
        await precacheImage(
            AssetImage('assets/images/$asset'), boundary.currentContext!);
      }
    });
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

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

  Finder tiles() => find.descendant(
      of: find.byType(AllServicesScreen),
      matching: find.byType(HomeServiceTile));

  testWidgets(
      'Home keeps four cards; All services opens seven cards, not the switch screen',
      (t) async {
    await host(t);
    expect(find.byType(HomeServiceTile), findsNWidgets(4));
    await click(t, find.byKey(const ValueKey('home-service-all')));
    expect(find.byType(AllServicesScreen), findsOneWidget);
    expect(find.byType(ServiceManagementScreen), findsNothing);
    expect(find.byType(RevoSwitch), findsNothing);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.text('Tất cả dịch vụ'), findsOneWidget);
    final list = t.widgetList<HomeServiceTile>(tiles()).toList();
    expect(list.map((e) => e.service.id),
        ['battery', 'tire', 'flood', 'tow', 'repair', 'fuel', 'maintenance']);
    expect(list.every((e) => e.service.image != null), isTrue);
    expect(list[5].service.image, 'assets/images/home_service_fuel.jpg');
    expect(list[6].service.image, 'assets/images/home_service_maintenance.jpg');
    expect(list.map((e) => HomeServiceTile.description(e.service)), [
      'Xe không đề được?',
      'Lốp xẹp, thủng?',
      'Xe bị chết máy?',
      'Xe hư, không di chuyển?',
      'Sự cố trên đường?',
      'Xe hết nhiên liệu?',
      'Đến lịch chăm sóc xe?',
    ]);
    final r = [
      for (final id in AllServicesScreen.serviceIds)
        t.getRect(find.byKey(ValueKey('all-service-$id')))
    ];
    expect(r[0].top, r[1].top);
    expect(r[2].top, r[3].top);
    expect(r[4].top, r[5].top);
    expect(r[4].top, greaterThan(r[2].bottom));
    expect(r[6].top, greaterThan(r[4].bottom));
    expect(r[6].left, r[0].left);
    expect(r[6].right, lessThan(r[1].left));
    expect(r.every((e) => e.size == r[0].size), isTrue);
    expect(t.widget<Text>(find.text('Tất cả dịch vụ')).style!.fontFamily,
        'Montserrat');
    await shot(t, 'all-services');
    await click(t, find.byTooltip('Quay lại'));
    expect(find.byType(AllServicesScreen), findsNothing);
    expect(find.byType(AppBottomNav), findsOneWidget);
    await t.pumpAndSettle();
  });

  for (final id in AllServicesScreen.serviceIds) {
    testWidgets(
        'Card $id opens nearby jobs filtered by that serviceId and back works',
        (t) async {
      await host(t);
      await click(t, find.byKey(const ValueKey('home-service-all')));
      await click(t, find.byKey(ValueKey('all-service-$id')));
      final screen = t.widget<NearbyJobsScreen>(find.byType(NearbyJobsScreen));
      expect(screen.initialServiceId, id);
      expect(
          t
              .widget<ChoiceChip>(find.byKey(ValueKey('nearby-chip-$id')))
              .selected,
          isTrue);
      expect(find.byType(IncomingOrderPopup), findsNothing);
      expect(appState.activeOrder, isNull);
      expect(appState.balance, 1250000);
      await click(t, find.byTooltip('Quay lại'));
      expect(find.byType(AllServicesScreen), findsOneWidget);
      await click(t, find.byTooltip('Quay lại'));
      expect(find.byType(AllServicesScreen), findsNothing);
      expect(find.byType(AppBottomNav), findsOneWidget);
    });
  }

  testWidgets(
      'A disabled service explains itself without changing registration',
      (t) async {
    appState.saveServices([true, true, false, true, true, false, false]);
    await host(t);
    await click(t, find.byKey(const ValueKey('home-service-all')));
    await click(t, find.byKey(const ValueKey('all-service-flood')));
    expect(find.byType(NearbyJobsScreen), findsOneWidget);
    expect(find.textContaining('Ngập nước đang tắt'), findsOneWidget);
    expect(appState.services[2].enabled, isFalse);
  });

  testWidgets(
      'Service management stays reachable from Account with its switches',
      (t) async {
    await host(t);
    appState.setTab(3);
    await t.pumpAndSettle();
    expect(find.byType(MechanicAccountScreen), findsOneWidget);
    await click(t, find.text('Quản lý dịch vụ').first);
    expect(find.byType(ServiceManagementScreen), findsOneWidget);
    expect(find.byType(RevoSwitch), findsNWidgets(7));
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
        'All services fits without overflow or truncation ${config.$1} at ${config.$2}',
        (t) async {
      await host(t, size: config.$1, scale: config.$2);
      await click(t, find.byKey(const ValueKey('home-service-all')));
      await shot(t, 'all-services-${config.$1.width.toInt()}-${config.$2}');
      await t.drag(
          find.byType(SingleChildScrollView).last, const Offset(0, -800));
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
