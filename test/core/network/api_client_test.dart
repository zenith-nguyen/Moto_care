import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/auth/session_invalidation_bus.dart';
import 'package:moto_care/core/network/api_client.dart';
import 'package:moto_care/core/network/api_failure.dart';
import 'package:moto_care/core/network/json_api.dart';

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

  test(
    'uploads multipart bytes with the declared field and MIME type',
    () async {
      final bus = SessionInvalidationBus();
      final adapter = RecordingAdapter((options) {
        return jsonResponse(201, {
          'id': 1,
          'senderId': 7,
          'content': null,
          'image': null,
          'createdAt': '2026-10-10T00:00:00.000Z',
        });
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;
      final api = ApiClient(dio, MemoryTokenStore('jwt'), bus);

      await api.postMultipartObject(
        '/orders/42/messages',
        fields: const {'content': 'Ảnh hiện trường'},
        file: BinaryUpload(
          fieldName: 'image',
          bytes: Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]),
          filename: 'incident.png',
          contentType: 'image/png',
        ),
      );

      final form = adapter.lastOptions?.data as FormData;
      expect(
        form.fields.any(
          (field) => field.key == 'content' && field.value == 'Ảnh hiện trường',
        ),
        isTrue,
      );
      expect(form.files.single.key, 'image');
      expect(form.files.single.value.filename, 'incident.png');
      expect(form.files.single.value.contentType.toString(), 'image/png');
      await bus.dispose();
    },
  );

  test(
    'downloads protected binary data through the authenticated client',
    () async {
      final bus = SessionInvalidationBus();
      final adapter = RecordingAdapter((options) {
        return ResponseBody.fromBytes(
          [0xff, 0xd8, 0xff],
          200,
          headers: {
            Headers.contentTypeHeader: ['image/jpeg'],
          },
        );
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;
      final api = ApiClient(dio, MemoryTokenStore('jwt'), bus);

      final image = await api.getBinary('/orders/42/messages/9/image');

      expect(image.bytes, [0xff, 0xd8, 0xff]);
      expect(image.contentType, 'image/jpeg');
      expect(adapter.lastOptions?.headers['Authorization'], 'Bearer jwt');
      expect(adapter.lastOptions?.responseType, ResponseType.bytes);
      await bus.dispose();
    },
  );
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
