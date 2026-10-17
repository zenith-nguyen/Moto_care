import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/secure_token_store.dart';
import '../core/auth/session_invalidation_bus.dart';
import '../core/auth/token_store.dart';
import '../core/config/app_config.dart';
import '../core/device/device_location_source.dart';
import '../core/network/api_client.dart';
import '../core/network/json_api.dart';
import '../core/realtime/realtime_client.dart';
import '../core/realtime/realtime_transport.dart';
import '../core/realtime/socket_io_realtime_transport.dart';
import '../core/notifications/installation_id_store.dart';
import '../core/notifications/push_registration_service.dart';
import '../core/notifications/push_token_source.dart';
import '../core/notifications/secure_installation_id_store.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/admin/data/admin_repository.dart';
import '../features/incidents/data/incident_types_repository.dart';
import '../features/messages/data/messages_repository.dart';
import '../features/messages/data/chat_image_picker.dart';
import '../features/orders/data/orders_repository.dart';
import '../features/payments/data/payments_repository.dart';
import '../features/providers/data/providers_repository.dart';
import '../features/reviews/data/reviews_repository.dart';
import '../features/rescue_station/data/service_locations_repository.dart';
import '../features/wallet/data/wallet_repository.dart';
import '../features/notifications/data/notifications_repository.dart';

/// Enabled by the production entrypoint. Tests can keep deterministic fixtures
/// without allowing accidental network requests from unrelated widget tests.
final runtimeApiIntegrationProvider = Provider<bool>((ref) => false);

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return SecureTokenStore();
});

final pushTokenSourceProvider = Provider<PushTokenSource>((ref) {
  return const DisabledPushTokenSource();
});

final installationIdStoreProvider = Provider<InstallationIdStore>((ref) {
  return SecureInstallationIdStore();
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

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return HttpAdminRepository(ref.watch(jsonApiProvider));
});

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return HttpPaymentsRepository(ref.watch(jsonApiProvider));
});

final incidentTypesRepositoryProvider = Provider<IncidentTypesRepository>((
  ref,
) {
  return HttpIncidentTypesRepository(ref.watch(jsonApiProvider));
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return HttpOrdersRepository(ref.watch(jsonApiProvider));
});

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return HttpMessagesRepository(ref.watch(jsonApiProvider));
});

final chatImagePickerProvider = Provider<ChatImagePicker>((ref) {
  return SystemChatImagePicker();
});

final deviceLocationSourceProvider = Provider<DeviceLocationSource>((ref) {
  return const GeolocatorDeviceLocationSource();
});

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return HttpReviewsRepository(ref.watch(jsonApiProvider));
});

final serviceLocationsRepositoryProvider = Provider<ServiceLocationsRepository>(
  (ref) => HttpServiceLocationsRepository(ref.watch(jsonApiProvider)),
);

final providersRepositoryProvider = Provider<ProvidersRepository>((ref) {
  return HttpProvidersRepository(ref.watch(jsonApiProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return HttpWalletRepository(ref.watch(jsonApiProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return HttpNotificationsRepository(ref.watch(jsonApiProvider));
});

final pushRegistrationServiceProvider = Provider<PushRegistrationService>((
  ref,
) {
  final service = PushRegistrationService(
    ref.watch(pushTokenSourceProvider),
    ref.watch(installationIdStoreProvider),
    ref.watch(notificationsRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final realtimeTransportProvider = Provider<RealtimeTransport>((ref) {
  return SocketIoRealtimeTransport();
});

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(ref.watch(realtimeTransportProvider));
  ref.onDispose(client.dispose);
  return client;
});
