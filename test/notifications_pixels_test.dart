import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/screens/notifications_screen.dart';
import 'package:motocare_mechanic/services/notification_feed.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/notification_glyph.dart';
import 'fixtures/notification_visual_reference.dart';

void main() {
  Future<void> host(WidgetTester tester,
      {Size size = const Size(412, 915),
      double scale = 1,
      bool shell = false}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appState.activeOrder = null;
    appState.setTab(0);
    appState.notifications
      ..clear()
      ..addAll(notificationVisualReference(DateTime.now()));
    await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        home: shell ? const MechanicShell() : const NotificationsScreen(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!)));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());
  Future<void> chip(WidgetTester tester, NotificationFilter filter) async {
    final f = find.byKey(ValueKey('notification-chip-${filter.name}'));
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
      'Five horizontal reference chips filter real state, with exact selected/unselected styling',
      (tester) async {
    await host(tester);
    for (final filter in NotificationFilter.values.take(5)) {
      expect(find.byKey(ValueKey('notification-chip-${filter.name}')),
          findsOneWidget);
    }
    final selected = tester
        .widget<Material>(find.byKey(const ValueKey('notification-chip-all')));
    expect(selected.color, const Color(0xFF317CBB));
    expect(
        tester
            .widget<Text>(find.descendant(
                of: find.byKey(const ValueKey('notification-chip-all')),
                matching: find.byType(Text)))
            .style!
            .color,
        Colors.white);
    final inactive = tester
        .widget<Material>(find.byKey(const ValueKey('notification-chip-read')));
    expect(inactive.color, const Color(0xFFF0F4F9));
    await chip(tester, NotificationFilter.messages);
    expect(
        find.byKey(const ValueKey('notification-visual-chat')), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-visual-emergency')),
        findsNothing);
    await chip(tester, NotificationFilter.read);
    expect(
        find.byKey(const ValueKey('notification-visual-chat')), findsNothing);
    expect(find.byKey(const ValueKey('notification-visual-quote')),
        findsOneWidget);
    await chip(tester, NotificationFilter.unread);
    expect(find.byKey(const ValueKey('notification-visual-emergency')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('notification-visual-income')), findsNothing);
    await chip(tester, NotificationFilter.orders);
    expect(find.byKey(const ValueKey('notification-visual-emergency')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('notification-visual-chat')), findsNothing);
    await chip(tester, NotificationFilter.all);
    expect(
        find.byKey(const ValueKey('notification-visual-chat')), findsOneWidget);
    await close(tester);
  });

  testWidgets(
      'Only the first two unread cards get NEW badges; read change removes badge and dot',
      (tester) async {
    await host(tester);
    expect(find.text('MỚI'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('notification-new-visual-emergency')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('notification-new-visual-chat')),
        findsOneWidget);
    appState.markNotificationRead(appState.notifications.first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-new-visual-emergency')),
        findsNothing);
    expect(find.byKey(const ValueKey('notification-unread-visual-emergency')),
        findsNothing);
    expect(find.text('MỚI'), findsOneWidget);
    expect(
        appState.notifications.firstWhere((n) => n.id == 'visual-quote').read,
        isTrue);
    await close(tester);
  });

  testWidgets(
      'Existing bottom navigation shows once and each tab returns to the same shell without losing active order',
      (tester) async {
    await host(tester, shell: true);
    final active = appState.acceptOffer(appState.nextOffer(serviceIndex: 0));
    for (final tab in [1, 2, 3, 0]) {
      appState.setTab(0);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thông báo'));
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNav), findsOneWidget);
      final nav = tester.widget<AppBottomNav>(find.byType(AppBottomNav));
      expect(nav.currentIndex, 0);
      expect(nav.inactiveLabelWeight, FontWeight.w500);
      await tester.tap(find.descendant(
          of: find.byType(AppBottomNav),
          matching:
              find.text(['Trang chủ', 'Đơn hàng', 'Ví', 'Tài khoản'][tab])));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsNothing);
      expect(find.byType(MechanicShell), findsOneWidget);
      expect(appState.tabIndex, tab);
      expect(appState.activeOrder, same(active));
      expect(
          tester
              .widget<AppBottomNav>(find.byType(AppBottomNav))
              .inactiveLabelWeight,
          FontWeight.w400);
    }
    await close(tester);
    appState.activeOrder = null;
  });

  testWidgets(
      'Vector symbols, chevrons and navy Montserrat headings render every reference category',
      (tester) async {
    await host(tester);
    final title = tester.widget<Text>(find.text('Thông báo'));
    expect(title.style!.fontFamily, 'Montserrat');
    expect(title.style!.fontSize, 22);
    expect(title.style!.color, const Color(0xFF14213D));
    for (final n in appState.notifications) {
      final card = find.byKey(ValueKey('notification-${n.id}'));
      await tester.scrollUntilVisible(card, 140,
          scrollable: find
              .descendant(
                  of: find.byKey(const ValueKey('notification-list')),
                  matching: find.byType(Scrollable))
              .first);
      final glyph = tester.widget<NotificationGlyph>(
          find.byKey(ValueKey('notification-icon-${n.id}')));
      expect(glyph.color, const Color(0xFF317CBB));
      expect(glyph.type, n.type);
      expect(
          find.byKey(ValueKey('notification-chevron-${n.id}')), findsOneWidget);
      final shape =
          tester.widget<Material>(card).shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(17));
      expect(shape.side.color, const Color(0xFFE5EBF2));
      expect(tester.takeException(), isNull);
    }
    await close(tester);
  });

  test(
      'Previous calendar week timestamps keep actual weekday and time, even more than seven days old',
      () {
    expect(
        notificationTime(
            DateTime(2026, 10, 8, 14, 10), DateTime(2026, 10, 16, 12)),
        'Thứ 5 · 14:10');
    expect(
        notificationTime(
            DateTime(2026, 10, 6, 18, 40), DateTime(2026, 10, 16, 12)),
        'Thứ 3 · 18:40');
    expect(
        notificationTime(
            DateTime(2026, 9, 30, 18, 40), DateTime(2026, 10, 16, 12)),
        '30/09/2026 · 18:40');
  });

  for (final config in [
    (const Size(412, 915), 1.0),
    (const Size(320, 568), 1.6)
  ]) {
    testWidgets(
        'Reference fixture renders chips, six cards and reserved navigation ${config.$1} x ${config.$2}',
        (tester) async {
      await host(tester, size: config.$1, scale: config.$2);
      const output = String.fromEnvironment('REVO_NOTIFICATION_CAPTURE');
      if (output.isNotEmpty) {
        final boundary = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
            key: boundary,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(),
                home: const NotificationsScreen(),
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(config.$2)),
                    child: child!))));
        await tester.pumpAndSettle();
        final renderer = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final png = await renderer.toImage(pixelRatio: 2);
          final bytes = await png.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory(output)..createSync(recursive: true);
          File('${dir.path}/reference-${config.$1.width.toInt()}-${config.$2}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          png.dispose();
        });
      }
      await tester.ensureVisible(
          find.byKey(const ValueKey('notification-chip-messages')));
      for (var i = 0; i < 7; i++) {
        expect(tester.takeException(), isNull);
        await tester.drag(find.byKey(const ValueKey('notification-list')),
            const Offset(0, -260));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(AppBottomNav), findsOneWidget);
      await close(tester);
    });
  }
}
