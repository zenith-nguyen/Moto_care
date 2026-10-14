import '../domain/chat_message.dart';

enum CustomerChatAction { refresh, send }

class CustomerChatState {
  const CustomerChatState({
    required this.messages,
    this.action,
    this.lastFailure,
  });

  final List<ChatMessage> messages;
  final CustomerChatAction? action;
  final Object? lastFailure;

  bool get isBusy => action != null;

  CustomerChatState copyWith({
    List<ChatMessage>? messages,
    Object? action = _unchanged,
    Object? lastFailure = _unchanged,
  }) {
    return CustomerChatState(
      messages: messages ?? this.messages,
      action: identical(action, _unchanged)
          ? this.action
          : action as CustomerChatAction?,
      lastFailure: identical(lastFailure, _unchanged)
          ? this.lastFailure
          : lastFailure,
    );
  }
}

const _unchanged = Object();
