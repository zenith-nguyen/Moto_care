import 'dart:async';

import '../../features/auth/domain/app_user.dart';
import 'realtime_event.dart';
import 'realtime_transport.dart';

enum RealtimeConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

class RealtimeScope {
  const RealtimeScope({required this.role, this.orderId});

  final AppRole role;
  final int? orderId;
}

class RealtimeResyncRequest {
  const RealtimeResyncRequest({
    required this.role,
    required this.orderId,
    required this.isReconnect,
  });

  final AppRole role;
  final int? orderId;
  final bool isReconnect;

  bool get refreshPendingOffers => role == AppRole.provider;
  bool get refreshOrderAndMessages => orderId != null;
}

abstract interface class RealtimeConnection {
  void connect({
    required Uri origin,
    required String accessToken,
    required RealtimeScope scope,
  });

  void disconnect();
}

class RealtimeClient implements RealtimeConnection {
  RealtimeClient(this._transport) {
    _transportSubscription = _transport.events.listen(_handleTransportEvent);
  }

  final RealtimeTransport _transport;
  late final StreamSubscription<RealtimeTransportEvent> _transportSubscription;
  final StreamController<RealtimeConnectionStatus> _statuses =
      StreamController<RealtimeConnectionStatus>.broadcast(sync: true);
  final StreamController<RealtimeEvent> _domainEvents =
      StreamController<RealtimeEvent>.broadcast(sync: true);
  final StreamController<RealtimeResyncRequest> _resyncRequests =
      StreamController<RealtimeResyncRequest>.broadcast(sync: true);

  RealtimeConnectionStatus _status = RealtimeConnectionStatus.disconnected;
  RealtimeScope? _scope;

  RealtimeConnectionStatus get status => _status;
  Stream<RealtimeConnectionStatus> get statuses => _statuses.stream;
  Stream<RealtimeEvent> get events => _domainEvents.stream;
  Stream<RealtimeResyncRequest> get resyncRequests => _resyncRequests.stream;

  @override
  void connect({
    required Uri origin,
    required String accessToken,
    required RealtimeScope scope,
  }) {
    if (accessToken.isEmpty) {
      throw const FormatException('Realtime access token is required.');
    }
    if (scope.orderId case final orderId? when orderId <= 0) {
      throw ArgumentError.value(orderId, 'scope.orderId');
    }

    _scope = scope;
    _setStatus(RealtimeConnectionStatus.connecting);
    _transport.connect(
      origin: origin,
      auth: <String, Object>{'token': accessToken, 'orderId': ?scope.orderId},
    );
  }

  @override
  void disconnect() {
    _scope = null;
    _transport.disconnect();
    _setStatus(RealtimeConnectionStatus.disconnected);
  }

  Future<void> dispose() async {
    disconnect();
    await _transportSubscription.cancel();
    await _transport.dispose();
    await Future.wait([
      _statuses.close(),
      _domainEvents.close(),
      _resyncRequests.close(),
    ]);
  }

  void _handleTransportEvent(RealtimeTransportEvent event) {
    switch (event) {
      case RealtimeTransportConnected(:final isReconnect):
        _setStatus(RealtimeConnectionStatus.connected);
        final scope = _scope;
        if (scope != null) {
          _resyncRequests.add(
            RealtimeResyncRequest(
              role: scope.role,
              orderId: scope.orderId,
              isReconnect: isReconnect,
            ),
          );
        }
      case RealtimeTransportReconnecting():
        _setStatus(RealtimeConnectionStatus.reconnecting);
      case RealtimeTransportDisconnected():
        _setStatus(RealtimeConnectionStatus.disconnected);
      case RealtimeTransportFailed():
        _setStatus(RealtimeConnectionStatus.failed);
      case RealtimeTransportPayload(:final name, :final data):
        final parsed = _parse(name, data);
        if (parsed != null && _isAllowedForScope(parsed)) {
          _domainEvents.add(parsed);
        }
    }
  }

