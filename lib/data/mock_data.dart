import 'package:flutter/material.dart';

import '../models/models.dart';

/// Toàn bộ dữ liệu mẫu của app (không gọi API).
class MockData {
  MockData._();

  static const String weekRange = '30/09 – 06/10/2026';
  static const int lastWeekIncome = 1850000;
  static const int lastWeekOrders = 12;
  static const double lastWeekRating = 4.9;

  static const int weatherTemp = 32;
  static const String weatherTitle = 'Nắng nóng, dễ nổ lốp';
  static const String weatherNote = 'Lưu ý khi di chuyển ngoài trời';

  static const String supportHotline = '1900 6868';

  static const String rejectReason =
      'Ảnh CCCD bị mờ, không đọc rõ số giấy tờ. Vui lòng chụp lại ảnh rõ nét, đủ 4 góc.';
  static const String rejectRequirement = 'Ảnh mặt trước CCCD, chụp rõ dưới ánh sáng đủ';

  static const List<String> districts = [
    'Quận 1',
    'Quận 3',
    'Quận 5',
    'Quận 10',
    'Quận 11',
    'Bình Thạnh',
    'Phú Nhuận',
    'Tân Bình',
  ];

  /// Mock đăng nhập: email/SĐT chứa "pending" -> hồ sơ chờ duyệt,
  /// chứa "rejected" -> hồ sơ bị từ chối, còn lại -> đã duyệt.
  static AccountStatus accountStatusFor(String identifier) {
    final id = identifier.toLowerCase();
    if (id.contains('pending')) return AccountStatus.pending;
    if (id.contains('rejected')) return AccountStatus.rejected;
    return AccountStatus.approved;
  }

  static MechanicProfile profile() => MechanicProfile(
        name: 'Nguyễn Minh Phát',
        email: 'nguyenphat@gmail.com',
        bio: 'Thợ sửa xe máy lưu động, chuyên vá lốp và xử lý sự cố điện. '
            'Luôn mang đầy đủ đồ nghề để xử lý nhanh tại hiện trường.',
        tierName: 'Bạc',
        nextTierName: 'Vàng',
        tierOrders: 44,
        nextTierTarget: 50,
        experienceYears: 5,
        radiusKm: 8,
        rating: 4.9,
        ratingCount: 132,
        area: 'Quận 5',
        skills: [
          Skill(name: 'Vá xe', icon: Icons.adjust, status: VerificationStatus.verified),
          Skill(name: 'Kích bình', icon: Icons.bolt_outlined, status: VerificationStatus.verified),
          Skill(
              name: 'Cẩu kéo',
              icon: Icons.local_shipping_outlined,
              status: VerificationStatus.pending),
          Skill(
              name: 'Thay nhớt',
              icon: Icons.water_drop_outlined,
              status: VerificationStatus.verified),
          Skill(
              name: 'Sửa điện, còi',
              icon: Icons.power_outlined,
              status: VerificationStatus.rejected),
        ],
        documents: const [
          VerificationDoc(
              name: 'CCCD', icon: Icons.badge_outlined, status: VerificationStatus.verified),
          VerificationDoc(
              name: 'Chứng chỉ nghề',
              icon: Icons.workspace_premium_outlined,
              status: VerificationStatus.pending),
        ],
      );

  /// Kỹ năng có thể đăng ký thêm (Admin sẽ xác minh).
  static const List<(String, IconData)> extraSkills = [
    ('Tiếp xăng khẩn cấp', Icons.local_gas_station_outlined),
    ('Thay săm, lốp', Icons.tire_repair_outlined),
    ('Sửa phanh', Icons.build_outlined),
  ];

