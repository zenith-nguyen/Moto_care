import 'package:flutter/material.dart';

enum HomeDestination {
  personalInfo('Thông tin cá nhân', Icons.account_circle_rounded),
  membership('Tích điểm & Hạng thành viên', Icons.loyalty_rounded),
  nearbyServices('Trạm sạc & Tiệm sửa xe gần nhất', Icons.ev_station_rounded),
  vouchers('Kho ưu đãi', Icons.local_offer_rounded),
  prices('Bảng giá dịch vụ & Phụ tùng', Icons.receipt_long_rounded),
  partnership('Trở thành đối tác (Dành cho thợ)', Icons.handshake_rounded),
  serviceCommitment('Cam kết dịch vụ & Bồi thường', Icons.verified_rounded),
  help('Trung tâm trợ giúp & FAQ', Icons.help_outline_rounded),
  emergencyTips('Mẹo tự xử lý sự cố khẩn cấp', Icons.build_circle_outlined),
  home('Trang chủ', Icons.home_rounded),
  services('Dịch vụ', Icons.widgets_rounded),
  account('Tài khoản', Icons.account_circle_rounded),
  myVehicles('Xe của tôi', Icons.two_wheeler_rounded),
  activity('Hoạt động', Icons.history_rounded),
  rescueStations('Trạm cứu hộ', Icons.location_on_rounded),
  messages('Tin nhắn', Icons.mark_email_unread_outlined);

  const HomeDestination(this.label, this.icon);

  final String label;
  final IconData icon;

  static const menuItems = [
    personalInfo,
    membership,
    nearbyServices,
    vouchers,
    prices,
    partnership,
    serviceCommitment,
    help,
    emergencyTips,
  ];

  static const navigationItems = [
    home,
    myVehicles,
    activity,
    rescueStations,
    messages,
  ];

  static const homeNavigationItems = [
    home,
    activity,
    services,
    vouchers,
    account,
  ];

  String get navigationLabel => switch (this) {
    vouchers => 'Kho ưu đãi',
    personalInfo => 'Tài khoản',
    _ => label,
  };
}