  bool _isAllowedForScope(RealtimeEvent event) {
    final scope = _scope;
    if (scope == null) return false;
    if (event is OfferCreated || event is OfferExpired) {
      return scope.role == AppRole.provider;
    }
    return scope.orderId == event.orderId;
  }

  RealtimeEvent? _parse(String name, Object? raw) {
    try {
      final json = _stringMap(raw);
      final orderId = _positiveInt(json['orderId']);
      return switch (name) {
        'offer.created' => OfferCreated(
          orderId: orderId,
          offerId: _positiveInt(json['offerId']),
          expiresAt: _dateTime(json['expiresAt']),
        ),
        'offer.expired' => OfferExpired(
          orderId: orderId,
          offerId: _positiveInt(json['offerId']),
        ),
        'order.status_changed' => OrderStatusChanged(
          orderId: orderId,
          status: _nonEmptyString(json['status']),
        ),
        'provider.location_updated' => ProviderLocationUpdated(
          orderId: orderId,
          providerId: _positiveInt(json['providerId']),
          latitude: _coordinate(json['latitude'], minimum: -90, maximum: 90),
          longitude: _coordinate(
            json['longitude'],
            minimum: -180,
            maximum: 180,
          ),
          updatedAt: _dateTime(json['updatedAt']),
        ),
        'message.created' => MessageCreated(
          orderId: orderId,
          id: _positiveInt(json['id']),
          senderId: _positiveInt(json['senderId']),
          content: _nullableString(json['content']),
          image: _messageImage(json['image']),
          createdAt: _dateTime(json['createdAt']),
        ),
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }

  void _setStatus(RealtimeConnectionStatus next) {
    if (_status == next) return;
    _status = next;
    if (!_statuses.isClosed) _statuses.add(next);
  }
}

Map<String, dynamic> _stringMap(Object? raw) {
  if (raw is! Map) throw const FormatException('Expected an object.');
  final result = <String, dynamic>{};
  for (final entry in raw.entries) {
    if (entry.key is! String) {
      throw const FormatException('Expected string keys.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

int _positiveInt(Object? raw) {
  if (raw is! int || raw <= 0) throw const FormatException('Expected ID.');
  return raw;
}

String _nonEmptyString(Object? raw) {
  if (raw is! String || raw.isEmpty) {
    throw const FormatException('Expected string.');
  }
  return raw;
}

String? _nullableString(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) throw const FormatException('Expected text.');
  return raw;
}

DateTime _dateTime(Object? raw) {
  if (raw is! String) throw const FormatException('Expected timestamp.');
  final value = DateTime.tryParse(raw);
  if (value == null) throw const FormatException('Invalid timestamp.');
  return value.toUtc();
}

double _coordinate(
  Object? raw, {
  required double minimum,
  required double maximum,
}) {
  if (raw is! num) throw const FormatException('Expected coordinate.');
  final value = raw.toDouble();
  if (!value.isFinite || value < minimum || value > maximum) {
    throw const FormatException('Coordinate out of range.');
  }
  return value;
}

RealtimeMessageImage? _messageImage(Object? raw) {
  if (raw == null) return null;
  final json = _stringMap(raw);
  final url = _nonEmptyString(json['url']);
  final uri = Uri.tryParse(url);
  final isProtectedApiPath =
      uri != null &&
      !uri.hasScheme &&
      url.startsWith('/') &&
      !uri.hasQuery &&
      !uri.hasFragment;
  final isHttpUrl = uri != null && uri.scheme == 'https' && uri.hasAuthority;
  if (!isProtectedApiPath && !isHttpUrl) {
    throw const FormatException('Invalid image URL.');
  }
  return RealtimeMessageImage(
    url: url,
    mimeType: _nonEmptyString(json['mimeType']),
    sizeBytes: _positiveInt(json['sizeBytes']),
  );
}
