import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/network/json_api.dart';
import 'package:moto_care/features/auth/data/auth_repository.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';

void main() {
  test('sign-in sends the backend contract and parses the session', () async {
    final api = RecordingJsonApi()
      ..postResponse = {
        'accessToken': 'signed-token',
        'user': userJson(role: 'PROVIDER', status: 'PENDING_APPROVAL'),
      };
    final repository = HttpAuthRepository(api);

    final session = await repository.signIn(
      identity: ' provider@example.com ',
      password: 'password123',
    );

    expect(api.lastPath, '/auth/login');
    expect(api.lastData, {
      'identity': 'provider@example.com',
      'password': 'password123',
    });
    expect(session.accessToken, 'signed-token');
    expect(session.user.role, AppRole.provider);
    expect(session.user.status, AppUserStatus.pendingApproval);
  });

  test('does not allow self-registering an administrator', () async {
    final repository = HttpAuthRepository(RecordingJsonApi());

    await expectLater(
      repository.register(
        name: 'Admin',
        password: 'password123',
        role: AppRole.admin,
        email: 'admin@example.com',
      ),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> userJson({
  String role = 'CUSTOMER',
  String status = 'ACTIVE',
}) {
  return {
    'id': 1,
    'name': 'MotoCare Test',
    'email': 'test@example.com',
    'phone': null,
    'role': role,
    'status': status,
  };
}

class RecordingJsonApi implements JsonApi {
  Map<String, dynamic> postResponse = {};
  String? lastPath;
  Object? lastData;

  @override
  Future<BinaryResponse> getBinary(String path) {
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    return userJson();
  }

  @override
  Future<Map<String, dynamic>> patchObject(String path, {Object? data}) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postObject(String path, {Object? data}) async {
    lastPath = path;
    lastData = data;
    return postResponse;
  }

  @override
  Future<Map<String, dynamic>> postMultipartObject(
    String path, {
    Map<String, String> fields = const {},
    required BinaryUpload file,
  }) {
    throw UnimplementedError();
  }
}
