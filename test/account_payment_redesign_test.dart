import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/models/payout_request.dart';
import 'package:motocare_mechanic/screens/mechanic_account_screen.dart';
import 'package:motocare_mechanic/screens/order_history_detail_screen.dart';
import 'package:motocare_mechanic/screens/payment_tracking_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/utils/format.dart';
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
    appState.setTab(3);
  });

  Future<void> host(WidgetTester t, Widget page,
      {Size size = const Size(412, 915), double scale = 1}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          theme: buildAppTheme(),
          builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: page,
        )));
    await t.pumpAndSettle();
  }

  Future<void> shot(WidgetTester t, String name) async {
    const output = String.fromEnvironment('REVO_HOME_PIXELS_CAPTURE');
    if (output.isEmpty) return;
    await t.runAsync(() async {
      final r =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final png = await r.toImage(pixelRatio: 2);
      final b = await png.toByteData(format: ui.ImageByteFormat.png);
      Directory(output).createSync(recursive: true);
      File('$output/$name.png').writeAsBytesSync(b!.buffer.asUint8List());
    });
  }

  Finder k(String key) => find.byKey(ValueKey(key));

  PayoutRequest req(PayoutStatus s) => PayoutRequest(
      id: '#PO9',
      orderCode: '#RVO2298',
      amount: 112000,
      serviceName: 'Xẹp lốp',
      status: s,
      receivedAt: DateTime(2026, 10, 19, 10, 12),
      processingAt:
          s == PayoutStatus.received ? null : DateTime(2026, 10, 19, 10, 18),
      resolvedAt: s == PayoutStatus.paid || s == PayoutStatus.rejected
          ? DateTime(2026, 10, 19, 11, 2)
          : null,
      rejectReason: s == PayoutStatus.rejected ? 'Thiếu chứng từ.' : null);

  List<Color?> dotFills(WidgetTester t, String key) => [
        for (final w in t.widgetList<AnimatedContainer>(find.descendant(
            of: k(key), matching: find.byType(AnimatedContainer))))
          if ((w.decoration as BoxDecoration?)?.shape == BoxShape.circle)
            (w.decoration as BoxDecoration).color
      ];

  group('Account', () {
    testWidgets('profile identity, stats and fonts', (t) async {
      await host(t, const Scaffold(body: MechanicAccountScreen()));
      expect(find.text('Võ Thành Đạt'), findsOneWidget);
      expect(find.text('Nguyễn Văn Hùng'), findsNothing);
      final img = t.widget<Image>(find
          .descendant(of: k('profile-avatar'), matching: find.byType(Image))
          .first);
      expect((img.image as AssetImage).assetName,
          'assets/images/mechanic_vo_thanh_dat.png');
      expect(img.fit, BoxFit.cover);
      expect(
          t
              .getSize(find.descendant(
                  of: k('profile-avatar'), matching: find.byType(ClipOval)))
              .width,
          76);
      expect(find.text('124'), findsOneWidget);
      expect(find.text(formatVnd(appState.monthIncome)), findsOneWidget);
      expect(find.text('Số liệu demo · Thu nhập tháng từ số giao dịch'),
          findsOneWidget);
      expect(t.widget<Text>(find.text('Tài khoản')).style!.fontFamily,
          'Montserrat');
      expect(t.widget<Text>(find.text('Sửa hồ sơ')).style!.color,
          AppColors.primary);
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing,
          reason: 'header has no notification button');
      expect(t.takeException(), isNull);
      await t.runAsync(() async {
        await precacheImage(
            const AssetImage('assets/images/mechanic_vo_thanh_dat.png'),
            t.element(k('profile-avatar')));
      });
      await t.pumpAndSettle();
      await shot(t, 'account-full');
    });

    testWidgets('profile rows use REVO blue icons and navigate', (t) async {
      await host(t, const Scaffold(body: MechanicAccountScreen()));
      for (final icon in [
        Icons.person_outline,
        Icons.badge_outlined,
        Icons.workspace_premium_outlined
      ]) {
        expect(t.widget<Icon>(find.byIcon(icon).first).color,
            const Color(0xFF317CBB));
      }
      // All four rows (incl. the wrench) are #317CBB on an #EAF3FA disc.
      final circles =
          t.widgetList<IconCircle>(find.byType(IconCircle)).where((c) =>
              const [
                Icons.person_outline,
                Icons.badge_outlined,
                Icons.workspace_premium_outlined,
              ].contains(c.icon) ||
              (c.icon == Icons.build_outlined && c.size == 36));
      expect(circles, hasLength(4));
      for (final c in circles) {
        expect(c.color, const Color(0xFF317CBB));
        expect(c.background, const Color(0xFFEAF3FA));
      }
      await t.tap(find.text('Thông tin cá nhân'));
      await t.pumpAndSettle();
      expect(find.byType(ProfileEditScreen), findsOneWidget);
    });

    testWidgets('quick actions: Đơn hàng and Ví switch tab', (t) async {
      await host(t, const Scaffold(body: MechanicAccountScreen()));
      await t.tap(find.text('Đơn hàng').first);
      expect(appState.tabIndex, 1);
      appState.setTab(3);
      await t.tap(find.text('Ví Thợ'));
      expect(appState.tabIndex, 2);
    });

    testWidgets('order timeline: latest completed order, 4 done, real times',
        (t) async {
      await host(t, const Scaffold(body: MechanicAccountScreen()));
      await t.ensureVisible(k('order-activity'));
      final o = appState.history.first;
      expect(t.widget<Text>(k('activity-code')).data, o.orderId);
      expect(find.text('Hoàn thành'), findsWidgets);
      for (var i = 0; i < 4; i++) {
        expect(find.text(formatHm(o.timeline[i].time)), findsWidgets);
      }
      expect(dotFills(t, 'order-stepper').where((c) => c == AppColors.primary),
          hasLength(4));
      await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
      await t.pumpAndSettle();
      await shot(t, 'account-activity');
    });

    testWidgets('order timeline follows the active order step', (t) async {
      appState.history.clear();
      final offer = MockData.offers.first;
      final a = ActiveOrder(
          offer: offer, acceptedAt: DateTime(2026, 10, 19, 9, 0), messages: []);
      appState.activeOrder = a;
      for (final c in [
        (OrderStep.received, 1),
        (OrderStep.arrived, 2),
        (OrderStep.repairing, 3),
        (OrderStep.completed, 4),
      ]) {
        a.step = c.$1;
        await t.pumpWidget(const SizedBox());
        await host(t, const Scaffold(body: MechanicAccountScreen()));
        await t.ensureVisible(k('order-activity'));
        expect(
            dotFills(t, 'order-stepper')
                .where((x) => x == AppColors.primary)
                .length,
            c.$2,
            reason: '${c.$1}');
      }
      // Times that were never recorded are not invented.
      expect(find.text('—'), findsWidgets);
      appState.activeOrder = null;
    });

    testWidgets('copy puts the order code on the clipboard', (t) async {
      String? copied;
      t.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      await host(t, const Scaffold(body: MechanicAccountScreen()));
      await t.ensureVisible(k('activity-copy'));
      await t.tap(k('activity-copy'));
      await t.pump();
      expect(copied, appState.history.first.orderId);
      await t.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('Xem tất cả opens the orders tab', (t) async {
      await host(t, const Scaffold(body: MechanicAccountScreen()));
      await t.ensureVisible(k('activity-see-all'));
      await t.tap(k('activity-see-all'));
      expect(appState.tabIndex, 1);
    });
  });

  group('Payment tracking', () {
    testWidgets('processing: amount, order code, 2 of 3 reached, banner',
        (t) async {
      await host(
          t, PaymentTrackingScreen(request: req(PayoutStatus.processing)));
      expect(find.text('ĐỀ NGHỊ CHI TRẢ'), findsOneWidget);
      expect(t.widget<Text>(k('pay-amount')).data, '112.000đ');
      expect(t.widget<Text>(k('pay-order-code')).data, '#RVO2298');
      expect(find.text('Đang xử lý'), findsWidgets);
      expect(find.text('10:12'), findsOneWidget);
      expect(find.text('10:18'), findsOneWidget);
      expect(find.text('Chưa có'), findsOneWidget);
      expect(t.widget<Text>(k('pay-banner')).data,
          'Khoản tiền chưa được ghi nhận là đã chi trả. Trạng thái sẽ cập nhật sau khi Admin xử lý.');
      final fills = dotFills(t, 'pay-stepper');
      expect(fills.where((c) => c == AppColors.primary), hasLength(2));
      expect(fills.where((c) => c == Colors.white), hasLength(1));
      expect(find.byType(Image), findsNothing);
      await shot(t, 'payment-processing');
    });

    testWidgets('received: only the first step is reached', (t) async {
      await host(t, PaymentTrackingScreen(request: req(PayoutStatus.received)));
      expect(dotFills(t, 'pay-stepper').where((c) => c == AppColors.primary),
          hasLength(1));
      expect(find.text('Chưa có'), findsNWidgets(2));
    });

    testWidgets('paid: all reached, no "not paid" wording', (t) async {
      await host(t, PaymentTrackingScreen(request: req(PayoutStatus.paid)));
      expect(dotFills(t, 'pay-stepper').where((c) => c == AppColors.primary),
          hasLength(3));
      expect(find.text('11:02'), findsOneWidget);
      expect(find.textContaining('chưa được ghi nhận'), findsNothing);
    });

    testWidgets('rejected is never shown as paid', (t) async {
      await host(t, PaymentTrackingScreen(request: req(PayoutStatus.rejected)));
      expect(find.text('Bị từ chối'), findsWidgets);
      expect(find.text('Đã xử lý'), findsNothing);
      expect(find.text('Thiếu chứng từ.'), findsOneWidget);
      expect(find.textContaining('chưa có khoản nào được chi trả'),
          findsOneWidget);
    });

    testWidgets('steps are not tappable and do not change data', (t) async {
      final balance = appState.balance;
      final tx = appState.transactions.length;
      await host(
          t, PaymentTrackingScreen(request: req(PayoutStatus.processing)));
      expect(
          find.descendant(of: k('pay-stepper'), matching: find.byType(InkWell)),
          findsNothing);
      await t.tap(find.text('Đã xử lý'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(find.text('Chưa có'), findsOneWidget);
      expect(appState.balance, balance);
      expect(appState.transactions.length, tx);
    });

    testWidgets('copy sends the request order code', (t) async {
      String? copied;
      t.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      await host(
          t, PaymentTrackingScreen(request: req(PayoutStatus.processing)));
      await t.tap(k('pay-copy'));
      await t.pump();
      expect(copied, '#RVO2298');
      await t.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('open related order uses the real order and keeps the wallet',
        (t) async {
      final balance = appState.balance;
      await host(
          t, PaymentTrackingScreen(request: req(PayoutStatus.processing)));
      expect(
          t
              .widget<FilledButton>(k('pay-open-order'))
              .style!
              .backgroundColor!
              .resolve({}),
          AppColors.primary);
      await t.tap(k('pay-open-order'));
      await t.pumpAndSettle();
      final page = t.widget<OrderHistoryDetailScreen>(
          find.byType(OrderHistoryDetailScreen));
      expect(page.item.orderId, '#RVO2298');
      expect(appState.balance, balance);
    });

    testWidgets('account links to the demo request', (t) async {
      await host(t, const Scaffold(body: MechanicAccountScreen()));
      await t.scrollUntilVisible(find.text('Theo dõi thanh toán'), 200,
          scrollable: find.byType(Scrollable).first);
      await t.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await t.pumpAndSettle();
      await t.tap(find.text('Theo dõi thanh toán'));
      await t.pumpAndSettle();
      expect(find.byType(PaymentTrackingScreen), findsOneWidget);
      expect(t.widget<Text>(k('pay-order-code')).data,
          appState.payoutRequests.first.orderCode);
    });
  });

  for (final c in [
    (const Size(320, 640), 1.0),
    (const Size(360, 780), 1.3),
    (const Size(393, 851), 1.0),
    (const Size(412, 915), 1.6),
    (const Size(320, 640), 1.6),
  ]) {
    testWidgets('No overflow ${c.$1} at ${c.$2}', (t) async {
      await host(t, const Scaffold(body: MechanicAccountScreen()),
          size: c.$1, scale: c.$2);
      expect(t.takeException(), isNull);
      await host(
          t, PaymentTrackingScreen(request: req(PayoutStatus.processing)),
          size: c.$1, scale: c.$2);
      expect(t.takeException(), isNull);
      await host(t, PaymentTrackingScreen(request: req(PayoutStatus.rejected)),
          size: c.$1, scale: c.$2);
      expect(t.takeException(), isNull);
      final clipped = <String>[];
      for (final e in find.byType(RichText).evaluate()) {
        final r = e.renderObject;
        if (r is RenderParagraph && r.didExceedMaxLines) {
          clipped.add(r.text.toPlainText());
        }
      }
      expect(clipped, isEmpty);
    });
  }
}