  static const List<OrderOffer> offers = [
    OrderOffer(
      code: '#MC105',
      service: ServiceType.battery,
      issue: 'Hết bình, cần kích bình',
      description: 'Xe không nổ máy do hết bình ắc quy. Đã kiểm tra, cần kích bình và '
          'kiểm tra lại hệ thống sạc trước khi giao xe.',
      vehicle: 'Honda Vario 150',
      plate: '59S1-123.45',
      customerName: 'Trần Quốc Bảo',
      customerPhone: '0901234545',
      address: '273 An Dương Vương, Q.5',
      distanceKm: 1.2,
      etaMinutes: 6,
      price: 150000,
    ),
    OrderOffer(
      code: '#MC106',
      service: ServiceType.tire,
      issue: 'Vá lốp không ruột',
      description: 'Lốp sau bị đinh, xì hơi hoàn toàn. Khách đang dắt xe ven đường, '
          'cần vá lốp không ruột tại chỗ.',
      vehicle: 'Yamaha Exciter 155',
      plate: '59X2-456.78',
      customerName: 'Lê Thị Hạnh',
      customerPhone: '0912345678',
      address: '56 Nguyễn Trãi, Q.5',
      distanceKm: 2.4,
      etaMinutes: 9,
      price: 60000,
    ),
  ];

  static List<ChatMessage> openingChat(DateTime acceptedAt) => [
        ChatMessage(
          fromMechanic: false,
          time: acceptedAt.add(const Duration(seconds: 20)),
          text: 'Anh ơi em đứng trước nhà sách, xe đề không lên luôn ạ.',
        ),
        ChatMessage(
          fromMechanic: false,
          time: acceptedAt.add(const Duration(seconds: 35)),
          isImage: true,
        ),
        ChatMessage(
          fromMechanic: true,
          time: acceptedAt.add(const Duration(minutes: 1)),
          text: 'Anh tới liền nha, em đứng chỗ có bóng mát chờ anh.',
          status: MessageStatus.failed,
        ),
      ];

