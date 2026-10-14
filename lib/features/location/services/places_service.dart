import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../home/models/rescue_location.dart';
import '../models/place_suggestion.dart';
import 'location_api_config.dart';

final locationDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 8),
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
});
final placesServiceProvider = Provider<PlacesService>(
  (ref) => GooglePlacesService(
    ref.watch(locationDioProvider),
    ref.watch(locationApiConfigProvider),
  ),
);

abstract interface class PlacesService {
  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    required String sessionToken,
    LatLng? bias,
    CancelToken? cancelToken,
  });
  Future<RescueLocation> detail(
    String placeId, {
    required String sessionToken,
    CancelToken? cancelToken,
  });
  Future<RescueLocation> geocode(String address, {CancelToken? cancelToken});
  Future<RescueLocation> reverseGeocode(
    LatLng point, {
    CancelToken? cancelToken,
  });
}

class PlacesException implements Exception {
  const PlacesException(this.message);
  final String message;
}

String newPlacesSessionToken() {
  final random = Random.secure();
  return List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
}

class GooglePlacesService implements PlacesService {
  GooglePlacesService(this.dio, this.config);
  final Dio dio;
  final LocationApiConfig config;
  String get _placesBase => config.placesProxyUrl.isEmpty
      ? 'https://places.googleapis.com/v1'
      : config.placesProxyUrl.replaceAll(RegExp(r'/$'), '');
  Options _options(String mask) => Options(
    headers: {
      ...config.applicationHeaders,
      if (config.placesProxyUrl.isEmpty) 'X-Goog-Api-Key': config.placesKey,
      'X-Goog-FieldMask': mask,
    },
  );
  @override
  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    required String sessionToken,
    LatLng? bias,
    CancelToken? cancelToken,
  }) async {
    if (input.trim().isEmpty) return [];
    if (!config.placesConfigured) {
      throw const PlacesException(
        'Tìm kiếm địa điểm chưa sẵn sàng. Bạn có thể nhập địa chỉ hoặc dùng GPS.',
      );
    }
    final data = await _request(
      () => dio.post<Object?>(
        '$_placesBase/places:autocomplete',
        data: {
          'input': input.trim(),
          'languageCode': 'vi',
          'regionCode': 'VN',
          'includedRegionCodes': ['vn'],
          'sessionToken': sessionToken,
          if (bias != null)
            'locationBias': {
              'circle': {
                'center': {
                  'latitude': bias.latitude,
                  'longitude': bias.longitude,
                },
                'radius': 30000.0,
              },
            },
        },
        options: _options(
          'suggestions.placePrediction.placeId,suggestions.placePrediction.text.text,suggestions.placePrediction.structuredFormat',
        ),
        cancelToken: cancelToken,
      ),
    );
    final suggestions = data['suggestions'];
    if (suggestions == null) return [];
    if (suggestions is! List) {
      throw const PlacesException('Dữ liệu địa điểm chưa hợp lệ. Hãy thử lại.');
    }
    final result = <PlaceSuggestion>[];
    for (final entry in suggestions) {
      if (entry is! Map) continue;
      final prediction = entry['placePrediction'];
      if (prediction is! Map) continue;
      final id = prediction['placeId'];
      final structure = prediction['structuredFormat'];
      final title = structure is Map ? _text(structure['mainText']) : '';
      final address = structure is Map ? _text(structure['secondaryText']) : '';
      final fullText = _text(prediction['text']);
      if (id is String &&
          id.isNotEmpty &&
          (title.isNotEmpty || fullText.isNotEmpty)) {
        result.add(
          PlaceSuggestion(
            id: id,
            title: title.isEmpty ? fullText : title,
            address: address.isEmpty ? fullText : address,
          ),
        );
      }
    }
    return result;
  }

  @override
  Future<RescueLocation> detail(
    String placeId, {
    required String sessionToken,
    CancelToken? cancelToken,
  }) async {
    if (!config.placesConfigured) {
      throw const PlacesException('Tìm kiếm địa điểm chưa sẵn sàng.');
    }
    final data = await _request(
      () => dio.get<Object?>(
        '$_placesBase/places/${Uri.encodeComponent(placeId)}',
        queryParameters: {
          'languageCode': 'vi',
          'regionCode': 'VN',
          'sessionToken': sessionToken,
        },
        options: _options('id,formattedAddress,location'),
        cancelToken: cancelToken,
      ),
    );
    return _location(
      data['formattedAddress'],
      data['location'],
      latitudeKey: 'latitude',
      longitudeKey: 'longitude',
    );
  }

  @override
  Future<RescueLocation> geocode(String address, {CancelToken? cancelToken}) =>
      _geocode({'address': address.trim(), 'region': 'vn'}, cancelToken);
  @override
  Future<RescueLocation> reverseGeocode(
    LatLng point, {
    CancelToken? cancelToken,
  }) =>
      _geocode({'latlng': '${point.latitude},${point.longitude}'}, cancelToken);
  Future<RescueLocation> _geocode(
    Map<String, Object> query,
    CancelToken? cancelToken,
  ) async {
    if (!config.geocodingConfigured) {
      throw const PlacesException(
        'Chưa tra được địa chỉ. Bạn có thể dùng GPS hoặc chọn kết quả tìm kiếm.',
      );
    }
    final proxied = config.geocodingProxyUrl.isNotEmpty;
    final data = await _request(
      () => dio.get<Object?>(
        proxied
            ? config.geocodingProxyUrl
            : 'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          ...query,
          'language': 'vi',
          if (!proxied)
            'key': config.geocodingKey.isEmpty
                ? config.placesKey
                : config.geocodingKey,
        },
        options: Options(headers: config.applicationHeaders),
        cancelToken: cancelToken,
      ),
    );
    if (data['status'] == 'ZERO_RESULTS') {
      throw const PlacesException(
        'Không tìm thấy địa chỉ này. Thử địa chỉ chi tiết hơn hoặc chọn trên bản đồ.',
      );
    }
    if (data['status'] != 'OK') {
      throw const PlacesException('Không tra được địa chỉ. Vui lòng thử lại.');
    }
    final results = data['results'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      throw const PlacesException(
        'Địa chỉ chưa có tọa độ. Vui lòng chọn điểm khác.',
      );
    }
    final first = results.first as Map;
    final geometry = first['geometry'];
    return _location(
      first['formatted_address'],
      geometry is Map ? geometry['location'] : null,
      latitudeKey: 'lat',
      longitudeKey: 'lng',
    );
  }

  Future<Map> _request(Future<Response<Object?>> Function() send) async {
    try {
      final response = await send();
      if (response.data is! Map) {
        throw const PlacesException(
          'Dữ liệu địa điểm chưa hợp lệ. Hãy thử lại.',
        );
      }
      return response.data as Map;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      final status = error.response?.statusCode;
      throw PlacesException(switch (status) {
        401 || 403 =>
          'Dịch vụ địa điểm chưa sẵn sàng. Vui lòng thử lại hoặc dùng GPS.',
        429 => 'Dịch vụ tìm kiếm đang bận. Vui lòng thử lại sau.',
        _ => 'Không kết nối được dịch vụ địa điểm. Kiểm tra mạng và thử lại.',
      });
    }
  }

  static String _text(Object? value) =>
      value is Map && value['text'] is String ? value['text'] as String : '';
  static RescueLocation _location(
    Object? address,
    Object? point, {
    required String latitudeKey,
    required String longitudeKey,
  }) {
    final lat = point is Map ? point[latitudeKey] : null;
    final lng = point is Map ? point[longitudeKey] : null;
    if (address is! String ||
        address.trim().length < 5 ||
        address.trim().length > 240 ||
        lat is! num ||
        lng is! num ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      throw const PlacesException(
        'Địa điểm chưa có địa chỉ và tọa độ hợp lệ. Vui lòng chọn điểm khác.',
      );
    }
    return RescueLocation(
      address: address.trim(),
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
    );
  }
}
