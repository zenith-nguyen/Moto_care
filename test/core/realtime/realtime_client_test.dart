import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/realtime/realtime_client.dart';
import 'package:moto_care/core/realtime/realtime_event.dart';
import 'package:moto_care/core/realtime/realtime_transport.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';

void main() {
  late FakeRealtimeTransport transport;
  late RealtimeClient client;

  setUp(() {
    transport = FakeRealtimeTransport();
    client = RealtimeClient(transport);
  });

  tearDown(() => client.dispose());

  test('keeps JWT in handshake auth and requests the selected order room', () {
    final origin = Uri.parse('https://demo.example.test');

    client.connect(
      origin: origin,
      accessToken: 'private-jwt',
      scope: const RealtimeScope(role: AppRole.customer, orderId: 41),
    );

    expect(transport.origin, origin);
    expect(transport.origin!.query, isEmpty);
    expect(transport.auth, {'token': 'private-jwt', 'orderId': 41});
    expect(client.status, RealtimeConnectionStatus.connecting);
  });

  test('requests REST resync on initial connection and reconnect', () {
    final requests = <RealtimeResyncRequest>[];
    client.resyncRequests.listen(requests.add);
    client.connect(
      origin: Uri.parse('https://demo.example.test'),
      accessToken: 'provider-jwt',
      scope: const RealtimeScope(role: AppRole.provider, orderId: 52),
    );

    transport.emit(const RealtimeTransportConnected(isReconnect: false));
    transport.emit(const RealtimeTransportConnected(isReconnect: true));

    expect(requests, hasLength(2));
    expect(requests.first.isReconnect, isFalse);
    expect(requests.last.isReconnect, isTrue);
    expect(requests.last.refreshPendingOffers, isTrue);
    expect(requests.last.refreshOrderAndMessages, isTrue);
  });

  test('parses all documented payloads into typed events', () {
    final events = <RealtimeEvent>[];
    client.events.listen(events.add);
    client.connect(
      origin: Uri.parse('https://demo.example.test'),
      accessToken: 'provider-jwt',
      scope: const RealtimeScope(role: AppRole.provider, orderId: 52),
    );

    transport.payload('offer.created', {
      'orderId': 52,
      'offerId': 9,
      'expiresAt': '2026-10-08T08:00:15.000Z',
    });
    transport.payload('offer.expired', {'orderId': 52, 'offerId': 9});
    transport.payload('order.status_changed', {
      'orderId': 52,
      'status': 'ACCEPTED',
    });
    transport.payload('provider.location_updated', {
      'orderId': 52,
      'providerId': 3,
      'latitude': 10.7769,
      'longitude': 106.7009,
      'updatedAt': '2026-10-08T08:00:20.000Z',
    });
    transport.payload('message.created', {
      'orderId': 52,
      'id': 7,
      'senderId': 4,
      'content': 'Tôi đang đến',
      'image': {
        'url': '/orders/52/messages/7/image',
        'mimeType': 'image/jpeg',
        'sizeBytes': 2048,
      },
      'createdAt': '2026-10-08T08:00:25.000Z',
    });

    expect(events, hasLength(5));
    expect(events[0], isA<OfferCreated>());
    expect(events[1], isA<OfferExpired>());
    expect((events[2] as OrderStatusChanged).status, 'ACCEPTED');
    expect((events[3] as ProviderLocationUpdated).latitude, 10.7769);
    expect(
      (events[4] as MessageCreated).image?.url,
      '/orders/52/messages/7/image',
    );
  });

  test('drops malformed and wrong-order payloads without failing stream', () {
    final events = <RealtimeEvent>[];
    client.events.listen(events.add);
    client.connect(
      origin: Uri.parse('https://demo.example.test'),
      accessToken: 'customer-jwt',
      scope: const RealtimeScope(role: AppRole.customer, orderId: 52),
    );

    transport.payload('provider.location_updated', {
      'orderId': 52,
      'providerId': 3,
      'latitude': 999,
      'longitude': 106.7,
      'updatedAt': 'not-a-date',
    });
    transport.payload('order.status_changed', {
      'orderId': 99,
      'status': 'ACCEPTED',
    });
    transport.payload('offer.created', {
      'orderId': 52,
      'offerId': 9,
      'expiresAt': '2026-10-08T08:00:15.000Z',
    });

    expect(events, isEmpty);
  });

  test('disconnect clears the active scope and listeners ignore late data', () {
    final events = <RealtimeEvent>[];
    client.events.listen(events.add);
    client.connect(
      origin: Uri.parse('https://demo.example.test'),
      accessToken: 'customer-jwt',
      scope: const RealtimeScope(role: AppRole.customer, orderId: 52),
    );

    client.disconnect();
    transport.payload('order.status_changed', {
      'orderId': 52,
      'status': 'ACCEPTED',
    });

    expect(transport.disconnectCount, 1);
    expect(client.status, RealtimeConnectionStatus.disconnected);
    expect(events, isEmpty);
  });
}

class FakeRealtimeTransport implements RealtimeTransport {
  final StreamController<RealtimeTransportEvent> _events =
      StreamController<RealtimeTransportEvent>.broadcast(sync: true);

  Uri? origin;
  Map<String, Object>? auth;
  int disconnectCount = 0;

  @override
  Stream<RealtimeTransportEvent> get events => _events.stream;

  @override
  void connect({required Uri origin, required Map<String, Object> auth}) {
    this.origin = origin;
    this.auth = Map.unmodifiable(auth);
  }

  void emit(RealtimeTransportEvent event) => _events.add(event);

  void payload(String name, Object? data) {
    emit(RealtimeTransportPayload(name, data));
  }

  @override
  void disconnect() {
    disconnectCount += 1;
  }

  @override
  Future<void> dispose() => _events.close();
}
