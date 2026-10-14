import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moto_care/features/location/services/location_api_config.dart';
import 'package:moto_care/features/location/services/places_service.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object body = <String, Object>{};
  int status = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _Adapter adapter;
  late GooglePlacesService service;
  setUp(() {
    adapter = _Adapter();
    dio = Dio()..httpClientAdapter = adapter;
    service = GooglePlacesService(
      dio,
      const LocationApiConfig(
        placesKey: 'test-only-key',
        geocodingKey: 'geocode-test-key',
      ),
    );
  });
  tearDown(() => dio.close(force: true));
  test(
    'Autocomplete uses POST, Vietnamese, session, GPS bias and structured rows',
    () async {
      adapter.body = {
        'suggestions': [
          {
            'placePrediction': {
              'placeId': 'vincom',
              'text': {'text': 'Vincom, Quận 1'},
              'structuredFormat': {
                'mainText': {'text': 'Vincom'},
                'secondaryText': {'text': 'Quận 1'},
              },
            },
          },
          {
            'queryPrediction': {
              'text': {'text': 'ignored'},
            },
          },
        ],
      };
      final result = await service.autocomplete(
        ' vincom ',
        sessionToken: 'session',
        bias: const LatLng(10.77, 106.7),
      );
      expect(result.single.id, 'vincom');
      expect(result.single.title, 'Vincom');
      expect(result.single.address, 'Quận 1');
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(
        request.uri.toString(),
        'https://places.googleapis.com/v1/places:autocomplete',
      );
      final data = request.data as Map;
      expect(data['input'], 'vincom');
      expect(data['languageCode'], 'vi');
      expect(data['sessionToken'], 'session');
      expect(data['locationBias']['circle']['center']['latitude'], 10.77);
      expect(request.headers['X-Goog-FieldMask'], contains('structuredFormat'));
    },
  );
  test(
    'Place details keep real coordinates and terminate with the same token',
    () async {
      adapter.body = {
        'id': 'vincom',
        'formattedAddress': '72 Lê Thánh Tôn, Quận 1',
        'location': {'latitude': 10.778, 'longitude': 106.701},
      };
      final place = await service.detail(
        'vincom',
        sessionToken: 'same-session',
      );
      expect(place.latitude, 10.778);
      expect(place.longitude, 106.701);
      expect(adapter.requests.single.path, endsWith('/places/vincom'));
      expect(
        adapter.requests.single.queryParameters['sessionToken'],
        'same-session',
      );
      expect(
        adapter.requests.single.headers['X-Goog-FieldMask'],
        'id,formattedAddress,location',
      );
    },
  );
  test(
    'Forward and reverse geocoding use their own key and validate coordinates',
    () async {
      adapter.body = {
        'status': 'OK',
        'results': [
          {
            'formatted_address': '273 An Dương Vương, Quận 5',
            'geometry': {
              'location': {'lat': 10.757, 'lng': 106.668},
            },
          },
        ],
      };
      final place = await service.geocode('273 An Dương Vương');
      expect(place.hasCoordinates, isTrue);
      await service.reverseGeocode(const LatLng(10.757, 106.668));
      expect(
        adapter.requests.first.queryParameters['address'],
        '273 An Dương Vương',
      );
      expect(adapter.requests.last.queryParameters['latlng'], '10.757,106.668');
      expect(adapter.requests.last.queryParameters['key'], 'geocode-test-key');
      adapter.body = {
        'formattedAddress': 'Wrong coordinate',
        'location': {'latitude': 91, 'longitude': 0},
      };
      await expectLater(
        service.detail('bad', sessionToken: 's'),
        throwsA(isA<PlacesException>()),
      );
    },
  );
  test(
    'Empty, rejected, rate-limited and malformed responses remain recoverable',
    () async {
      adapter.body = <String, Object>{};
      expect(await service.autocomplete('ktx', sessionToken: 's'), isEmpty);
      adapter.body = {'status': 'ZERO_RESULTS'};
      await expectLater(
        service.geocode('unknown'),
        throwsA(isA<PlacesException>()),
      );
      adapter.body = {'suggestions': 'invalid'};
      await expectLater(
        service.autocomplete('ktx', sessionToken: 's'),
        throwsA(isA<PlacesException>()),
      );
      adapter.status = 403;
      await expectLater(
        service.autocomplete('ktx', sessionToken: 's'),
        throwsA(
          isA<PlacesException>().having(
            (error) => error.message,
            'message',
            isNot(contains('test-only-key')),
          ),
        ),
      );
      adapter.status = 429;
      await expectLater(
        service.autocomplete('ktx', sessionToken: 's'),
        throwsA(
          isA<PlacesException>().having(
            (error) => error.message,
            'message',
            contains('đang bận'),
          ),
        ),
      );
    },
  );
  test(
    'Cancellation stays cancellation and unconfigured services make no request',
    () async {
      final cancel = CancelToken()..cancel();
      await expectLater(
        service.autocomplete('vincom', sessionToken: 's', cancelToken: cancel),
        throwsA(
          isA<DioException>().having(CancelToken.isCancel, 'cancelled', isTrue),
        ),
      );
      final missing = GooglePlacesService(dio, const LocationApiConfig());
      await expectLater(
        missing.autocomplete('vincom', sessionToken: 's'),
        throwsA(isA<PlacesException>()),
      );
      expect(adapter.requests, isEmpty);
    },
  );
  test(
    'Configured proxies receive no Google keys and session tokens are unique',
    () async {
      final proxy = GooglePlacesService(
        dio,
        const LocationApiConfig(
          placesKey: 'must-not-forward',
          placesProxyUrl: 'https://example.test/places/v1/',
          geocodingProxyUrl: 'https://example.test/geocode',
        ),
      );
      await proxy.autocomplete('bệnh viện', sessionToken: 's');
      expect(adapter.requests.single.uri.host, 'example.test');
      expect(
        adapter.requests.single.headers.containsKey('X-Goog-Api-Key'),
        isFalse,
      );
      adapter.body = {'status': 'ZERO_RESULTS'};
      await expectLater(
        proxy.geocode('hospital'),
        throwsA(isA<PlacesException>()),
      );
      expect(adapter.requests.last.queryParameters.containsKey('key'), isFalse);
      final a = newPlacesSessionToken(), b = newPlacesSessionToken();
      expect(a.length, 32);
      expect(a, isNot(b));
    },
  );
}