  static DateTime _at(int daysAgo, int h, int m) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - daysAgo, h, m);
  }

  static List<TimelineEvent> _timeline(DateTime done, {bool cancelled = false}) => cancelled
      ? [
          TimelineEvent('Đã nhận đơn', done.subtract(const Duration(minutes: 12))),
          TimelineEvent('Đơn bị hủy', done),
        ]
      : [
          TimelineEvent('Đã nhận đơn', done.subtract(const Duration(minutes: 41))),
          TimelineEvent('Đã đến nơi', done.subtract(const Duration(minutes: 33))),
          TimelineEvent('Bắt đầu sửa chữa', done.subtract(const Duration(minutes: 31))),
          TimelineEvent('Hoàn thành', done),
        ];

  static List<OrderHistoryItem> history() {
    OrderHistoryItem done(
      String code,
      ServiceType service,
      String issue,
      int daysAgo,
      int h,
      int m,
      int price, {
      String vehicle = 'Honda Vision',
      String plate = '59C1-246.80',
      String customer = 'Trần Văn Khách',
      String phone = '0900000012',
      String address = 'Quận 5, TP.HCM',
      int? rating,
      String? comment,
    }) {
      final t = _at(daysAgo, h, m);
      return OrderHistoryItem(
        code: code,
        service: service,
        issue: issue,
        vehicle: vehicle,
        plate: plate,
        customerName: customer,
        customerPhone: phone,
        address: address,
        status: OrderStatus.completed,
        time: t,
        initialPrice: price,
        finalPrice: price,
        timeline: _timeline(t),
        messages: [
          ChatMessage(
            fromMechanic: false,
            time: t.subtract(const Duration(minutes: 40)),
            text: 'Em ở đầu hẻm nha anh.',
          ),
          ChatMessage(
            fromMechanic: true,
            time: t.subtract(const Duration(minutes: 39)),
            text: 'Ok em, anh tới liền.',
          ),
        ],
        rating: rating,
        ratingComment: comment,
      );
    }

    OrderHistoryItem cancelled(
        String code, ServiceType service, String issue, int daysAgo, int h, int m, int price) {
      final t = _at(daysAgo, h, m);
      return OrderHistoryItem(
        code: code,
        service: service,
        issue: issue,
        vehicle: 'Yamaha Sirius',
        plate: '59K1-135.79',
        customerName: 'Phạm Đức Anh',
        customerPhone: '0987654321',
        address: 'Quận 10, TP.HCM',
        status: OrderStatus.cancelled,
        time: t,
        initialPrice: price,
        finalPrice: price,
        timeline: _timeline(t, cancelled: true),
      );
    }

    return [
      done('#MC104', ServiceType.battery, 'Kích bình ắc quy', 0, 16, 42, 95000,
          rating: 5, comment: 'Khách thân thiện, chỉ đường rõ ràng.'),
      done('#MC103', ServiceType.tire, 'Vá lốp không ruột', 0, 15, 10, 150000,
          vehicle: 'Honda Air Blade', customer: 'Lê Minh Tú', phone: '0938112233'),
      done('#MC102', ServiceType.tow, 'Cẩu kéo về tiệm', 0, 11, 25, 60000,
          vehicle: 'Honda SH 150i', customer: 'Võ Thanh Tùng', phone: '0933111222'),
      cancelled('#MC100', ServiceType.tire, 'Vá lốp không ruột', 1, 21, 10, 60000),
      done('#MC098', ServiceType.battery, 'Kích bình ắc quy', 1, 20, 5, 95000, rating: 4),
      done('#MC095', ServiceType.tire, 'Thay ruột xe', 1, 14, 30, 120000,
          vehicle: 'Honda Wave Alpha', rating: 5),
      cancelled('#MC093', ServiceType.oil, 'Thay nhớt', 3, 10, 15, 80000),
      done('#MC090', ServiceType.electric, 'Sửa điện, còi', 6, 9, 12, 80000,
          vehicle: 'Yamaha Janus', rating: 5),
    ];
  }

  /// Lịch sử giao dịch ví (mới nhất trước).
  static List<WalletTransaction> transactions() {
    WalletTransaction credit(String code, String txn, int daysAgo, int h, int m, int price,
        String service, String customer, String phone) {
      final fee = feeOf(price);
      return WalletTransaction(
        code: code,
        txnId: txn,
        type: TxType.credit,
        amount: price - fee,
        time: _at(daysAgo, h, m),
        orderCode: code,
        serviceName: service,
        customerName: customer,
        customerPhone: phone,
        customerArea: 'Quận 5, TP.HCM',
        platformFee: fee,
      );
    }

    return [
      credit('#MC104', 'TXN-88213049', 0, 16, 42, 95000, 'Kích bình ắc quy', 'Trần Văn Khách',
          '0900000012'),
      credit('#MC103', 'TXN-88212877', 0, 15, 10, 150000, 'Vá lốp không ruột', 'Lê Minh Tú',
          '0938112233'),
      WalletTransaction(
        code: '#RT0032',
        txnId: 'TXN-88212510',
        type: TxType.debit,
        amount: 500000,
        time: _at(0, 14, 0),
        withdrawStatus: WithdrawStatus.pending,
      ),
      credit('#MC102', 'TXN-88211954', 0, 11, 25, 60000, 'Cẩu kéo về tiệm', 'Võ Thanh Tùng',
          '0933111222'),
      credit('#MC098', 'TXN-88209318', 1, 20, 5, 95000, 'Kích bình ắc quy', 'Trần Văn Khách',
          '0900000012'),
      WalletTransaction(
        code: '#RT0031',
        txnId: 'TXN-88209102',
        type: TxType.debit,
        amount: 300000,
        time: _at(1, 18, 20),
        withdrawStatus: WithdrawStatus.approved,
      ),
      credit('#MC095', 'TXN-88208447', 1, 14, 30, 120000, 'Thay ruột xe', 'Trần Văn Khách',
          '0900000012'),
    ];
  }

  /// Thu nhập 6 ngày trước hôm nay (cũ -> mới). Hôm nay lấy từ trạng thái ví.
  static const List<int> previousSixDays = [320000, 410000, 280000, 390000, 450000, 250000];
}
