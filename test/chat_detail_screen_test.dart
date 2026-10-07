import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/widgets/photo_attachment_field.dart';
import 'package:moto_care/features/chat/models/chat_conversation.dart';
import 'package:moto_care/features/chat/models/chat_message.dart';
import 'package:moto_care/features/chat/providers/chat_messages_provider.dart';
import 'package:moto_care/features/chat/screens/chat_detail_screen.dart';
import 'package:moto_care/features/chat/theme/chat_theme.dart';
import 'package:moto_care/features/chat/widgets/chat_message_bubble.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<ProviderContainer> _open(
  WidgetTester tester, {
  Future<Uint8List?> Function()? camera,
  Future<Uint8List?> Function()? gallery,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cameraAttachmentPickerProvider.overrideWithValue(
          camera ?? () async => null,
        ),
        attachmentPickerProvider.overrideWithValue(gallery ?? () async => null),
      ],
      child: MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ChatDetailScreen(conversation: mockRescueConversations.first),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(ChatDetailScreen)),
  );
}

List<ChatMessage> _messages(ProviderContainer container) =>
    container.read(chatMessagesProvider(mockRescueConversations.first));

Future<void> _choosePhoto(WidgetTester tester, String source) async {
  await tester.tap(_key('chat-camera'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(source));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Text sends immediately and receives one reply after two seconds',
    (tester) async {
      final container = await _open(tester);
      expect(tester.widget<IconButton>(_key('chat-send')).onPressed, isNull);
      await tester.enterText(_key('chat-input'), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(_messages(container), hasLength(1));
      expect(tester.widget<IconButton>(_key('chat-send')).onPressed, isNull);

      await tester.enterText(_key('chat-input'), '  Xe ở cổng màu xanh  ');
      await tester.pump();
      expect(tester.widget<IconButton>(_key('chat-send')).onPressed, isNotNull);
      expect(
        tester.widget<IconButton>(_key('chat-send')).color,
        ChatTheme.messageRed,
      );
      await tester.tap(_key('chat-send'));
      await tester.pump();
      expect(_messages(container), hasLength(2));
      expect(_messages(container).last.text, 'Xe ở cổng màu xanh');
      expect(_messages(container).last.isCustomer, isTrue);
      expect(
        tester.widget<TextField>(_key('chat-input')).controller!.text,
        isEmpty,
      );

      final customerBubble = find.byType(ChatMessageBubble).last;
      final customerAlignment = tester.widget<Align>(
        find.descendant(of: customerBubble, matching: find.byType(Align)),
      );
      expect(customerAlignment.alignment, Alignment.centerRight);
      final customerContainer = tester.widget<Container>(
        find.descendant(of: customerBubble, matching: find.byType(Container)),
      );
      expect(
        (customerContainer.decoration! as BoxDecoration).color,
        ChatTheme.messageRed,
      );

      await tester.pump(const Duration(milliseconds: 1999));
      expect(_messages(container), hasLength(2));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(_messages(container), hasLength(3));
      expect(_messages(container).last.isCustomer, isFalse);
      expect(_messages(container).last.text, isNotEmpty);
      final mechanicBubble = find.byType(ChatMessageBubble).last;
      expect(
        tester
            .widget<Align>(
              find.descendant(of: mechanicBubble, matching: find.byType(Align)),
            )
            .alignment,
        Alignment.centerLeft,
      );
      final mechanicDecoration =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: mechanicBubble,
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(mechanicDecoration.color, Colors.white);
      expect(mechanicDecoration.border, Border.all(color: ChatTheme.border));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Keyboard send submits text and ignores a second empty submit', (
    tester,
  ) async {
    final container = await _open(tester);
    await tester.enterText(_key('chat-input'), 'Tôi ở đây');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    expect(_messages(container), hasLength(2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(_messages(container), hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('All horizontal quick replies send without overwriting a draft', (
    tester,
  ) async {
    final container = await _open(tester);
    await tester.enterText(_key('chat-input'), 'Tin nhắn đang soạn');
    for (final text in [
      'Tôi đang ở đúng vị trí ghim',
      'Anh đến đâu rồi?',
      'Xe tôi bị thủng lốp / không nổ máy',
    ]) {
      final chip = find.widgetWithText(ActionChip, text);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pump();
      expect(_messages(container).last.text, text);
      expect(_messages(container).last.isCustomer, isTrue);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(_messages(container).last.isCustomer, isFalse);
    }
    expect(_messages(container), hasLength(7));
    expect(
      tester.widget<TextField>(_key('chat-input')).controller!.text,
      'Tin nhắn đang soạn',
    );
    expect(
      tester
          .widget<SingleChildScrollView>(_key('chat-quick-replies'))
          .scrollDirection,
      Axis.horizontal,
    );
    expect(tester.takeException(), isNull);
  });

  for (final source in ['Chụp ảnh', 'Chọn từ thư viện']) {
    testWidgets('$source sends an image and receives an automatic reply', (
      tester,
    ) async {
      final bytes = (await rootBundle.load('assets/images/Logo_motocare.png'))
          .buffer
          .asUint8List();
      var cameraCalls = 0;
      var galleryCalls = 0;
      final container = await _open(
        tester,
        camera: () async {
          cameraCalls++;
          return bytes;
        },
        gallery: () async {
          galleryCalls++;
          return bytes;
        },
      );
      await _choosePhoto(tester, source);
      expect(cameraCalls, source == 'Chụp ảnh' ? 1 : 0);
      expect(galleryCalls, source == 'Chọn từ thư viện' ? 1 : 0);
      expect(_messages(container), hasLength(2));
      expect(_messages(container).last.imageBytes, orderedEquals(bytes));
      expect(_messages(container).last.isCustomer, isTrue);
      expect(find.byType(Image), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(_messages(container), hasLength(3));
      expect(_messages(container).last.isCustomer, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Dismissing photo choices or cancelling the picker sends nothing',
    (tester) async {
      var calls = 0;
      final container = await _open(
        tester,
        gallery: () async {
          calls++;
          return null;
        },
      );
      await tester.tap(_key('chat-camera'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 100));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await _choosePhoto(tester, 'Chọn từ thư viện');
      expect(calls, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(_messages(container), hasLength(1));
      expect(
        tester.widget<IconButton>(_key('chat-camera')).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final source in ['Chụp ảnh', 'Chọn từ thư viện']) {
    testWidgets(
      '$source failure restores the composer without creating a reply',
      (tester) async {
        Future<Uint8List?> fail() async =>
            throw PlatformException(code: 'access_denied');
        final container = await _open(tester, camera: fail, gallery: fail);
        await _choosePhoto(tester, source);
        expect(
          find.text(
            source == 'Chụp ảnh'
                ? 'Không thể mở camera. Vui lòng kiểm tra quyền truy cập.'
                : 'Không thể mở thư viện ảnh. Vui lòng kiểm tra quyền truy cập.',
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<IconButton>(_key('chat-camera')).onPressed,
          isNotNull,
        );
        await tester.pump(const Duration(seconds: 2));
        expect(_messages(container), hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Leaving during photo picking and a pending reply is safe', (
    tester,
  ) async {
    final pending = Completer<Uint8List?>();
    await _open(tester, camera: () => pending.future);
    await tester.enterText(_key('chat-input'), 'Bạn đến đâu rồi?');
    await tester.tap(_key('chat-send'));
    await tester.pump();
    await tester.tap(_key('chat-camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chụp ảnh'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<IconButton>(_key('chat-camera')).onPressed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    pending.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Messages and replies scroll to the end above a small-screen keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = await _open(tester);
      await tester.tap(_key('chat-input'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        await tester.enterText(_key('chat-input'), 'Tin nhắn $i');
        await tester.pump();
        await tester.tap(_key('chat-send'));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      final controller = tester
          .widget<ListView>(_key('chat-message-list'))
          .controller!;
      expect(
        controller.offset,
        closeTo(controller.position.maxScrollExtent, 1),
      );
      expect(find.text('Tin nhắn 7').hitTestable(), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(_messages(container), hasLength(17));
      expect(
        controller.offset,
        closeTo(controller.position.maxScrollExtent, 1),
      );
      final lastBubble = _key('chat-message-16');
      expect(
        find
            .descendant(of: lastBubble, matching: find.byType(Text))
            .last
            .hitTestable(),
        findsOneWidget,
      );
      expect(_key('chat-camera').hitTestable(), findsOneWidget);
      expect(_key('chat-input').hitTestable(), findsOneWidget);
      expect(_key('chat-send').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
