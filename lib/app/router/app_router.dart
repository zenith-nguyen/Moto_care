import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/models/rescue_order.dart';
import '../../features/activity/screens/chi_tiet_don_hang_screen.dart';
import '../../features/activity/screens/hoat_dong_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_finance_screen.dart';
import '../../features/admin/presentation/admin_orders_screen.dart';
import '../../features/admin/presentation/admin_provider_approval_screen.dart';
import '../../features/activity/screens/order_details_screen.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/application/session_state.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/session_bootstrap_page.dart';
import '../../features/auth/presentation/session_error_page.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/chat/models/chat_conversation.dart';
import '../../features/chat/screens/chat_detail_screen.dart';
import '../../features/chat/screens/tin_nhan_screen.dart';
import '../../features/help/screens/faq_screen.dart';
import '../../features/home/models/home_user.dart';
import '../../features/home/models/rescue_location.dart';
import '../../features/home/screens/trang_chu.dart';
import '../../features/location/screens/incident_location_screen.dart';
import '../../features/location/screens/select_location_screen.dart';
import '../../features/partner/screens/dang_ky_tho_screen.dart';
import '../../features/partner/screens/partner_detail_screen.dart';
import '../../features/partner/screens/partner_list_screen.dart';
import '../../features/payments/screens/bank_transfer_screen.dart';
import '../../features/places/screens/tram_sac_tiem_sua_screen.dart';
import '../../features/policy/screens/cam_ket_dich_vu_screen.dart';
import '../../features/pricing/screens/bang_gia_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/thong_tin_ca_nhan_screen.dart';
import '../../features/providers/presentation/provider_chat_screen.dart';
import '../../features/providers/presentation/provider_order_details_screen.dart';
import '../../features/providers/presentation/provider_notifications_screen.dart';
import '../../features/providers/presentation/provider_shell.dart';
import '../../features/providers/presentation/provider_stats_screen.dart';
import '../../features/providers/presentation/provider_support_screen.dart';
import '../../features/rescue/models/marketplace_booking.dart';
import '../../features/rescue/screens/checkout_screen.dart';
import '../../features/rescue/screens/order_tracking_screen.dart';
import '../../features/rescue/screens/rescue_tracking_screen.dart';
import '../../features/rescue/screens/service_rating_screen.dart';
import '../../features/rescue_station/models/station_model.dart';
import '../../features/rescue_station/screens/station_detail_screen.dart';
import '../../features/rescue_station/screens/tram_cuu_ho_screen.dart';
import '../../features/services/screens/services_screen.dart';
import '../../features/tips/screens/meo_xu_ly_screen.dart';
import '../../features/vehicle/screens/xe_cua_toi_screen.dart';
import '../app_dependencies.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionState = ref.watch(sessionControllerProvider);
  final providerOnly = isProviderOnlyRuntime(
    ref.watch(runtimeAllowedRolesProvider),
  );
  final sessionLocation = locationForSession(
    sessionState,
    providerOnly: providerOnly,
  );
  final router = GoRouter(
    initialLocation: sessionLocation,
    redirect: (context, state) {
      final location = state.matchedLocation;

      return switch (sessionState) {
        SessionBooting() || SessionUnavailable() =>
          location == sessionLocation ? null : sessionLocation,
        SessionAuthenticating() || SessionSignedOut() =>
          providerOnly && location == '/welcome'
              ? '/login'
              : _publicAuthLocations.contains(location)
              ? null
              : sessionLocation,
        SessionSignedIn(:final session) =>
          isAllowedForRole(location, session.user.role)
              ? null
              : _roleLocation(session.user.role),
      };
    },
    routes: [
      GoRoute(
        path: '/bootstrap',
        builder: (context, state) => const SessionBootstrapPage(),
      ),
      GoRoute(
        path: '/session-error',
        builder: (context, state) => const SessionErrorPage(),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: WelcomeScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: RegisterScreen()),
      ),
      GoRoute(
        path: '/customer',
        pageBuilder: (context, state) =>
            NoTransitionPage(child: _CustomerHome(sessionState: sessionState)),
      ),
      GoRoute(
        path: '/provider',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ProviderShell()),
      ),
      GoRoute(
        path: '/provider/orders/:orderId',
        builder: (context, state) => ProviderOrderDetailsScreen(
          orderId: int.parse(state.pathParameters['orderId']!),
        ),
      ),
      GoRoute(
        path: '/provider/orders/:orderId/chat',
        builder: (context, state) => ProviderChatScreen(
          orderId: int.parse(state.pathParameters['orderId']!),
        ),
      ),
      GoRoute(
        path: '/provider/stats',
        builder: (context, state) => const ProviderStatsScreen(),
      ),
      GoRoute(
        path: '/provider/notifications',
        builder: (context, state) => const ProviderNotificationsScreen(),
      ),
      GoRoute(
        path: '/provider/support',
        builder: (context, state) => const ProviderSupportScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/providers',
        builder: (context, state) => const AdminProviderApprovalScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/finance',
        builder: (context, state) => const AdminFinanceScreen(),
      ),
      GoRoute(
        path: '/stations/:stationId',
        builder: (context, state) => StationDetailRoute(
          stationId: state.pathParameters['stationId']!,
          station: state.extra is StationModel
              ? state.extra as StationModel
              : null,
          serviceType: state.uri.queryParameters['service'] ?? 'Tất cả dịch vụ',
        ),
      ),
      GoRoute(
        path: '/stations/:stationId/reviews',
        builder: (context, state) => StationDetailRoute(
          stationId: state.pathParameters['stationId']!,
          station: state.extra is StationModel
              ? state.extra as StationModel
              : null,
          showReviews: true,
        ),
      ),
      GoRoute(
        path: '/partners',
        builder: (context, state) => PartnerListScreen(
          serviceType: state.uri.queryParameters['service'] ?? 'Tất cả dịch vụ',
        ),
      ),
      GoRoute(
        path: '/partners/:partnerId',
        builder: (context, state) => PartnerDetailScreen(
          partnerId: state.pathParameters['partnerId']!,
          serviceType: state.uri.queryParameters['service'] ?? 'Tất cả dịch vụ',
        ),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => CheckoutScreen(
          booking: state.extra is MarketplaceBooking
              ? state.extra as MarketplaceBooking
              : null,
        ),
      ),
      GoRoute(
        path: '/order-tracking',
        builder: (context, state) =>
            OrderTrackingScreen(orderId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/bank-transfer',
        builder: (context, state) => BankTransferScreen(
          orderId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/rescue-tracking',
        builder: (context, state) =>
            RescueTrackingScreen(orderId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/service-rating',
        builder: (context, state) =>
            ServiceRatingScreen(orderId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/hoat-dong',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HoatDongScreen()),
      ),
      GoRoute(
        path: '/tai-khoan',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ProfileScreen()),
      ),
      GoRoute(
        path: '/dich-vu',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ServicesScreen()),
      ),
      GoRoute(
        path: '/order-details',
        builder: (context, state) => OrderDetailsScreen(
          orderId:
              state.uri.queryParameters['id'] ??
              (state.extra is RescueOrder
                  ? (state.extra as RescueOrder).id
                  : null),
        ),
      ),
      GoRoute(
        path: '/chi-tiet-don-hang',
        builder: (context, state) => ChiTietDonHangScreen(
          orderId:
              state.uri.queryParameters['id'] ??
              (state.extra is RescueOrder
                  ? (state.extra as RescueOrder).id
                  : null),
        ),
      ),
      GoRoute(
        path: '/tin-nhan',
        pageBuilder: (context, state) => NoTransitionPage(
          child: TinNhanScreen(
            initialTabIndex: state.uri.queryParameters['tab'] == 'notifications'
                ? 2
                : 0,
          ),
        ),
      ),
      GoRoute(
        path: '/chat-detail',
        builder: (context, state) => ChatDetailScreen(
          conversation: state.extra is ChatConversation
              ? state.extra as ChatConversation
              : null,
        ),
      ),
      GoRoute(
        path: '/thong-tin-ca-nhan',
        builder: (context, state) => ThongTinCaNhanScreen(
          user: state.extra is HomeUser ? state.extra as HomeUser : null,
        ),
      ),
      GoRoute(
        path: '/tram-sac-tiem-sua',
        builder: (context, state) => const TramSacTiemSuaScreen(),
      ),
      GoRoute(
        path: '/bang-gia',
        builder: (context, state) => const BangGiaScreen(),
      ),
      GoRoute(
        path: '/dang-ky-tho',
        builder: (context, state) => const DangKyThoScreen(),
      ),
      GoRoute(
        path: '/cam-ket-dich-vu',
        builder: (context, state) => const CamKetDichVuScreen(),
      ),
      GoRoute(path: '/faq', builder: (context, state) => const FaqScreen()),
      GoRoute(
        path: '/meo-xu-ly',
        builder: (context, state) => const MeoXuLyScreen(),
      ),
      GoRoute(
        path: '/xe-cua-toi',
        builder: (context, state) => const XeCuaToiScreen(),
      ),
      GoRoute(
        path: '/tram-cuu-ho',
        builder: (context, state) => TramCuuHoScreen(
          initialMapView: state.uri.queryParameters['view'] == 'map',
        ),
      ),
      GoRoute(
        path: '/incident-location',
        builder: (context, state) => SelectLocationScreen(
          returnSelection: state.uri.queryParameters['pick'] == '1',
          initialLocation: state.extra is RescueLocation
              ? state.extra as RescueLocation
              : null,
        ),
      ),
      GoRoute(
        path: '/incident-map-picker',
        builder: (context, state) => ConfirmLocationScreen(
          initialLocation: state.extra is RescueLocation
              ? state.extra as RescueLocation
              : null,
        ),
      ),
      GoRoute(path: '/', redirect: (context, state) => '/welcome'),
      GoRoute(path: '/sign-in', redirect: (context, state) => '/login'),
      GoRoute(path: '/trang-chu', redirect: (context, state) => '/customer'),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

const _publicAuthLocations = {
  '/welcome',
  '/login',
  '/sign-in',
  '/forgot-password',
  '/register',
};

const _customerLocations = {
  '/customer',
  '/checkout',
  '/bank-transfer',
  '/order-tracking',
  '/rescue-tracking',
  '/service-rating',
  '/hoat-dong',
  '/tai-khoan',
  '/dich-vu',
  '/order-details',
  '/chi-tiet-don-hang',
  '/tin-nhan',
  '/chat-detail',
  '/thong-tin-ca-nhan',
  '/tram-sac-tiem-sua',
  '/bang-gia',
  '/dang-ky-tho',
  '/cam-ket-dich-vu',
  '/faq',
  '/meo-xu-ly',
  '/xe-cua-toi',
  '/tram-cuu-ho',
  '/incident-location',
  '/incident-map-picker',
};

@visibleForTesting
bool isAllowedForRole(String location, AppRole role) {
  return switch (role) {
    AppRole.customer =>
      _customerLocations.contains(location) ||
          location.startsWith('/stations/') ||
          location == '/partners' ||
          location.startsWith('/partners/'),
    AppRole.provider =>
      location == '/provider' || location.startsWith('/provider/'),
    AppRole.admin => location == '/admin' || location.startsWith('/admin/'),
  };
}

@visibleForTesting
String locationForSession(SessionState state, {bool providerOnly = false}) {
  return switch (state) {
    SessionBooting() => '/bootstrap',
    SessionAuthenticating() => '/login',
    SessionSignedOut(:final failure) =>
      failure == null && !providerOnly ? '/welcome' : '/login',
    SessionUnavailable() => '/session-error',
    SessionSignedIn(:final session) => _roleLocation(session.user.role),
  };
}

String _roleLocation(AppRole role) {
  return switch (role) {
    AppRole.customer => '/customer',
    AppRole.provider => '/provider',
    AppRole.admin => '/admin',
  };
}

class _CustomerHome extends StatelessWidget {
  const _CustomerHome({required this.sessionState});

  final SessionState sessionState;

  @override
  Widget build(BuildContext context) {
    final session = (sessionState as SessionSignedIn).session;
    return TrangChu(
      user: HomeUser(
        displayName: session.user.name,
        memberId: session.user.id.toString(),
      ),
    );
  }
}
