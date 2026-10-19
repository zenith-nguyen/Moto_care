import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/widgets/order_summary.dart';
import '../../home/models/home_destination.dart';
import '../../home/widgets/home_sheets.dart';
import '../models/user_profile.dart';
import '../theme/profile_dashboard_theme.dart';

abstract final class ProfileDashboardSheets {
  static void information(
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
          style: const TextStyle(
            color: ProfileDashboardTheme.muted,
            height: 1.6,
          ),
        ),
        if (action != null && route != null) ...[
          const SizedBox(height: 20),
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

  static void expenses(BuildContext context, WidgetRef ref) {
    final summary = ref.read(completedOrderSummaryProvider);
    showHomeSheet<void>(
      context,
      HomeSheetContent(
        title: 'Sổ tay bảo dưỡng & Chi tiêu',
        children: [
          Text(
            formatOrderPrice(summary.total),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.orders.length} đơn hoàn thành • ${summary.maintenanceCount} lần bảo dưỡng',
          ),
          const SizedBox(height: 16),
          const Text(
            'Tổng hợp từ các đơn đã hoàn thành trong phiên dùng thử. Chưa có bản ghi bảo dưỡng riêng.',
            style: TextStyle(color: ProfileDashboardTheme.muted, height: 1.6),
          ),
          const SizedBox(height: 20),
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

  static void emergency(
    BuildContext context,
    UserProfile profile,
  ) => information(
    context,
    'Liên hệ khẩn cấp',
    profile.emergencyContactPhone.isEmpty
        ? 'Bạn chưa thêm số liên hệ khẩn cấp. Cập nhật người thân trong thông tin cá nhân.'
        : '${profile.emergencyContactName.isEmpty ? 'Người thân' : profile.emergencyContactName}\n${profile.emergencyContactPhone}',
    action: 'Cập nhật người thân',
    route: '/thong-tin-ca-nhan',
  );

  static void vehicle(BuildContext context, UserProfile profile) {
    final vehicle = profile.defaultVehicle;
    information(
      context,
      'Thông tin xe',
      vehicle == null
          ? 'Chưa chọn xe mặc định. Quản lý phương tiện trong danh sách xe của bạn.'
          : 'Xe mặc định: ${vehicle.type}\nBiển số: ${vehicle.plate}\nLoại lốp: ${vehicle.tireType}',
      action: 'Quản lý danh sách xe',
      route: '/xe-cua-toi',
    );
  }

  static void addresses(
    BuildContext context,
    UserProfile profile,
  ) => information(
    context,
    'Địa chỉ đã lưu',
    'Nhà riêng: ${profile.defaultAddress.isEmpty ? 'Chưa cập nhật' : profile.defaultAddress}\n\nCơ quan: ${profile.workAddress.isEmpty ? 'Chưa cập nhật' : profile.workAddress}',
    action: 'Xem thông tin cá nhân',
    route: '/thong-tin-ca-nhan',
  );

  static void payment(BuildContext context) => information(
    context,
    'Phương thức thanh toán',
    'Chuyển khoản ngân hàng qua mã QR SePay.\n\nMỗi đơn có số tiền và nội dung chuyển khoản riêng. Hệ thống chỉ bắt đầu tìm thợ sau khi webhook ngân hàng xác nhận thanh toán.',
  );

  static void insurance(BuildContext context) => information(
    context,
    'Bảo hiểm xe máy TNDS',
    'Chưa có hợp đồng bảo hiểm được liên kết với tài khoản. Tính năng mua và quản lý bảo hiểm chưa được mở.',
  );

  static void shop(BuildContext context) => information(
    context,
    'Đăng ký Tiệm sửa xe / Trạm sạc',
    'Đăng ký dành riêng cho tiệm và trạm sạc chưa được mở. Bạn có thể xem chương trình đối tác và đăng ký hồ sơ thợ hiện có.',
    action: 'Xem chương trình đối tác',
    route: '/dang-ky-tho',
  );

  static void settings(BuildContext context) => showHomeSheet<void>(
    context,
    HomeSheetContent(
      title: 'Cài đặt & Điều khoản',
      children: [
        for (final (label, route) in const [
          ('Tài khoản & Bảo mật', '/thong-tin-ca-nhan'),
          ('Điều khoản & Cam kết dịch vụ', '/cam-ket-dich-vu'),
          ('Trợ giúp', '/faq'),
        ])
          ListTile(
            title: Text(label),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.pop(context);
              context.push(route);
            },
          ),
      ],
    ),
  );
}
