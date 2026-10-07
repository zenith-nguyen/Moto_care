import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/widgets/order_summary.dart';
import '../../home/models/home_destination.dart';
import '../../home/theme/home_theme.dart';
import '../../home/widgets/home_bottom_navigation.dart';
import '../../home/widgets/home_sections.dart';
import '../../home/widgets/home_sheets.dart';
import '../providers/profile_provider.dart';
import '../widgets/account_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _information(
    BuildContext context,
    String title,
    String message, {
    String? action,
    String? route,
  }) => showHomeSheet<void>(
    context,
    HomeSheetContent(
      title: title,
      children: [
        Text(
          message,
          style: const TextStyle(color: HomeColors.secondary, height: 1.6),
        ),
        if (action != null && route != null) ...[
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(route);
            },
            child: Text(action),
          ),
        ],
      ],
    ),
  );

  void _expenses(BuildContext context, WidgetRef ref) {
    final orders = ref
        .read(activityProvider)
        .historyOrders
        .where((order) => order.status == RescueOrderStatus.completed)
        .toList();
    final total = orders.fold<int>(0, (sum, order) => sum + order.totalPrice);
    final maintenanceCount = orders
        .where((order) => order.serviceType == RescueServiceType.maintenance)
        .length;
    showHomeSheet<void>(
      context,
      HomeSheetContent(
        title: 'Sổ tay bảo dưỡng & Chi tiêu',
        children: [
          const Text(
            'Chi tiêu từ các đơn đã hoàn thành',
            style: TextStyle(color: HomeColors.secondary),
          ),
          const SizedBox(height: 8),
          Text(
            formatOrderPrice(total),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            '${orders.length} đơn hoàn thành • $maintenanceCount lần bảo dưỡng',
          ),
          const SizedBox(height: 16),
          const Text(
            'Số liệu theo lịch sử hiện có trong phiên dùng thử.',
            style: TextStyle(color: HomeColors.secondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              navigateMainTab(context, HomeDestination.activity);
            },
            child: const Text('Xem lịch sử dịch vụ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    final profile = state.profile;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Theme(
        data: HomeTheme.light,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  key: const ValueKey('account-scroll'),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    AccountHeader(
                      state: state,
                      onEdit: () => context.push('/thong-tin-ca-nhan'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: HomeClubCard(
                        points: profile.rewardPoints,
                        tier: profile.memberTier,
                        actionLabel: 'Đổi quà ›',
                        onPressed: () => context.push('/tich-diem'),
                      ),
                    ),
                    AccountMenuGroup(
                      title: 'Quản lý xe & Sự cố',
                      items: [
                        AccountMenuItem(
                          'vehicles',
                          'Danh sách xe của tôi',
                          Icons.two_wheeler_rounded,
                          () => context.push('/xe-cua-toi'),
                        ),
                        AccountMenuItem(
                          'expenses',
                          'Sổ tay bảo dưỡng & Chi tiêu',
                          Icons.menu_book_rounded,
                          () => _expenses(context, ref),
                        ),
                        AccountMenuItem(
                          'emergency',
                          'Liên hệ khẩn cấp (Người thân)',
                          Icons.health_and_safety_outlined,
                          () => _information(
                            context,
                            'Liên hệ khẩn cấp',
                            profile.emergencyContactPhone.isEmpty
                                ? 'Bạn chưa thêm số liên hệ khẩn cấp. Cập nhật người thân trong thông tin cá nhân.'
                                : '${profile.emergencyContactName.isEmpty ? 'Người thân' : profile.emergencyContactName}\n${profile.emergencyContactPhone}',
                            action: 'Cập nhật người thân',
                            route: '/thong-tin-ca-nhan',
                          ),
                        ),
                        AccountMenuItem(
                          'payment',
                          'Phương thức thanh toán',
                          Icons.account_balance_wallet_outlined,
                          () => _information(
                            context,
                            'Phương thức thanh toán',
                            'Tiền mặt\nThanh toán trực tiếp cho thợ hoặc tiệm sau khi xác nhận chi phí.\n\nChưa có thẻ hoặc ví điện tử được liên kết.',
                          ),
                        ),
                      ],
                    ),
                    AccountMenuGroup(
                      title: 'Dành cho Đối tác & Tiệm',
                      items: [
                        AccountMenuItem(
                          'mechanic',
                          'Đăng ký Trở thành Đối tác Thợ',
                          Icons.build_outlined,
                          () => context.push('/dang-ky-tho'),
                        ),
                        AccountMenuItem(
                          'shop',
                          'Đăng ký Tiệm sửa xe / Trạm sạc',
                          Icons.storefront_outlined,
                          () => _information(
                            context,
                            'Đăng ký Tiệm sửa xe / Trạm sạc',
                            'Đăng ký dành riêng cho tiệm và trạm sạc chưa được mở. Bạn có thể xem chương trình đối tác và đăng ký hồ sơ thợ hiện có.',
                            action: 'Xem chương trình đối tác',
                            route: '/dang-ky-tho',
                          ),
                        ),
                      ],
                    ),
                    AccountMenuGroup(
                      title: 'Hệ thống & Trợ giúp',
                      items: [
                        AccountMenuItem(
                          'personal-info',
                          'Thông tin cá nhân',
                          Icons.account_circle_outlined,
                          () => context.push('/thong-tin-ca-nhan'),
                        ),
                        AccountMenuItem(
                          'membership',
                          'Tích điểm & Hạng thành viên',
                          Icons.loyalty_rounded,
                          () => context.push('/tich-diem'),
                        ),
                        AccountMenuItem(
                          'places',
                          'Trạm sạc & Tiệm sửa xe gần nhất',
                          Icons.ev_station_rounded,
                          () => context.push('/tram-sac-tiem-sua'),
                        ),
                        AccountMenuItem(
                          'prices',
                          'Bảng giá dịch vụ & Phụ tùng',
                          Icons.receipt_long_rounded,
                          () => context.push('/bang-gia'),
                        ),
                        AccountMenuItem(
                          'vouchers',
                          'Kho ưu đãi',
                          Icons.local_offer_outlined,
                          () => context.push('/kho-voucher'),
                        ),
                        AccountMenuItem(
                          'insurance',
                          'Bảo hiểm xe máy TNDS',
                          Icons.shield_outlined,
                          () => _information(
                            context,
                            'Bảo hiểm xe máy TNDS',
                            'Chưa có hợp đồng bảo hiểm được liên kết với tài khoản. Tính năng mua và quản lý bảo hiểm chưa được mở.',
                          ),
                        ),
                        AccountMenuItem(
                          'help',
                          'Trung tâm trợ giúp & FAQ',
                          Icons.help_outline_rounded,
                          () => context.push('/faq'),
                        ),
                        AccountMenuItem(
                          'commitment',
                          'Cam kết dịch vụ & Bồi thường',
                          Icons.verified_user_outlined,
                          () => context.push('/cam-ket-dich-vu'),
                        ),
                        AccountMenuItem(
                          'tips',
                          'Mẹo tự xử lý sự cố khẩn cấp',
                          Icons.build_circle_outlined,
                          () => context.push('/meo-xu-ly'),
                        ),
                        AccountMenuItem(
                          'messages',
                          'Tin nhắn',
                          Icons.mark_email_unread_outlined,
                          () => context.push('/tin-nhan'),
                        ),
                        AccountMenuItem(
                          'settings',
                          'Cài đặt & Điều khoản',
                          Icons.settings_outlined,
                          () => showHomeSheet<void>(
                            context,
                            HomeSheetContent(
                              title: 'Cài đặt & Điều khoản',
                              children: [
                                for (final (label, route) in const [
                                  ('Tài khoản & Bảo mật', '/thong-tin-ca-nhan'),
                                  (
                                    'Điều khoản & Cam kết dịch vụ',
                                    '/cam-ket-dich-vu',
                                  ),
                                  ('Trợ giúp', '/faq'),
                                ])
                                  ListTile(
                                    title: Text(label),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      context.push(route);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: HomeBottomNavigation(
              light: true,
              selectedDestination: HomeDestination.account,
              onSelected: (destination) =>
                  navigateMainTab(context, destination),
            ),
          ),
        ),
      ),
    );
  }
}
