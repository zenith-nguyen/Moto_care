import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

final chatMessagesProvider = NotifierProvider.autoDispose
    .family<ChatMessagesController, List<ChatMessage>, ChatConversation>(
      ChatMessagesController.new,
    );

/// Demo messages and attachments live only while the conversation is open.
class ChatMessagesController extends Notifier<List<ChatMessage>> {
  ChatMessagesController(this.conversation);

  final ChatConversation conversation;
  final _random = Random();

  static const _replies = [
    'Ok bạn nhé, mình đang chạy tới gần đó rồi!',
    'Bạn chờ mình 3 phút nhé!',
    'Mình đã nhận được thông tin, bạn chờ ở vị trí đã ghim nhé!',
  ];

  @override
  List<ChatMessage> build() => List.unmodifiable([
    ChatMessage.text(
      conversation.lastMessage,
      isCustomer: false,
      timeLabel: conversation.timeLabel,
    ),
  ]);

  bool sendText(String text) {
    final value = text.trim();
    if (value.isEmpty) return false;
    _send(ChatMessage.text(value, isCustomer: true, timeLabel: _timeLabel()));
    return true;
  }

  void sendImage(Uint8List bytes) {
    _send(ChatMessage.image(bytes, isCustomer: true, timeLabel: _timeLabel()));
  }

  String _timeLabel() => DateFormat('HH:mm').format(DateTime.now());

  void _send(ChatMessage message) {
    state = List.unmodifiable([...state, message]);
    unawaited(_simulateReply());
  }

  Future<void> _simulateReply() async {
    final currentRef = ref;
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!currentRef.mounted) return;
    state = List.unmodifiable([
      ...state,
      ChatMessage.text(
        _replies[_random.nextInt(_replies.length)],
        isCustomer: false,
        timeLabel: _timeLabel(),
      ),
    ]);
  }
}
