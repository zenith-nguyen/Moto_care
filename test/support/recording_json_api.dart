import 'dart:typed_data';

import 'package:moto_care/core/network/json_api.dart';

class RecordingJsonApi implements JsonApi {
  Map<String, dynamic> objectResponse = {};
  List<Map<String, dynamic>> listResponse = [];
  String? lastMethod;
  String? lastPath;
  Object? lastData;
  Map<String, dynamic>? lastQueryParameters;
  Map<String, String>? lastMultipartFields;
  BinaryUpload? lastUpload;
  BinaryResponse binaryResponse = BinaryResponse(
    bytes: Uint8List(0),
    contentType: null,
  );

  @override
  Future<BinaryResponse> getBinary(String path) async {
    _record('GET_BINARY', path);
    return binaryResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    _record('GET', path, queryParameters: queryParameters);
    return listResponse;
  }

  @override
  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    _record('GET', path, queryParameters: queryParameters);
    return objectResponse;
  }

  @override
  Future<Map<String, dynamic>> patchObject(String path, {Object? data}) async {
    _record('PATCH', path, data: data);
    return objectResponse;
  }

  @override
  Future<Map<String, dynamic>> postObject(String path, {Object? data}) async {
    _record('POST', path, data: data);
    return objectResponse;
  }

  @override
  Future<Map<String, dynamic>> postMultipartObject(
    String path, {
    Map<String, String> fields = const {},
    required BinaryUpload file,
  }) async {
    _record('POST_MULTIPART', path);
    lastMultipartFields = Map.unmodifiable(fields);
    lastUpload = file;
    return objectResponse;
  }

  void _record(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    lastMethod = method;
    lastPath = path;
    lastData = data;
    lastQueryParameters = queryParameters;
  }
}
