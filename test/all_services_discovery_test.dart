import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/all_services_screen.dart';
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
      for (final a in [
        'home_battery_car.png',
        'home_tire_suv.png',
        'home_service_tow.png',
        'home_service_flood.png',
        'home_service_repair.png',
        'home_service_fuel.jpg',
        'home_service_maintenance.jpg',
      ]) {
        await precacheImage(
            AssetImage('assets/images/$a'), boundary.currentContext!);
      }
    });
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const ValueKey('home-service-all')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('home-service-all')));
    await t.pumpAndSettle();
    expect(find.byType(AllServicesScreen), findsOneWidget);
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

  Future<void> tapKey(WidgetTester t, String key) async {
    final f = find.byKey(ValueKey(key));
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  Future<void> search(WidgetTester t, String text) async {
    await t.enterText(find.byKey(const ValueKey('all-services-search')), text);
    await t.pumpAndSettle();
  }

  List<String> ids(WidgetTester t) => [
        for (final tile in t.widgetList<HomeServiceTile>(find.descendant(
            of: find.byType(AllServicesScreen),
            matching: find.byType(HomeServiceTile))))
          tile.service.id
      ];
  String count(WidgetTester t) =>
      t.widget<Text>(find.byKey(const ValueKey('all-services-count'))).data!;

  testWidgets('Shows the registration summary, seven photo cards and the CTA',
      (t) async {
    await host(t);
    expect(find.text('Dịch vụ dành cho bạn'), findsOneWidget);
    expect(
        find.text(
            'Khám phá các dịch vụ cứu hộ và bảo dưỡng phù hợp với kỹ năng của bạn.'),
        findsOneWidget);
    expect(find.text('Bạn đã đăng ký 5/7 dịch vụ'), findsOneWidget);
    expect(find.text('Tìm kiếm dịch vụ...'), findsOneWidget);
    expect(find.text('Danh sách dịch vụ'), findsOneWidget);
    expect(count(t), '7 dịch vụ');
    expect(ids(t),
        ['battery', 'tire', 'flood', 'tow', 'repair', 'fuel', 'maintenance']);
    expect(find.byType(AppBottomNav), findsNothing);
    await t.ensureVisible(find.byKey(const ValueKey('all-services-nearby')));
    expect(find.text('Tìm công việc gần bạn'), findsOneWidget);
    expect(find.text('Xem đơn gần bạn →'), findsOneWidget);
    await shot(t, 'discovery');
  });

  testWidgets('Registered count and badges follow the real switches',
      (t) async {
    await host(t);
    Finder badge(String id, String text) => find.descendant(
        of: find.byKey(ValueKey('all-service-$id')), matching: find.text(text));
    expect(badge('battery', 'Đang bật'), findsOneWidget);
    expect(badge('fuel', 'Chưa bật'), findsOneWidget);
    expect(badge('maintenance', 'Chưa bật'), findsOneWidget);
    // Edit through the existing management screen, then come back.
    await tapKey(t, 'all-services-manage');
    expect(find.byType(ServiceManagementScreen), findsOneWidget);
    expect(find.byType(RevoSwitch), findsNWidgets(7));
    expect(appState.services.map((s) => s.enabled),
        [true, true, true, true, true, false, false]);
    await t.ensureVisible(find.byType(RevoSwitch).at(5));
    await t.tap(find.byType(RevoSwitch).at(5));
    await t.pumpAndSettle();
    await t.tap(find.text('Lưu thay đổi'));
    await t.pumpAndSettle();
    expect(find.byType(AllServicesScreen), findsOneWidget);
    expect(find.text('Bạn đã đăng ký 6/7 dịch vụ'), findsOneWidget);
    expect(badge('fuel', 'Đang bật'), findsOneWidget);
    expect(appState.balance, 1250000);
  });

  testWidgets('Opening Quản lý dịch vụ changes nothing until saved', (t) async {
    await host(t);
    await tapKey(t, 'all-services-manage');
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    expect(find.text('Bạn đã đăng ký 5/7 dịch vụ'), findsOneWidget);
    expect(appState.services.map((s) => s.enabled),
        [true, true, true, true, true, false, false]);
  });

  testWidgets('Search works with and without accents, case and clear',
      (t) async {
    await host(t);
    await search(t, 'NHỚT');
    expect(ids(t), ['maintenance']);
    expect(count(t), '1 dịch vụ');
    await search(t, 'nhot');
    expect(ids(t), ['maintenance']);
    await search(t, 'xang');
    expect(ids(t), ['fuel']);
    await search(t, 'lốp');
    expect(ids(t), ['tire']);
    await search(t, 'xe');
    expect(ids(t), containsAll(['tow', 'repair']));
    await t.tap(find.byTooltip('Xóa từ khóa'));
    await t.pumpAndSettle();
    expect(ids(t), hasLength(7));
    expect(count(t), '7 dịch vụ');
  });

  testWidgets('Rescue, maintenance and enabled filters work', (t) async {
    await host(t);
    await tapKey(t, 'all-services-chip-rescue');
    expect(ids(t), ['battery', 'tire', 'flood', 'tow', 'repair', 'fuel']);
    expect(count(t), '6 dịch vụ');
    await tapKey(t, 'all-services-chip-maintenance');
    expect(ids(t), ['maintenance']);
    await tapKey(t, 'all-services-chip-enabled');
    expect(ids(t), ['battery', 'tire', 'flood', 'tow', 'repair']);
    expect(count(t), '5 dịch vụ');
    expect(
        t
            .widget<ChoiceChip>(
                find.byKey(const ValueKey('all-services-chip-enabled')))
            .selected,
        isTrue);
    await tapKey(t, 'all-services-chip-all');
    expect(ids(t), hasLength(7));
  });

  testWidgets(
      'Search combines with the filters and shows a recoverable empty state',
      (t) async {
    await host(t);
    await tapKey(t, 'all-services-chip-enabled');
    await search(t, 'nhớt');
    expect(find.byKey(const ValueKey('all-services-empty')), findsOneWidget);
    expect(find.text('Không tìm thấy dịch vụ phù hợp'), findsOneWidget);
    expect(find.text('Thử từ khóa khác hoặc thay đổi bộ lọc.'), findsOneWidget);
    expect(count(t), '0 dịch vụ');
    await t.tap(find.text('Xóa bộ lọc'));
    await t.pumpAndSettle();
    expect(ids(t), hasLength(7));
    await tapKey(t, 'all-services-chip-rescue');
    await search(t, 'bình');
    expect(ids(t), ['battery']);
  });

  testWidgets('Cards open nearby jobs by serviceId and the CTA opens the list',
      (t) async {
    await host(t);
    for (final id in AllServicesScreen.serviceIds) {
      await tapKey(t, 'all-service-$id');
      expect(
          t
              .widget<NearbyJobsScreen>(find.byType(NearbyJobsScreen))
              .initialServiceId,
          id);
      await t.tap(find.byTooltip('Quay lại'));
      await t.pumpAndSettle();
      expect(find.byType(AllServicesScreen), findsOneWidget);
      // Let the "service is off" snackbar finish before the next tap.
      await t.pump(const Duration(seconds: 6));
      await t.pumpAndSettle();
    }
    await tapKey(t, 'all-services-nearby');
    expect(
        t
            .widget<NearbyJobsScreen>(find.byType(NearbyJobsScreen))
            .initialServiceId,
        'all');
    expect(appState.activeOrder, isNull);
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    expect(find.byType(AllServicesScreen), findsNothing);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(appState.balance, 1250000);
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
        'Discovery screen fits without overflow or truncation ${config.$1} at ${config.$2}',
        (t) async {
      await host(t, size: config.$1, scale: config.$2);
      final tag = '${config.$1.width.toInt()}-${config.$2}';
      await shot(t, 'discovery-$tag-top');
      await t.drag(
          find.byType(SingleChildScrollView).last, const Offset(0, -3000));
      await t.pumpAndSettle();
      await shot(t, 'discovery-$tag-bottom');
      await search(t, 'zzz');
      expect(find.byKey(const ValueKey('all-services-empty')), findsOneWidget);
      expect(t.takeException(), isNull);
      await search(t, '');
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
