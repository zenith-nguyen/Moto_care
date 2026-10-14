import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_chat_data.dart';
import '../models/chat_conversation.dart';
import '../models/admin_message.dart';

final chatConversationsProvider = Provider<List<ChatConversation>>(
  (ref) => List.unmodifiable(mockRescueConversations),
);
final chatSupportMessagesProvider = Provider<List<AdminMessage>>(
  (ref) => demoSupportMessages,
);
final chatNotificationsProvider = Provider<List<AdminMessage>>(
  (ref) => demoAdminNotifications,
);
