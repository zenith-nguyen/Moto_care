import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

final chatMessagesProvider = NotifierProvider.autoDispose
    .family<ChatMessagesController, List<ChatMessage>, ChatConversation>(
      ChatMessagesController.new,
    );

/// Demo messages and attachments live only while the conversation is open.
class ChatMessagesController extends Notifier<List<ChatMessage>> {
  ChatMessagesController(this.conversation);
  final ChatConversation conversation;
  final _pendingReplies = <Timer>{};
  @override
  List<ChatMessage> build() {
    ref.onDispose(() {
      for (final timer in _pendingReplies) {
        timer.cancel();
      }
      _pendingReplies.clear();
    });
    return List.unmodifiable([
      ChatMessage.text(
        conversation.lastMessage,
        isCustomer: false,
        timeLabel: conversation.timeLabel,
      ),
    ]);
  }

  bool sendText(String input) {
    final message = ref.read(chatServiceProvider).textMessage(input);
    if (message == null) return false;
    _send(message);
    return true;
  }

  void sendImage(Uint8List bytes) =>
      _send(ref.read(chatServiceProvider).imageMessage(bytes));
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
