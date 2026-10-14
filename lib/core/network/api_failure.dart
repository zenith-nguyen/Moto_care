import 'package:dio/dio.dart';

enum ApiFailureKind {
  validation,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  rateLimited,
  timeout,
  network,
  server,
  invalidResponse,
  unknown,
}

class ApiFailure implements Exception {
  const ApiFailure({
    required this.kind,
    required this.message,
    this.statusCode,
    this.requestId,
    this.details = const [],
    this.retryAfter,
  });

  final ApiFailureKind kind;
  final String message;
  final int? statusCode;
  final String? requestId;
  final List<String> details;
  final Duration? retryAfter;

  bool get isUnauthorized => kind == ApiFailureKind.unauthorized;

  factory ApiFailure.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiFailure(
          kind: ApiFailureKind.timeout,
          message: 'Kết nối quá thời gian. Vui lòng thử lại.',
        );
      case DioExceptionType.connectionError:
        return const ApiFailure(
          kind: ApiFailureKind.network,
          message: 'Không thể kết nối tới máy chủ.',
        );
      case DioExceptionType.cancel:
        return const ApiFailure(
          kind: ApiFailureKind.unknown,
          message: 'Yêu cầu đã bị hủy.',
        );
      case DioExceptionType.badCertificate:
        return const ApiFailure(
          kind: ApiFailureKind.network,
          message: 'Không thể xác minh kết nối an toàn tới máy chủ.',
        );
      case DioExceptionType.badResponse:
        return _fromResponse(error);
      case DioExceptionType.unknown:
        return const ApiFailure(
          kind: ApiFailureKind.unknown,
          message: 'Đã xảy ra lỗi không xác định.',
        );
    }
  }

  static ApiFailure _fromResponse(DioException error) {
    final response = error.response;
    final status = response?.statusCode;
    final body = response?.data;
    final bodyMap = body is Map ? Map<String, dynamic>.from(body) : null;
    final rawMessage = bodyMap?['message'];
    final details = rawMessage is List
        ? rawMessage.whereType<String>().toList(growable: false)
        : const <String>[];
    final requestId = bodyMap?['requestId'] is String
        ? bodyMap!['requestId'] as String
        : response?.headers.value('x-request-id');
    final retryAfterSeconds = int.tryParse(
      response?.headers.value('retry-after') ?? '',
    );
    final retryAfter = retryAfterSeconds == null
        ? null
        : Duration(seconds: retryAfterSeconds);
    final isLogin = error.requestOptions.path.endsWith('/auth/login');

    return switch (status) {
      400 => ApiFailure(
        kind: ApiFailureKind.validation,
        message: 'Dữ liệu gửi lên chưa hợp lệ.',
        statusCode: status,
        requestId: requestId,
        details: details,
      ),
      401 => ApiFailure(
        kind: ApiFailureKind.unauthorized,
        message: isLogin
            ? 'Thông tin đăng nhập không đúng hoặc tài khoản đang tạm khóa.'
            : 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        statusCode: status,
        requestId: requestId,
      ),
      403 => ApiFailure(
        kind: ApiFailureKind.forbidden,
        message: 'Bạn không có quyền thực hiện thao tác này.',
        statusCode: status,
        requestId: requestId,
      ),
      404 => ApiFailure(
        kind: ApiFailureKind.notFound,
        message: 'Không tìm thấy dữ liệu yêu cầu.',
        statusCode: status,
        requestId: requestId,
      ),
      409 => ApiFailure(
        kind: ApiFailureKind.conflict,
        message: 'Trạng thái dữ liệu vừa thay đổi. Vui lòng tải lại.',
        statusCode: status,
        requestId: requestId,
      ),
      429 => ApiFailure(
        kind: ApiFailureKind.rateLimited,
        message: 'Bạn thao tác quá nhanh. Vui lòng chờ rồi thử lại.',
        statusCode: status,
        requestId: requestId,
        retryAfter: retryAfter,
      ),
      final code? when code >= 500 => ApiFailure(
        kind: ApiFailureKind.server,
        message: 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
        statusCode: status,
        requestId: requestId,
      ),
      _ => ApiFailure(
        kind: ApiFailureKind.unknown,
        message: 'Yêu cầu không thành công.',
        statusCode: status,
        requestId: requestId,
        details: details,
      ),
    };
  }

  @override
  String toString() =>
      'ApiFailure($kind, status: $statusCode, requestId: $requestId)';
}
