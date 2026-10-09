import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/core/realtime/realtime_client.dart';
import 'package:moto_care/core/realtime/realtime_transport.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/messages/application/customer_chat_controller.dart';
import 'package:moto_care/features/messages/data/messages_repository.dart';
import 'package:moto_care/features/messages/domain/chat_message.dart';

void main() {
  test('merges HTTP sends and realtime messages without duplicates', () async {
    final repository = FakeMessagesRepository();
    final transport = FakeRealtimeTransport();
    final realtime = RealtimeClient(transport);
    final container = ProviderContainer(
      overrides: [
        messagesRepositoryProvider.overrideWithValue(repository),
        realtimeClientProvider.overrideWithValue(realtime),
      ],
    );
    final provider = customerChatControllerProvider(42);
    final listener = container.listen(provider, (_, _) {});
    addTearDown(() async {
      listener.close();
      container.dispose();
      await realtime.dispose();
    });

    final initial = await container.read(provider.future);
    expect(initial.messages.single.id, 8);

    await container.read(provider.notifier).sendText(' Tôi đã thấy thợ ');
    expect(repository.lastContent, ' Tôi đã thấy thợ ');
    expect(container.read(provider).value?.messages.last.id, 9);

    realtime.connect(
      origin: Uri.parse('https://demo.example.test'),
      accessToken: 'customer-jwt',
      scope: const RealtimeScope(role: AppRole.customer, orderId: 42),
    );
    transport.payload('message.created', _realtimeMessageJson(id: 10));
    transport.payload('message.created', _realtimeMessageJson(id: 10));

    expect(container.read(provider).value?.messages.map((item) => item.id), [
      8,
      9,
      10,
    ]);
  });
}

class FakeMessagesRepository implements MessagesRepository {
  String? lastContent;

  @override
  Future<List<ChatMessage>> list(int orderId) async => [
    ChatMessage.fromJson(_messageJson(id: 8, content: 'Tôi đang tới')),
  ];

  @override
  Future<ChatMessage> send({
    required int orderId,
    String? content,
    ChatImageUpload? image,
  }) async {
    lastContent = content;
    return ChatMessage.fromJson(_messageJson(id: 9, content: content?.trim()));
  }

  @override
  Future<ProtectedChatImage> loadImage({
    required int orderId,
    required int messageId,
  }) async {
    return ProtectedChatImage(
      bytes: Uint8List.fromList([0xff, 0xd8, 0xff]),
      contentType: 'image/jpeg',
    );
  }
}

class FakeRealtimeTransport implements RealtimeTransport {
  final StreamController<RealtimeTransportEvent> _events =
      StreamController<RealtimeTransportEvent>.broadcast(sync: true);

  @override
  Stream<RealtimeTransportEvent> get events => _events.stream;

  @override
  void connect({required Uri origin, required Map<String, Object> auth}) {}

  void payload(String name, Object? data) {
    _events.add(RealtimeTransportPayload(name, data));
  }

  @override
  void disconnect() {}

  @override
  Future<void> dispose() => _events.close();
}

Map<String, dynamic> _messageJson({
  required int id,
  required String? content,
}) => {
  'id': id,
  'senderId': 3,
  'content': content,
  'image': null,
  'createdAt': '2026-10-10T00:00:${id.toString().padLeft(2, '0')}.000Z',
};

Map<String, dynamic> _realtimeMessageJson({required int id}) => {
  'orderId': 42,
  'id': id,
  'senderId': 3,
  'content': 'Tin realtime',
  'image': null,
  'createdAt': '2026-10-10T00:00:10.000Z',
};
