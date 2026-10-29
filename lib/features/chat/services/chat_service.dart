import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/service_actions.dart';
import '../models/chat_message.dart';

final chatClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(
    clock: ref.watch(chatClockProvider),
    launch: ref.watch(serviceUrlLauncherProvider),
  ),
);

class ChatService {
  ChatService({required this.clock, required this.launch});
  final DateTime Function() clock;
  final Future<bool> Function(Uri) launch;
  final _random = Random();
  static const _replies = [
    'Ok bạn nhé, mình đang chạy tới gần đó rồi!',
    'Bạn chờ mình 3 phút nhé!',
    'Mình đã nhận được thông tin, bạn chờ ở vị trí đã ghim nhé!',
  ];
  String _timeLabel() => DateFormat('HH:mm').format(clock());
  ChatMessage? textMessage(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    return ChatMessage.text(text, isCustomer: true, timeLabel: _timeLabel());
  }

  ChatMessage imageMessage(Uint8List bytes) => ChatMessage.image(
    Uint8List.fromList(bytes).asUnmodifiableView(),
    isCustomer: true,
    timeLabel: _timeLabel(),
  );
  Timer simulateReply(void Function(ChatMessage) deliver) => Timer(
    const Duration(seconds: 2),
    () => deliver(
      ChatMessage.text(
        _replies[_random.nextInt(_replies.length)],
        isCustomer: false,
        timeLabel: _timeLabel(),
      ),
    ),
  );
  Future<bool> call(
    String phone, {
    Future<bool> Function(Uri)? launcher,
  }) async {
    try {
      return await (launcher ?? launch)(Uri(scheme: 'tel', path: phone));
    } on Exception {
      return false;
    }
  }
}
