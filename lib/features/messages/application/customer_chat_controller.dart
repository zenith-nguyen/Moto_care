import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/realtime/realtime_event.dart';
import '../domain/chat_message.dart';
import 'customer_chat_state.dart';

final customerChatControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CustomerChatController, CustomerChatState, int>(
      CustomerChatController.new,
    );

class CustomerChatController extends AsyncNotifier<CustomerChatState> {
  CustomerChatController(this.orderId);

  final int orderId;
  StreamSubscription<RealtimeEvent>? _eventSubscription;
  StreamSubscription? _resyncSubscription;
  Future<void>? _refreshInFlight;

  @override
  Future<CustomerChatState> build() async {
    if (orderId <= 0) throw ArgumentError.value(orderId, 'orderId');
    final realtime = ref.watch(realtimeClientProvider);
    _eventSubscription = realtime.events.listen(_handleRealtimeEvent);
    _resyncSubscription = realtime.resyncRequests.listen((request) {
      if (request.orderId == orderId) unawaited(_refreshSilently());
    });
    ref.onDispose(() {
      unawaited(_eventSubscription?.cancel());
      unawaited(_resyncSubscription?.cancel());
    });
    return CustomerChatState(
      messages: await ref.read(messagesRepositoryProvider).list(orderId),
    );
  }

  Future<void> refresh() => _runAction(CustomerChatAction.refresh, () async {
    final messages = await ref.read(messagesRepositoryProvider).list(orderId);
    state = AsyncData(_requireState().copyWith(messages: messages));
  });

  Future<void> sendText(String content) => _send(content: content);

  Future<void> sendImage(ChatImageUpload image, {String? content}) {
    return _send(content: content, image: image);
  }

  Future<ProtectedChatImage> loadImage(int messageId) {
    return ref
        .read(messagesRepositoryProvider)
        .loadImage(orderId: orderId, messageId: messageId);
  }

  Future<void> _send({String? content, ChatImageUpload? image}) {
    return _runAction(CustomerChatAction.send, () async {
      final message = await ref
          .read(messagesRepositoryProvider)
          .send(orderId: orderId, content: content, image: image);
      state = AsyncData(
        _requireState().copyWith(
          messages: _upsert(_requireState().messages, message),
        ),
      );
    });
  }

  Future<void> _runAction(
    CustomerChatAction action,
    Future<void> Function() operation,
  ) async {
    final current = state.value;
    if (current == null || current.isBusy) return;
    state = AsyncData(current.copyWith(action: action, lastFailure: null));
    try {
      await operation();
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(action: null, lastFailure: null));
      }
    } catch (error) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(action: null, lastFailure: error));
    }
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    if (event is! MessageCreated || event.orderId != orderId) return;
    final current = state.value;
    if (current == null) return;
    final image = event.image;
    final message = ChatMessage(
      id: event.id,
      senderId: event.senderId,
      content: event.content,
      image: image == null
          ? null
          : ChatMessageImage(
              url: image.url,
              mimeType: image.mimeType,
              sizeBytes: image.sizeBytes,
            ),
      createdAt: event.createdAt,
    );
    state = AsyncData(
      current.copyWith(messages: _upsert(current.messages, message)),
    );
  }

  Future<void> _refreshSilently() {
    return _refreshInFlight ??= _loadSilently().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<void> _loadSilently() async {
    try {
      final messages = await ref.read(messagesRepositoryProvider).list(orderId);
      final current = state.value;
      if (current != null) {
        state = AsyncData(current.copyWith(messages: messages));
      }
    } catch (_) {
      // Keep the latest valid history. Explicit refresh exposes the error.
    }
  }

  CustomerChatState _requireState() {
    final current = state.value;
    if (current == null) throw StateError('Customer chat is not loaded.');
    return current;
  }
}

List<ChatMessage> _upsert(List<ChatMessage> messages, ChatMessage incoming) {
  final byId = {for (final message in messages) message.id: message};
  byId[incoming.id] = incoming;
  final sorted = byId.values.toList()
    ..sort((left, right) {
      final byTime = left.createdAt.compareTo(right.createdAt);
      return byTime != 0 ? byTime : left.id.compareTo(right.id);
    });
  return List.unmodifiable(sorted);
}
