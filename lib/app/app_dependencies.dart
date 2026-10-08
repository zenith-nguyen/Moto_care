import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/secure_token_store.dart';
import '../core/auth/session_invalidation_bus.dart';
import '../core/auth/token_store.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/network/json_api.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/payments/data/payments_repository.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return SecureTokenStore();
});

final sessionInvalidationBusProvider = Provider<SessionInvalidationBus>((ref) {
  final bus = SessionInvalidationBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ),
  );
});

final jsonApiProvider = Provider<JsonApi>((ref) {
  return ApiClient(
    ref.watch(dioProvider),
    ref.watch(tokenStoreProvider),
    ref.watch(sessionInvalidationBusProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HttpAuthRepository(ref.watch(jsonApiProvider));
});

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return HttpPaymentsRepository(ref.watch(jsonApiProvider));
});
