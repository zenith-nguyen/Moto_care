import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/screens/support_chat_screen.dart';
import 'package:motocare_mechanic/screens/support_screen.dart';
import 'package:motocare_mechanic/services/support_assistant.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/state/support_chat_controller.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';

class _Flaky implements SupportAssistant {
  bool fail = true;
  @override
  bool get isLive => false;
  @override
  Future<List<AssistantReply>> reply(String m) async {
    if (fail) throw Exception('down');
    return const [AssistantReply('Đã nhận.')];
  }
}

void main() {
  final boundary = GlobalKey();

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
  SupportChatController fresh([SupportAssistant? a]) => SupportChatController(
      a ?? MockSupportAssistant(delay: const Duration(milliseconds: 50)),
      userName: () => 'Võ Thành Đạt');

  Future<void> say(WidgetTester t, String text) async {
    await t.enterText(k('chat-input'), text);
    await t.pump();
    await t.tap(k('chat-send'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpAndSettle();
  }

  group('Support centre', () {
    testWidgets('copy, fonts, colours', (t) async {
      await host(t, const SupportScreen());
      expect(find.text('Trung tâm hỗ trợ'), findsOneWidget);
      expect(find.text('Bạn cần giúp gì?'), findsOneWidget);
      expect(find.text('Tìm câu trả lời nhanh hoặc nhắn cho đội REVO.'),
          findsOneWidget);
      expect(find.text('Vẫn chưa giải quyết được?'), findsOneWidget);
      expect(find.text('Trả lời ngay, cả ngoài giờ'), findsOneWidget);
      expect(find.text('Cho các trường hợp cần người xử lý'), findsOneWidget);
      final title = t.widget<Text>(find.text('Bạn cần giúp gì?')).style!;
      expect(title.color, const Color(0xFF000000));
      expect(title.fontFamily, 'Montserrat');
      final q = t.widget<Text>(find.text('Khách chưa cung cấp mã xác nhận?'));
      expect(q.style!.color, const Color(0xFF000000));
      final tab = t.widget<AnimatedContainer>(k('support-tab-0'));
      expect((tab.decoration as BoxDecoration).color, const Color(0xFF317CBB));
      expect(t.widget<Text>(find.text('Đơn hàng')).style!.color, Colors.white);
      expect(find.text('Đơn hàng'), findsOneWidget);
      await shot(t, 'support-center');
    });

    testWidgets('tabs switch the list', (t) async {
      await host(t, const SupportScreen());
      expect(find.text('Rút tiền mất bao lâu?'), findsNothing);
      await t.tap(find.text('Thanh toán'));
      await t.pumpAndSettle();
      expect(find.text('Rút tiền mất bao lâu?'), findsOneWidget);
      expect(find.text('Khách chưa cung cấp mã xác nhận?'), findsNothing);
    });

    testWidgets('accordion opens one answer at a time', (t) async {
      await host(t, const SupportScreen());
      await t.tap(find.text('Khách chưa cung cấp mã xác nhận?'));
      await t.pumpAndSettle();
      expect(find.textContaining('Chỉ bắt đầu sửa khi đã xác nhận đúng mã.'),
          findsOneWidget);
      await t.tap(find.text('Khi nào được sửa hạng mục phát sinh?'));
      await t.pumpAndSettle();
      expect(find.textContaining('Chỉ bắt đầu sửa khi đã xác nhận đúng mã.'),
          findsNothing);
      expect(find.textContaining('chờ khách đồng ý'), findsOneWidget);
    });

    testWidgets('search filters with and without Vietnamese accents',
        (t) async {
      await host(t, const SupportScreen());
      for (final q in ['mã xác nhận', 'ma xac nhan']) {
        await t.enterText(k('support-search'), q);
        await t.pumpAndSettle();
        expect(find.text('Khách chưa cung cấp mã xác nhận?'), findsOneWidget);
        expect(find.text('Khi nào được sửa hạng mục phát sinh?'), findsNothing);
      }
      // The field keeps exactly what was typed (IME composition untouched).
      expect(t.widget<TextField>(k('support-search')).controller!.text,
          'ma xac nhan');
      await t.enterText(k('support-search'), 'zzzz');
      await t.pumpAndSettle();
      expect(k('support-empty'), findsOneWidget);
      await t.tap(find.byTooltip('Xóa'));
      await t.pumpAndSettle();
      expect(find.text('Khách chưa cung cấp mã xác nhận?'), findsOneWidget);
    });

    testWidgets('chat row opens the assistant; admin row is honest', (t) async {
      await host(t, const SupportScreen());
      await t.tap(k('support-contact-admin'));
      await t.pump();
      expect(find.textContaining('chưa được kết nối'), findsOneWidget);
      expect(find.byType(SupportChatScreen), findsNothing);
      await t.pumpAndSettle(const Duration(seconds: 5));
      await t.tap(k('support-open-chat'));
      await t.pumpAndSettle();
      expect(find.byType(SupportChatScreen), findsOneWidget);
    });
  });

  group('Assistant chat', () {
    testWidgets('opens with only the greeting, no pre-filled demo', (t) async {
      final c = fresh();
      await host(t, SupportChatScreen(controller: c));
      expect(c.messages, hasLength(1));
      expect(
          find.text(
              'Chào anh Đạt, mình là Trợ lý REVO. Anh cần hỏi về đơn hàng, thanh toán, hồ sơ thợ hay chuyện khác?'),
          findsOneWidget);
      expect(find.text('Trợ lý REVO'), findsOneWidget);
      expect(find.textContaining('Đã xem'), findsNothing);
      // Mock mode is stated, not disguised as a live 24/7 service.
      expect(find.text('Chế độ mô phỏng'), findsOneWidget);
      expect(find.text('R'), findsNothing);
      // Real robot asset: header + greeting bubble, no Material fallback icon.
      expect(find.byIcon(Icons.smart_toy_outlined), findsNothing);
      final avatars = t.widgetList<Image>(find.byType(Image)).where((i) =>
          i.image is AssetImage &&
          (i.image as AssetImage).assetName ==
              'assets/images/revo_chatbot_avatar.png');
      expect(avatars, hasLength(2));
      expect(
          (await rootBundle.load('assets/images/revo_chatbot_avatar.png'))
              .lengthInBytes,
          greaterThan(1000));
      expect(
          File('assets/images/revo_chatbot_avatar.png').existsSync(), isTrue);
      expect(find.byTooltip('Quay lại'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
      await shot(t, 'chat-open');
    });

    testWidgets('payment question: user right/blue, bot left/white, link',
        (t) async {
      final c = fresh();
      await host(t, SupportChatScreen(controller: c));
      await say(t, 'Tôi đã hoàn thành đơn nhưng chưa nhận được tiền?');
      final user = t.getRect(find.byKey(const ValueKey('bubble-user')));
      final bot = t.getRect(find.byKey(const ValueKey('bubble-bot')).last);
      expect(user.right, greaterThan(t.view.physicalSize.width - 24));
      expect(bot.left, lessThan(60));
      final ub = t.widget<Container>(find.byKey(const ValueKey('bubble-user')));
      expect((ub.decoration as BoxDecoration).color, const Color(0xFF317CBB));
      expect(
          find.textContaining('chưa được xác nhận là đã chi trả',
              findRichText: true),
          findsOneWidget);
      expect(find.text('Xem hướng dẫn thanh toán'), findsOneWidget);
      expect(c.waiting, isFalse);
      await shot(t, 'chat-conversation');
      await t.tap(k('action-openPaymentGuide'));
      await t.pumpAndSettle();
      expect(find.byType(SupportScreen), findsOneWidget);
      expect(find.text('Rút tiền mất bao lâu?'), findsOneWidget);
    });

    testWidgets('payout guide, Mở Ví Thợ goes to the wallet tab, thanks',
        (t) async {
      final c = fresh();
      appState.setTab(3);
      await host(t, SupportChatScreen(controller: c));
      await say(t, 'Cách gửi đề nghị chi trả?');
      expect(find.textContaining('Anh làm theo 3 bước', findRichText: true),
          findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await say(t, 'Cảm ơn bạn nhiều!');
      expect(find.text('Vẫn chưa nhận được tiền sau 24 giờ?'), findsOneWidget);
      expect(find.text('Gặp Admin'), findsWidgets);
      await shot(t, 'chat-payout-guide');
      final balance = appState.balance;
      await t.ensureVisible(k('action-openWallet'));
      await t.tap(k('action-openWallet'));
      await t.pumpAndSettle();
      expect(appState.tabIndex, 2);
      expect(appState.balance, balance);
    });

    testWidgets('chips send a real question; Gặp Admin is honest', (t) async {
      final c = fresh();
      await host(t, SupportChatScreen(controller: c));
      await t.tap(k('chat-chip-2'));
      await t.pump();
      await t.pumpAndSettle();
      expect(
          c.messages.where((m) => m.sender == ChatSender.user), hasLength(1));
      expect(find.textContaining('Không chia sẻ mã OTP', findRichText: true),
          findsOneWidget);
      final n = c.messages.length;
      await t.tap(k('chat-chip-3'));
      await t.pump();
      expect(c.messages.length, n);
      expect(find.textContaining('chưa được kết nối'), findsOneWidget);
      await t.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('empty text is never sent; Vietnamese text is kept', (t) async {
      final c = fresh();
      await host(t, SupportChatScreen(controller: c));
      await t.enterText(k('chat-input'), '   ');
      await t.pump();
      await t.tap(k('chat-send'));
      await t.pump();
      expect(c.messages, hasLength(1));
      await t.enterText(k('chat-input'), 'Tôi muốn rút tiền');
      expect(t.widget<TextField>(k('chat-input')).controller!.text,
          'Tôi muốn rút tiền');
      await t.pump();
      await t.tap(k('chat-send'));
      await t.pump();
      expect(find.byKey(const ValueKey('chat-typing')), findsOneWidget);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-typing')), findsNothing);
      expect(t.widget<TextField>(k('chat-input')).controller!.text, '');
    });

    testWidgets('failure shows retry and recovers', (t) async {
      final a = _Flaky();
      final c = fresh(a);
      await host(t, SupportChatScreen(controller: c));
      await say(t, 'Xin chào');
      expect(find.text('Thử lại'), findsOneWidget);
      a.fail = false;
      await t.tap(k('chat-retry'));
      await t.pumpAndSettle();
      expect(find.text('Thử lại'), findsNothing);
      expect(find.text('Đã nhận.'), findsOneWidget);
      expect(
          c.messages.where((m) => m.sender == ChatSender.user), hasLength(1));
    });

    testWidgets('menu starts a new conversation and explains mock mode',
        (t) async {
      final c = fresh();
      await host(t, SupportChatScreen(controller: c));
      await say(t, 'Xin chào');
      await t.tap(find.byIcon(Icons.more_horiz_rounded));
      await t.pumpAndSettle();
      await t.tap(find.text('Thông tin về Trợ lý REVO'));
      await t.pumpAndSettle();
      expect(find.textContaining('chưa kết nối dịch vụ AI'), findsOneWidget);
      await t.tap(find.text('Đóng'));
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.more_horiz_rounded));
      await t.pumpAndSettle();
      await t.tap(find.text('Cuộc trò chuyện mới'));
      await t.pumpAndSettle();
      expect(c.messages, hasLength(1));
    });

    testWidgets('plus menu: FAQ and new conversation both work', (t) async {
      final c = fresh();
      await host(t, SupportChatScreen(controller: c));
      await say(t, 'Xin chào');
      await t.tap(k('chat-plus'));
      await t.pumpAndSettle();
      await t.tap(k('plus-new'));
      await t.pumpAndSettle();
      expect(c.messages, hasLength(1));
      await t.tap(k('chat-plus'));
      await t.pumpAndSettle();
      await t.tap(k('plus-faq'));
      await t.pumpAndSettle();
      expect(find.byType(SupportScreen), findsOneWidget);
    });

    testWidgets('input stays above the keyboard', (t) async {
      final c = fresh();
      await host(t, SupportChatScreen(controller: c));
      t.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(t.view.resetViewInsets);
      await t.pumpAndSettle();
      expect(t.getRect(k('chat-input')).bottom, lessThanOrEqualTo(915 - 300));
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
      await host(t, const SupportScreen(), size: c.$1, scale: c.$2);
      expect(t.takeException(), isNull);
      await t.tap(find.text('Khách chưa cung cấp mã xác nhận?'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final ctl = fresh();
      await host(t, SupportChatScreen(controller: ctl),
          size: c.$1, scale: c.$2);
      await say(t, 'Tôi đã hoàn thành đơn nhưng chưa nhận được tiền?');
      await say(t, 'Cách gửi đề nghị chi trả?');
      await say(t, 'Cảm ơn bạn nhiều!');
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
