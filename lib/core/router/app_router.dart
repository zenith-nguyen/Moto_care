import 'package:go_router/go_router.dart';

import '../../features/activity/models/rescue_order.dart';
import '../../features/activity/screens/chi_tiet_don_hang_screen.dart';
import '../../features/activity/screens/hoat_dong_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/chat/models/chat_conversation.dart';
import '../../features/chat/screens/chat_detail_screen.dart';
import '../../features/chat/screens/tin_nhan_screen.dart';
import '../../features/home/models/home_user.dart';
import '../../features/home/models/rescue_location.dart';
import '../../features/location/screens/select_location_screen.dart';
import '../../features/location/screens/incident_location_screen.dart';
import '../../features/home/screens/trang_chu.dart';
import '../../features/help/screens/faq_screen.dart';
import '../../features/membership/screens/tich_diem_screen.dart';
import '../../features/partner/screens/dang_ky_tho_screen.dart';
import '../../features/partner/screens/partner_list_screen.dart';
import '../../features/partner/screens/partner_detail_screen.dart';
import '../../features/rescue/models/marketplace_booking.dart';
import '../../features/rescue/screens/checkout_screen.dart';
import '../../features/rescue/screens/rescue_tracking_screen.dart';
import '../../features/rescue/screens/order_tracking_screen.dart';
import '../../features/places/screens/tram_sac_tiem_sua_screen.dart';
import '../../features/policy/screens/cam_ket_dich_vu_screen.dart';
import '../../features/pricing/screens/bang_gia_screen.dart';
import '../../features/profile/screens/thong_tin_ca_nhan_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/services/screens/services_screen.dart';
import '../../features/tips/screens/meo_xu_ly_screen.dart';
import '../../features/voucher/screens/kho_voucher_screen.dart';
import '../../features/vehicle/screens/xe_cua_toi_screen.dart';
import '../../features/rescue_station/screens/tram_cuu_ho_screen.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
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
        path: '/rescue-tracking',
        builder: (context, state) =>
            RescueTrackingScreen(orderId: state.uri.queryParameters['id']),
      ),
      GoRoute(path: '/', redirect: (context, state) => '/login'),
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
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TinNhanScreen()),
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
        path: '/tich-diem',
        builder: (context, state) => TichDiemScreen(
          user: state.extra is HomeUser ? state.extra as HomeUser : null,
        ),
      ),
      GoRoute(
        path: '/tram-sac-tiem-sua',
        builder: (context, state) => const TramSacTiemSuaScreen(),
      ),
      GoRoute(
        path: '/kho-voucher',
        builder: (context, state) => const KhoVoucherScreen(),
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
        builder: (context, state) => const TramCuuHoScreen(),
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
        builder: (context, state) => IncidentLocationScreen(
          initialLocation: state.extra is RescueLocation
              ? state.extra as RescueLocation
              : null,
        ),
      ),
      GoRoute(
        path: '/trang-chu',
        pageBuilder: (context, state) => NoTransitionPage(
          child: TrangChu(
            user: state.extra is HomeUser ? state.extra as HomeUser : null,
          ),
        ),
      ),
    ],
  );
}
