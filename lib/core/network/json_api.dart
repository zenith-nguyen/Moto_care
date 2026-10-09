import 'dart:typed_data';

class BinaryUpload {
  const BinaryUpload({
    required this.fieldName,
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final String fieldName;
  final Uint8List bytes;
  final String filename;
  final String contentType;
}

class BinaryResponse {
  const BinaryResponse({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String? contentType;
}

abstract interface class JsonApi {
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  Future<Map<String, dynamic>> postObject(String path, {Object? data});

  Future<Map<String, dynamic>> postMultipartObject(
    String path, {
    Map<String, String> fields = const {},
    required BinaryUpload file,
  });

  Future<BinaryResponse> getBinary(String path);

  Future<Map<String, dynamic>> patchObject(String path, {Object? data});
}
