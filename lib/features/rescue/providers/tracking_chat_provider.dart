import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/models/chat_message.dart';
import '../../chat/services/chat_service.dart';
import 'order_tracking_provider.dart';

final trackingChatProvider = NotifierProvider.autoDispose
    .family<TrackingChatController, List<ChatMessage>, TrackingKey>(
      TrackingChatController.new,
    );

class TrackingChatController extends Notifier<List<ChatMessage>> {
  TrackingChatController(this.key);
  final TrackingKey key;
  @override
  List<ChatMessage> build() => const [];
  bool send(String input) {
    final message = ref.read(chatServiceProvider).textMessage(input);
    if (message == null) return false;
    state = List.unmodifiable([...state, message]);
    return true;
  }
}
