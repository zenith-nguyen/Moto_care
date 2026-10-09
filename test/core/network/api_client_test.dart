import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/auth/session_invalidation_bus.dart';
import 'package:moto_care/core/network/api_client.dart';
import 'package:moto_care/core/network/api_failure.dart';

import '../../support/memory_token_store.dart';

void main() {
  test('parses a JSON object list without weakening item types', () async {
    final tokenStore = MemoryTokenStore('jwt-for-test');
    final bus = SessionInvalidationBus();
    final adapter = RecordingAdapter((options) {
      return jsonResponse(200, [
        {'id': 1, 'name': 'Xẹp lốp'},
      ]);
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    final api = ApiClient(dio, tokenStore, bus);

    final items = await api.getList('/incident-types');

    expect(items.single['id'], 1);
    await bus.dispose();
  });

  test('rejects a non-list response for a list endpoint', () async {
    final bus = SessionInvalidationBus();
    final adapter = RecordingAdapter((options) {
      return jsonResponse(200, {'id': 1});
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    final api = ApiClient(dio, MemoryTokenStore(), bus);

    await expectLater(
      api.getList('/orders'),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.kind,
          'kind',
          ApiFailureKind.invalidResponse,
        ),
      ),
    );
    await bus.dispose();
  });

  test(
    'adds bearer token and request ID without logging credentials',
    () async {
      final tokenStore = MemoryTokenStore('jwt-for-test');
      final bus = SessionInvalidationBus();
      final adapter = RecordingAdapter((options) {
        return jsonResponse(200, {'id': 1, 'name': 'Test'});
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;
      final api = ApiClient(dio, tokenStore, bus);

      await api.getObject('/users/me');

      expect(
        adapter.lastOptions?.headers['Authorization'],
        'Bearer jwt-for-test',
      );
      expect(
        adapter.lastOptions?.headers['X-Request-ID'],
        startsWith('mobile-'),
      );
      await bus.dispose();
    },
  );

  test('clears the token and emits invalidation on HTTP 401', () async {
    final tokenStore = MemoryTokenStore('expired-token');
    final bus = SessionInvalidationBus();
    final invalidation = bus.stream.first;
    final adapter = RecordingAdapter((options) {
      return jsonResponse(401, {
        'statusCode': 401,
        'code': 'UNAUTHORIZED',
        'message': 'Unauthorized',
        'requestId': 'request-12345678',
      });
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    final api = ApiClient(dio, tokenStore, bus);

    await expectLater(
      api.getObject('/users/me'),
      throwsA(
        isA<ApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              ApiFailureKind.unauthorized,
            )
            .having(
              (failure) => failure.requestId,
              'requestId',
              'request-12345678',
            ),
      ),
    );
    expect(await invalidation, SessionInvalidationReason.unauthorized);
    expect(tokenStore.token, isNull);
    await bus.dispose();
  });

  test('does not attach or invalidate a session for public auth 401', () async {
    final tokenStore = MemoryTokenStore('stale-token');
    final bus = SessionInvalidationBus();
    var invalidated = false;
    final subscription = bus.stream.listen((_) => invalidated = true);
    final adapter = RecordingAdapter((options) {
      return jsonResponse(401, {
        'statusCode': 401,
        'message': 'Invalid credentials',
      });
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    final api = ApiClient(dio, tokenStore, bus);

    await expectLater(
      api.postObject('/auth/login', data: const {}),
      throwsA(isA<ApiFailure>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(adapter.lastOptions?.headers['Authorization'], isNull);
    expect(tokenStore.token, 'stale-token');
    expect(invalidated, isFalse);
    await subscription.cancel();
    await bus.dispose();
  });
}

class RecordingAdapter implements HttpClientAdapter {
  RecordingAdapter(this._responder);

  final ResponseBody Function(RequestOptions options) _responder;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return _responder(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int statusCode, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
