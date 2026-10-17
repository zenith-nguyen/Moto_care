import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../../messages/application/customer_chat_controller.dart';
import '../../messages/application/customer_chat_state.dart';
import '../../messages/data/chat_image_picker.dart';
import '../../messages/domain/chat_message.dart' as api;

final chatMessagesProvider = NotifierProvider.autoDispose
    .family<ChatMessagesController, List<ChatMessage>, ChatConversation>(
      ChatMessagesController.new,
    );

class ChatMessagesController extends Notifier<List<ChatMessage>> {
  ChatMessagesController(this.conversation);
  final ChatConversation conversation;
  final _pendingReplies = <Timer>{};
  final _imageCache = <int, Uint8List>{};
  @override
  List<ChatMessage> build() {
    ref.onDispose(() {
      for (final timer in _pendingReplies) {
        timer.cancel();
      }
      _pendingReplies.clear();
    });
    if (conversation.orderId != null) {
      ref.listen<AsyncValue<CustomerChatState>>(
        customerChatControllerProvider(conversation.orderId!),
        (_, next) => next.whenData((value) => unawaited(_sync(value))),
        fireImmediately: true,
      );
      return const [];
    }
    // Legacy sample conversations are retained only as isolated test fixtures.
    return List.unmodifiable([
      ChatMessage.text(
        conversation.lastMessage,
        isCustomer: false,
        timeLabel: conversation.timeLabel,
      ),
    ]);
  }

  Future<bool> sendText(String input) async {
    final message = ref.read(chatServiceProvider).textMessage(input);
    if (message == null) return false;
    if (conversation.orderId != null) {
      await ref
          .read(customerChatControllerProvider(conversation.orderId!).notifier)
          .sendText(message.text!);
      return ref
              .read(customerChatControllerProvider(conversation.orderId!))
              .value
              ?.lastFailure ==
          null;
    }
    _send(message);
    return true;
  }

  Future<void> sendImage(Uint8List bytes) async {
    if (conversation.orderId == null) {
      _send(ref.read(chatServiceProvider).imageMessage(bytes));
      return;
    }
    final contentType = detectChatImageContentType(bytes);
    if (contentType == null) {
      throw const FormatException('Ảnh phải là JPEG, PNG hoặc WebP.');
    }
    final extension = switch (contentType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => throw const FormatException('Định dạng ảnh không được hỗ trợ.'),
    };
    await ref
        .read(customerChatControllerProvider(conversation.orderId!).notifier)
        .sendImage(
          api.ChatImageUpload(
            bytes: bytes,
            filename:
                'chat-${DateTime.now().microsecondsSinceEpoch}.$extension',
            contentType: contentType,
          ),
        );
  }

  Future<void> _sync(CustomerChatState source) async {
    final orderId = conversation.orderId;
    if (orderId == null) return;
    final controller = ref.read(
      customerChatControllerProvider(orderId).notifier,
    );
    final mapped = await Future.wait(
      source.messages.map((message) async {
        Uint8List? bytes = _imageCache[message.id];
        if (message.image != null) {
          try {
            bytes ??= (await controller.loadImage(message.id)).bytes;
            _imageCache[message.id] = bytes;
          } catch (_) {
            // Text still renders when a protected attachment cannot be loaded.
          }
        }
        return ChatMessage(
          text:
              message.content ??
              (message.image != null && bytes == null
                  ? 'Không thể tải hình ảnh'
                  : null),
          imageBytes: bytes,
          isCustomer: message.senderId == conversation.customerId,
          timeLabel: _timeLabel(message.createdAt),
        );
      }),
    );
    if (ref.mounted) state = List.unmodifiable(mapped);
  }

  String _timeLabel(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  void _send(ChatMessage message) {
    state = List.unmodifiable([...state, message]);
    late final Timer timer;
    timer = ref.read(chatServiceProvider).simulateReply((reply) {
      _pendingReplies.remove(timer);
      if (ref.mounted) state = List.unmodifiable([...state, reply]);
    });
    _pendingReplies.add(timer);
  }
}
