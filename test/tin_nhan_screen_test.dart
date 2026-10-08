import 'package:moto_care/features/chat/data/demo_chat_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/home/theme/home_theme.dart';
import 'package:moto_care/features/chat/screens/chat_detail_screen.dart';
import 'package:moto_care/features/chat/screens/tin_nhan_screen.dart';
import 'package:moto_care/features/home/models/home_user.dart';
import 'package:moto_care/features/home/screens/trang_chu.dart';
import 'package:moto_care/features/home/widgets/home_bottom_navigation.dart';

Future<void> _openMessages(
  WidgetTester tester, {
  Future<bool> Function(Uri)? launchPhone,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: launchPhone == null
            ? const TinNhanScreen()
            : TinNhanScreen(launchPhone: launchPhone),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<GoRouter> _openRouter(WidgetTester tester, String location) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ),
  );
  router.go(
    location,
    extra: location == '/trang-chu'
        ? const HomeUser(displayName: 'Nguyễn Văn An', memberId: '15335206')
        : null,
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('Rescue tab opens by default with mechanic and order details', (
    tester,
  ) async {
    await _openMessages(tester);

    for (final label in ['Cứu hộ', 'Hỗ trợ CSKH', 'Thông báo']) {
      expect(find.widgetWithText(Tab, label), findsOneWidget);
    }
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      HomeColors.background,
    );
    expect(find.text('Nguyễn Minh Tuấn'), findsOneWidget);
    expect(find.text('59-X1 123.45'), findsWidgets);
    expect(find.text('14:32'), findsOneWidget);
    expect(
      find.text(mockRescueConversations.first.lastMessage),
      findsOneWidget,
    );
    expect(find.byTooltip('Gọi Nguyễn Minh Tuấn'), findsOneWidget);
    final arriving = tester.widget<Chip>(
      find.widgetWithText(Chip, 'Đang đến - 5 phút'),
    );
    final completed = tester.widget<Chip>(
      find.widgetWithText(Chip, 'Đã hoàn tất').first,
    );
    expect(arriving.backgroundColor, HomeColors.red);
    expect(completed.backgroundColor, const Color(0xFF218653));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Support and notification tabs display their admin messages', (
    tester,
  ) async {
    await _openMessages(tester);
    await tester.tap(find.widgetWithText(Tab, 'Hỗ trợ CSKH'));
    await tester.pumpAndSettle();
    expect(find.text('CSKH MotoCare'), findsOneWidget);
    expect(find.text('Hỗ trợ đơn cứu hộ'), findsOneWidget);
    expect(find.text('Nguyễn Minh Tuấn'), findsNothing);

    await tester.tap(find.widgetWithText(Tab, 'Thông báo'));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng đến với MotoCare'), findsOneWidget);
    expect(find.text('Đơn cứu hộ đã hoàn tất'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Cứu hộ'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh Tuấn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Account opens messages and navigation returns to the same home',
    (tester) async {
      await _openRouter(tester, '/trang-chu');
      await tester.tap(find.text('Tài khoản'));
      await tester.pumpAndSettle();
      final messages = find.byKey(const ValueKey('account-messages'));
      final accountScroll = find.byKey(const ValueKey('account-scroll'));
      for (
        var attempt = 0;
        messages.hitTestable().evaluate().isEmpty && attempt < 20;
        attempt++
      ) {
        await tester.drag(accountScroll, const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      expect(messages.hitTestable(), findsOneWidget);
      await tester.tap(messages.hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(TinNhanScreen), findsOneWidget);
      expect(find.byType(TrangChu), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(HomeBottomNavigation),
          matching: find.text('Trang chủ'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TrangChu), findsOneWidget);
      expect(find.text('Chào Nguyễn Văn An'), findsOneWidget);
      expect(find.byType(TinNhanScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Conversation opens chat-detail with the selected mechanic', (
    tester,
  ) async {
    final router = await _openRouter(tester, '/tin-nhan');
    await tester.tap(find.text('Trần Quốc Bảo'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/chat-detail');
    expect(find.byType(ChatDetailScreen), findsOneWidget);
    expect(find.text('Trần Quốc Bảo'), findsOneWidget);
    expect(find.text(mockRescueConversations[1].lastMessage), findsOneWidget);
    expect(find.text('Nguyễn Minh Tuấn'), findsNothing);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(TinNhanScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Phone button launches the selected number without opening chat',
    (tester) async {
      final calls = <Uri>[];
      await _openMessages(
        tester,
        launchPhone: (uri) async {
          calls.add(uri);
          return true;
        },
      );
      await tester.tap(find.byTooltip('Gọi Trần Quốc Bảo'));
      await tester.pumpAndSettle();
      expect(calls, [Uri.parse('tel:0900000002')]);
      expect(find.byType(TinNhanScreen), findsOneWidget);
      expect(find.byType(ChatDetailScreen), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final throwsException in [false, true]) {
    testWidgets(
      'Phone launch ${throwsException ? 'exception' : 'failure'} gives a fallback number',
      (tester) async {
        await _openMessages(
          tester,
          launchPhone: (uri) async {
            if (throwsException) throw PlatformException(code: 'unavailable');
            return false;
          },
        );
        await tester.tap(find.byTooltip('Gọi Nguyễn Minh Tuấn'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Không thể mở ứng dụng gọi điện. Bạn có thể gọi số 0900000001.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Chat-detail without a conversation can return to messages', (
    tester,
  ) async {
    await _openRouter(tester, '/chat-detail');
    expect(
      find.text('Chọn một cuộc trò chuyện trong Tin nhắn để xem chi tiết.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(TinNhanScreen), findsOneWidget);

    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    expect(find.byType(TrangChu), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Narrow screens allow large text and scrolling in all tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openMessages(tester);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Phạm Đức Huy'),
      100,
      scrollable: find
          .descendant(
            of: find.byType(TabBarView),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    expect(find.text('Phạm Đức Huy'), findsOneWidget);
    for (final label in ['Hỗ trợ CSKH', 'Thông báo']) {
      final tab = find.widgetWithText(Tab, label);
      await tester.ensureVisible(tab);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
