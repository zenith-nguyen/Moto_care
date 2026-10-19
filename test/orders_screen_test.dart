import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/demo_controls_screen.dart';
import 'package:motocare_mechanic/screens/order_history_detail_screen.dart';
import 'package:motocare_mechanic/screens/order_received_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/order_identity.dart';
import 'package:motocare_mechanic/widgets/ui.dart';

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
    appState.setTab(1);
  });

  Future<void> host(WidgetTester t,
      {Size size = const Size(412, 2600), double scale = 1}) async {
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
        'order_battery_car.jpg',
        'order_flood_car.jpg',
        'order_fuel_motorbike.png',
        'order_tire_motorbike.jpg',
        'order_tow_car.jpg',
        'home_service_repair.png',
      ]) {
        await precacheImage(
            AssetImage('assets/images/$a'), boundary.currentContext!);
      }
    });
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

  Finder card(String code) => find.byKey(ValueKey(code));
  List<String> codes(WidgetTester t) => [
        for (final c in t.widgetList<ShadowCard>(find.byType(ShadowCard)))
          (c.key! as ValueKey<String>).value
      ];
  Future<void> tapKey(WidgetTester t, String key) async {
    final f = find.byKey(ValueKey(key));
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> search(WidgetTester t, String text) async {
    await t.enterText(find.byKey(const ValueKey('orders-search')), text);
    await t.pumpAndSettle();
  }

  group('photo mapping', () {
    test('uses the service and vehicle class, never a car photo for a bike',
        () {
      expect(orderPhotoFor('Xẹp lốp', 'Honda Vision'),
          'assets/images/order_tire_motorbike.jpg');
      expect(orderPhotoFor('Hết xăng', 'Yamaha Sirius'),
          'assets/images/order_fuel_motorbike.png');
      expect(orderPhotoFor('Hết bình', 'Toyota Vios'),
          'assets/images/order_battery_car.jpg');
      expect(orderPhotoFor('Xe cần kéo', 'Toyota Vios'),
          'assets/images/order_tow_car.jpg');
      expect(orderPhotoFor('Xe không thể di chuyển', 'Toyota Fortuner'),
          'assets/images/order_tow_car.jpg');
      expect(orderPhotoFor('Ngập nước', 'Toyota Vios'),
          'assets/images/order_flood_car.jpg');
      // Car services without a dedicated order photo reuse the catalog photo.
      expect(orderPhotoFor('Chết máy', 'Toyota Vios'),
          'assets/images/home_service_repair.png');
      // No suitable photo: neutral panel instead of a wrong picture.
      expect(orderPhotoFor('Hết bình', 'Honda Vision'),
          'assets/images/order_battery_car.jpg');
      expect(orderPhotoFor('Ngập nước', 'Yamaha Sirius'), isNull);
      expect(orderPhotoFor('Lý do lạ', 'Toyota Vios'), isNull);
    });

    test('all five approved order photos exist on disk', () {
      for (final f in [
        'order_fuel_motorbike.png',
        'order_tire_motorbike.jpg',
        'order_battery_car.jpg',
        'order_tow_car.jpg',
        'order_flood_car.jpg'
      ]) {
        expect(File('assets/images/$f').existsSync(), isTrue, reason: f);
      }
    });
  });

  testWidgets(
      'All five order photos decode, including content/extension mismatches',
      (t) async {
    await t.runAsync(() async {
      for (final f in [
        'order_fuel_motorbike.png',
        'order_tire_motorbike.jpg',
        'order_battery_car.jpg',
        'order_tow_car.jpg',
        'order_flood_car.jpg'
      ]) {
        final bytes = File('assets/images/$f').readAsBytesSync();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(100), reason: f);
        expect(frame.image.height, greaterThan(100), reason: f);
        frame.image.dispose();
      }
    });
  });

  testWidgets('Two orders with the same service name are both kept', (t) async {
    await host(t);
    expect(find.text('Xẹp lốp'), findsNWidgets(2));
    expect(card('#RVO2298'), findsOneWidget);
    expect(card('#RVO2271'), findsOneWidget);
    expect(
        appState.history.where((o) => o.issue == 'Xẹp lốp').map((o) => o.code),
        ['#RVO2298', '#RVO2271']);
    // Both resolve to the motorbike tyre photo through their own vehicle class.
    for (final code in ['#RVO2298', '#RVO2271']) {
      final img = t.widget<Image>(
          find.descendant(of: card(code), matching: find.byType(Image)));
      expect((img.image as AssetImage).assetName,
          'assets/images/order_tire_motorbike.jpg');
    }
  });

  testWidgets('Cards show photo, vehicle, address, time, badge and dark money',
      (t) async {
    final order = appState.acceptOffer(appState.nextOffer(serviceIndex: 4));
    await host(t);
    final done = card('#RVO2298');
    expect(find.descendant(of: done, matching: find.text('Xẹp lốp')),
        findsOneWidget);
    expect(
        find.descendant(
            of: done, matching: find.text('Honda Vision · Xe tay ga')),
        findsOneWidget);
    expect(find.descendant(of: done, matching: find.text('Hoàn thành')),
        findsOneWidget);
    expect(find.descendant(of: done, matching: find.text('Thu nhập')),
        findsOneWidget);
    // Earning (112.000đ) as recorded in the wallet, not the gross price.
    final amount = find.byKey(const ValueKey('orders-amount-#RVO2298'));
    expect(t.widget<Text>(amount).data, '112.000đ');
    expect(t.widget<Text>(amount).style!.color, const Color(0xFF172638));
    expect(t.widget<Text>(amount).style!.fontFamily, 'Montserrat');
    final img = t
        .widget<Image>(find.descendant(of: done, matching: find.byType(Image)));
    expect((img.image as AssetImage).assetName,
        'assets/images/order_tire_motorbike.jpg');
    expect(img.fit, BoxFit.cover);
    // No service icon inside any card; only the chevron remains.
    final icons = t.widgetList<Icon>(
        find.descendant(of: done, matching: find.byType(Icon)));
    expect(icons.map((i) => i.icon), [Icons.chevron_right_rounded]);

    final active = card(order.offer.code);
    expect(find.descendant(of: active, matching: find.text('Đang làm')),
        findsOneWidget);
    expect(find.descendant(of: active, matching: find.text('Báo giá')),
        findsOneWidget);
    expect(find.descendant(of: active, matching: find.text('Xe cần kéo')),
        findsOneWidget);
    final img2 = t.widget<Image>(
        find.descendant(of: active, matching: find.byType(Image)));
    expect((img2.image as AssetImage).assetName,
        'assets/images/order_tow_car.jpg');

    final cancelled = card('#RVO2279');
    expect(find.descendant(of: cancelled, matching: find.text('Đã hủy')),
        findsOneWidget);
    expect(
        find.descendant(
            of: cancelled, matching: find.text('Không ghi nhận thu nhập')),
        findsOneWidget);
    expect(find.descendant(of: cancelled, matching: find.textContaining('đ')),
        findsNothing);
    expect(
        (t
                .widget<Image>(find.descendant(
                    of: cancelled, matching: find.byType(Image)))
                .image as AssetImage)
            .assetName,
        'assets/images/order_fuel_motorbike.png');
    expect(find.byType(AppBottomNav), findsOneWidget);
    await shot(t, 'orders-default');
  });

  testWidgets('Active Hết bình order on a Honda Vision shows the battery photo',
      (t) async {
    final order = appState.acceptOffer(appState.nextOffer(serviceIndex: 0));
    expect(order.offer.vehicle, 'Honda Vision');
    expect(order.offer.issue, 'Hết bình');
    await host(t);
    final c = card(order.offer.code);
    final img =
        t.widget<Image>(find.descendant(of: c, matching: find.byType(Image)));
    expect((img.image as AssetImage).assetName,
        'assets/images/order_battery_car.jpg');
    expect(img.fit, BoxFit.cover);
    // The order data itself is untouched.
    expect(
        find.descendant(of: c, matching: find.text('Honda Vision · Xe tay ga')),
        findsOneWidget);
    expect(find.descendant(of: c, matching: find.text('Đang làm')),
        findsOneWidget);
    expect(
        t
            .widget<Text>(
                find.byKey(ValueKey('orders-amount-${order.offer.code}')))
            .data,
        '150.000đ');
    await shot(t, 'orders-battery-bike');
  });

  testWidgets('Tabs show real counts and one filter drives tabs and chips',
      (t) async {
    final order = appState.acceptOffer(appState.nextOffer(serviceIndex: 0));
    await host(t);
    expect(find.text('Tất cả (5)'), findsOneWidget);
    expect(find.text('Đang làm (1)'), findsOneWidget);
    expect(find.text('Hoàn thành (2)'), findsOneWidget);
    await tapKey(t, 'orders-tab-completed');
    expect(codes(t), ['#RVO2298', '#RVO2287']);
    expect(
        t
            .widget<ChoiceChip>(
                find.byKey(const ValueKey('orders-chip-completed')))
            .selected,
        isTrue);
    await tapKey(t, 'orders-chip-cancelled');
    expect(codes(t), ['#RVO2279', '#RVO2271']);
    expect(
        t
            .widget<ChoiceChip>(
                find.byKey(const ValueKey('orders-chip-completed')))
            .selected,
        isFalse);
    await tapKey(t, 'orders-chip-active');
    expect(codes(t), [order.offer.code]);
    await tapKey(t, 'orders-chip-all');
    expect(codes(t), hasLength(5));
  });

  testWidgets('Search matches code, service, vehicle and address; clear works',
      (t) async {
    await host(t);
    await search(t, 'RVO2287');
    expect(codes(t), ['#RVO2287']);
    await search(t, 'xep lop');
    expect(codes(t), ['#RVO2298', '#RVO2271']);
    await search(t, 'vios');
    expect(codes(t), ['#RVO2287']);
    await search(t, 'quận 10');
    expect(codes(t), isNotEmpty);
    await tapKey(t, 'orders-chip-completed');
    await search(t, 'xẹp lốp');
    expect(codes(t), ['#RVO2298']);
    await t.tap(find.byTooltip('Xóa từ khóa'));
    await t.pumpAndSettle();
    expect(codes(t), ['#RVO2298', '#RVO2287']);
  });

  testWidgets('Sorting follows the real timestamps', (t) async {
    await host(t);
    expect(codes(t), ['#RVO2298', '#RVO2287', '#RVO2279', '#RVO2271']);
    await tapKey(t, 'orders-sort');
    await t.tap(find.text('Cũ nhất').last);
    await t.pumpAndSettle();
    expect(codes(t), ['#RVO2271', '#RVO2279', '#RVO2287', '#RVO2298']);
    expect(find.text('Cũ nhất'), findsOneWidget);
  });

  testWidgets('Header search focuses the field and the filter sheet applies',
      (t) async {
    await host(t);
    await t.tap(find.byTooltip('Tìm đơn hàng'));
    await t.pumpAndSettle();
    expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('orders-search')))
            .focusNode!
            .hasFocus,
        isTrue);
    await t.tap(find.byTooltip('Bộ lọc đơn hàng'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(ChoiceChip, 'Đã hủy').last);
    await t.tap(find.widgetWithText(ChoiceChip, 'Cũ nhất'));
    await t.tap(find.text('Áp dụng bộ lọc'));
    await t.pumpAndSettle();
    expect(codes(t), ['#RVO2271', '#RVO2279']);
  });

  testWidgets('Empty state is explained and recoverable', (t) async {
    await host(t);
    await search(t, 'NO_SUCH_ORDER');
    expect(find.byKey(const ValueKey('orders-empty')), findsOneWidget);
    expect(find.text('Chưa có đơn hàng phù hợp'), findsOneWidget);
    expect(find.text('Thử thay đổi từ khóa hoặc bộ lọc.'), findsOneWidget);
    await t.tap(find.text('Xóa bộ lọc'));
    await t.pumpAndSettle();
    expect(codes(t), hasLength(4));
    await tapKey(t, 'orders-tab-active');
    expect(find.byKey(const ValueKey('orders-empty')), findsOneWidget);
  });

  testWidgets('Opening cards routes by orderId without touching money or state',
      (t) async {
    final order = appState.acceptOffer(appState.nextOffer(serviceIndex: 0));
    final balance = appState.balance;
    final tx = appState.transactions.length;
    final history = appState.history.length;
    await host(t);
    await t.tap(card('#RVO2287'));
    await t.pumpAndSettle();
    final detail = t.widget<OrderHistoryDetailScreen>(
        find.byType(OrderHistoryDetailScreen));
    expect(detail.item.code, '#RVO2287');
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    await t.tap(card(order.offer.code));
    await t.pumpAndSettle();
    expect(find.byType(OrderReceivedScreen), findsOneWidget);
    expect(appState.activeOrder, same(order));
    expect(appState.balance, balance);
    expect(appState.transactions.length, tx);
    expect(appState.history.length, history);
  });

  group('showcase orders (presentation only)', () {
    setUp(() => appState.setShowcaseOrders(false));
    tearDown(() => appState.setShowcaseOrders(false));

    test('five different services, apart from history, wallet and income', () {
      final items = appState.showcaseOrders;
      expect(items, hasLength(5));
      expect(items.map((e) => orderServiceId(e.issue)).toSet(),
          {'tire', 'battery', 'fuel', 'tow', 'flood'});
      expect(items.map((e) => e.code).toSet(), hasLength(5));
      expect(items.every((e) => e.code.startsWith('#DEMO-S')), isTrue);
      // Distinct from the real history codes.
      final real = appState.history.map((e) => e.code).toSet();
      expect(items.any((e) => real.contains(e.code)), isFalse);
      expect(
          appState.transactions
              .any((t) => items.any((e) => e.code == t.orderCode)),
          isFalse);
      expect(items.map((e) => orderPhotoFor(e.issue, e.vehicle)), [
        'assets/images/order_tire_motorbike.jpg',
        'assets/images/order_battery_car.jpg',
        'assets/images/order_fuel_motorbike.png',
        'assets/images/order_tow_car.jpg',
        'assets/images/order_flood_car.jpg',
      ]);
    });

    test('toggling never touches history, wallet or the active order', () {
      final history = appState.history.map((e) => e.code).toList();
      final tx = appState.transactions.length;
      appState.setShowcaseOrders(true);
      appState.setShowcaseOrders(false);
      expect(appState.history.map((e) => e.code), history);
      expect(appState.transactions.length, tx);
      expect(appState.balance, 1250000);
      expect(appState.activeOrder, isNull);
    });

    testWidgets(
        'tab shows the five cards when enabled and the real list otherwise',
        (t) async {
      await host(t);
      expect(codes(t), hasLength(4));
      appState.setShowcaseOrders(true);
      await t.pumpAndSettle();
      expect(codes(t), [
        '#DEMO-S001',
        '#DEMO-S002',
        '#DEMO-S003',
        '#DEMO-S004',
        '#DEMO-S005'
      ]);
      expect(find.textContaining('Dữ liệu trình diễn'), findsOneWidget);
      expect(find.text('Xẹp lốp'), findsOneWidget);
      for (final name in ['Kích bình', 'Hết xăng', 'Kéo xe', 'Ngập nước']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      for (final code in codes(t)) {
        final img = t.widget<Image>(
            find.descendant(of: card(code), matching: find.byType(Image)));
        expect(img.image, isA<AssetImage>());
      }
      expect(find.text('Tất cả (5)'), findsOneWidget);
      await shot(t, 'orders-showcase');
      // Search/filter/sort still work on the showcase set.
      await search(t, 'ngap nuoc');
      expect(codes(t), ['#DEMO-S005']);
      await search(t, '');
      await tapKey(t, 'orders-chip-cancelled');
      expect(codes(t), ['#DEMO-S003']);
      await tapKey(t, 'orders-chip-all');
      await tapKey(t, 'orders-sort');
      await t.tap(find.text('Cũ nhất').last);
      await t.pumpAndSettle();
      expect(codes(t).first, '#DEMO-S005');
      // Cancelled shows no income; completed show earnings; money untouched.
      expect(find.text('Không ghi nhận thu nhập'), findsOneWidget);
      expect(
          t
              .widget<Text>(
                  find.byKey(const ValueKey('orders-amount-#DEMO-S001')))
              .data,
          '112.000đ');
      expect(
          t
              .widget<Text>(
                  find.byKey(const ValueKey('orders-amount-#DEMO-S004')))
              .data,
          '500.000đ');
      expect(appState.balance, 1250000);
    });

    testWidgets('opening a showcase card routes by its own orderId', (t) async {
      appState.setShowcaseOrders(true);
      await host(t);
      await t.tap(card('#DEMO-S002'));
      await t.pumpAndSettle();
      expect(
          t
              .widget<OrderHistoryDetailScreen>(
                  find.byType(OrderHistoryDetailScreen))
              .item
              .code,
          '#DEMO-S002');
      expect(appState.transactions.length, MockData.transactions().length);
      expect(appState.balance, 1250000);
    });

    testWidgets('the demo controls switch drives the flag', (t) async {
      t.view.physicalSize = const Size(412, 915);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(MaterialApp(
          theme: buildAppTheme(), home: const DemoControlsScreen()));
      await t.pumpAndSettle();
      expect(appState.showcaseOrdersEnabled, isFalse);
      await t.tap(find.byKey(const ValueKey('demo-showcase-orders')));
      await t.pumpAndSettle();
      expect(appState.showcaseOrdersEnabled, isTrue);
    });
  });

  for (final config in [
    (const Size(412, 915), 1.0),
    (const Size(412, 915), 1.3),
    (const Size(412, 915), 1.6),
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 1.3),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets('Orders fits without overflow ${config.$1} at ${config.$2}',
        (t) async {
      appState.acceptOffer(appState.nextOffer(serviceIndex: 0));
      await host(t, size: config.$1, scale: config.$2);
      final tag = '${config.$1.width.toInt()}-${config.$2}';
      await shot(t, 'orders-$tag-top');
      await t.drag(find.byType(ListView).first, const Offset(0, -2500));
      await t.pumpAndSettle();
      await shot(t, 'orders-$tag-bottom');
      await t.drag(find.byType(ListView).first, const Offset(0, 3000));
      await t.pumpAndSettle();
      await search(t, 'zzz');
      expect(t.takeException(), isNull);
      await search(t, '');
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
