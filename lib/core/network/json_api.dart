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

  Future<Map<String, dynamic>> patchObject(String path, {Object? data});
}
