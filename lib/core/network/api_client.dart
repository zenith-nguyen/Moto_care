import 'dart:math';

import 'package:dio/dio.dart';

import '../auth/session_invalidation_bus.dart';
import '../auth/token_store.dart';
import 'api_failure.dart';
import 'json_api.dart';

class ApiClient implements JsonApi {
  ApiClient(this._dio, this._tokenStore, this._invalidationBus) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStore.read();
          if (token != null &&
              token.isNotEmpty &&
              !_isPublicAuthPath(options.path)) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers.putIfAbsent('X-Request-ID', _newRequestId);
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.headers['Authorization'] is String) {
            await _tokenStore.clear();
            _invalidationBus.invalidate(SessionInvalidationReason.unauthorized);
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStore _tokenStore;
  final SessionInvalidationBus _invalidationBus;
  final Random _random = Random.secure();

  @override
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _requestList(
      () => _dio.get<Object?>(path, queryParameters: queryParameters),
    );
  }

  @override
  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _requestObject(
      () => _dio.get<Object?>(path, queryParameters: queryParameters),
    );
  }

  @override
  Future<Map<String, dynamic>> postObject(String path, {Object? data}) {
    return _requestObject(() => _dio.post<Object?>(path, data: data));
  }

  @override
  Future<Map<String, dynamic>> patchObject(String path, {Object? data}) {
    return _requestObject(() => _dio.patch<Object?>(path, data: data));
  }

  Future<Map<String, dynamic>> _requestObject(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is! Map) {
        throw const ApiFailure(
          kind: ApiFailureKind.invalidResponse,
          message: 'Máy chủ trả về dữ liệu không hợp lệ.',
        );
      }
      return Map<String, dynamic>.from(data);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> _requestList(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is! List) {
        throw const ApiFailure(
          kind: ApiFailureKind.invalidResponse,
          message: 'Máy chủ trả về dữ liệu không hợp lệ.',
        );
      }
      return data
          .map((item) {
            if (item is! Map) {
              throw const ApiFailure(
                kind: ApiFailureKind.invalidResponse,
                message: 'Máy chủ trả về dữ liệu không hợp lệ.',
              );
            }
            return Map<String, dynamic>.from(item);
          })
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  String _newRequestId() {
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final random = _random.nextInt(0x7fffffff).toRadixString(36);
    return 'mobile-$micros-$random';
  }

  bool _isPublicAuthPath(String path) {
    return path == '/auth' || path.startsWith('/auth/');
  }
}
