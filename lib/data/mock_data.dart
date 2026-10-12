import '../models/models.dart';

/// Toàn bộ dữ liệu mẫu của app (không gọi API).
class MockData {
  MockData._();

  static const String weekRange = '06/10 – 12/10/2026';
  static const double weekRating = 4.9;
  static const String weekActiveHours = '~18 giờ';

  static const int weatherTemp = 32;
  static const String weatherTitle = '32°C · Nắng nóng';
  static const String weatherNote = 'Dễ nổ lốp giữa trưa, đừng tắt nhận đơn nhé';

  static const String supportHotline = '1900 6868';

  static const String rejectReason =
      'Ảnh mặt trước CCCD bị mờ, không đọc được số giấy tờ. Vui lòng chụp lại nơi đủ sáng.';
  static const String rejectRequirement = 'Ảnh mặt trước CCCD';

  static const List<String> districts = [
    'Quận 1, TP.HCM',
    'Quận 3, TP.HCM',
    'Quận 5, TP.HCM',
    'Quận 10, TP.HCM',
    'Quận 11, TP.HCM',
    'Bình Thạnh, TP.HCM',
    'Phú Nhuận, TP.HCM',
    'Tân Bình, TP.HCM',
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
        name: 'Minh Khang',
        email: 'thokhang@motocare.vn',
        bio: 'Thợ cứu hộ xe máy khu vực Quận 10, 3 năm kinh nghiệm sửa xe số và xe tay ga.',
        tierName: 'Bạc',
        nextTierName: 'Vàng',
        tierOrders: 18,
        nextTierTarget: 24,
        experienceYears: 3,
        radiusKm: 5,
        rating: 4.9,
        ratingCount: 132,
        area: 'Quận 10, TP.HCM',
        skills: [
          Skill(name: 'Vá xe, thay lốp', status: VerificationStatus.verified),
          Skill(name: 'Kích bình, câu điện', status: VerificationStatus.pending),
          Skill(name: 'Cẩu kéo xe', status: VerificationStatus.rejected),
        ],
        documents: const [
          VerificationDoc(name: 'CCCD', status: VerificationStatus.verified),
          VerificationDoc(name: 'Chứng chỉ nghề', status: VerificationStatus.pending),
        ],
      );

  /// Kỹ năng có thể đăng ký thêm (Admin sẽ xác minh).
  static const List<String> extraSkills = [
    'Thay nhớt',
    'Sửa điện, còi',
    'Tiếp xăng khẩn cấp',
    'Sửa phanh',
  ];

  static const List<OrderOffer> offers = [
    OrderOffer(
      code: '#MC2341',
      issue: 'Hết xăng',
      description: '"Xe hết xăng giữa đường, cần tiếp ứng gấp. Đang đứng gần trạm xe buýt."',
      vehicle: 'Honda Vision',
      plate: '59-X1 123.45',
      customerName: 'Minh Anh',
      customerPhone: '0905551298',
      address: '123 Lý Thường Kiệt, P.7, Q.10',
      distanceKm: 1.2,
      etaMinutes: 6,
      price: 74000,
      platformFee: 6000,
    ),
    OrderOffer(
      code: '#MC2342',
      issue: 'Xẹp lốp',
      description: '"Lốp sau bị xẹp hơi, em dắt xe vào lề đường trước cổng bệnh viện."',
      vehicle: 'Yamaha Exciter 155',
      plate: '59-P2 456.78',
      customerName: 'Lê Thị Hạnh',
      customerPhone: '0912345678',
      address: '56 Nguyễn Tri Phương, P.4, Q.10',
      distanceKm: 2.1,
      etaMinutes: 9,
      price: 120000,
      platformFee: 8000,
    ),
  ];

  /// 4 tin nhắn mở đầu (thợ gửi trước, khách trả lời) — giờ tính theo lúc nhận đơn.
  static List<ChatMessage> openingChat(DateTime acceptedAt) => [
        ChatMessage(
          fromMechanic: true,
          time: acceptedAt,
          text: 'Chào bạn, mình đang tới ngay đây, khoảng 6 phút nữa nha',
          status: MessageStatus.seen,
        ),
        ChatMessage(
          fromMechanic: false,
          time: acceptedAt.add(const Duration(seconds: 20)),
          text: 'Dạ ok anh, em đứng gần trạm xe buýt nha',
        ),
        ChatMessage(
          fromMechanic: true,
          time: acceptedAt.add(const Duration(seconds: 40)),
          isImage: true,
        ),
        ChatMessage(
          fromMechanic: false,
          time: acceptedAt.add(const Duration(seconds: 60)),
          text: 'Em thấy xe anh rồi!',
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
          TimelineEvent('Bắt đầu sửa', done.subtract(const Duration(minutes: 31))),
          TimelineEvent('Hoàn thành', done),
        ];

  static OrderHistoryItem _done(
    String code,
    String issue,
    int daysAgo,
    int h,
    int m,
    int price,
    int fee, {
    String vehicle = 'Honda Vision',
    String plate = '59-X1 456.12',
    String customer = 'Trần Văn Khách',
    String phone = '0900000012',
    String address = 'Quận 10, TP.HCM',
    int? customerRating,
    String? customerReview,
  }) {
    final t = _at(daysAgo, h, m);
    return OrderHistoryItem(
      code: code,
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
      fee: fee,
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
          status: MessageStatus.seen,
        ),
      ],
      customerRating: customerRating,
      customerReview: customerReview,
    );
  }

  static OrderHistoryItem _cancelled(String code, String issue, int daysAgo, int h, int m) {
    final t = _at(daysAgo, h, m);
    return OrderHistoryItem(
      code: code,
      issue: issue,
      vehicle: 'Yamaha Sirius',
      plate: '59-K1 135.79',
      customerName: 'Phạm Đức Anh',
      customerPhone: '0987654321',
      address: 'Quận 10, TP.HCM',
      status: OrderStatus.cancelled,
      time: t,
      initialPrice: 0,
      finalPrice: 0,
      fee: 0,
      timeline: _timeline(t, cancelled: true),
    );
  }

  static List<OrderHistoryItem> history() => [
        _done('#MC2298', 'Xẹp lốp', 1, 14, 2, 120000, 8000,
            customerRating: 5, customerReview: 'Thợ tới nhanh, nhiệt tình, giá hợp lý!'),
        _done('#MC2287', 'Chết máy', 2, 9, 40, 150000, 9000,
            vehicle: 'Honda SH 150i', customerRating: 5, customerReview: 'Làm việc gọn gàng.'),
        _cancelled('#MC2279', 'Hết xăng', 3, 19, 21),
        _cancelled('#MC2271', 'Xẹp lốp', 4, 8, 5),
      ];

  /// Lịch sử giao dịch ví (mới nhất trước).
  static List<WalletTransaction> transactions() => [
        WalletTransaction(
          code: '#RT0032',
          txnId: 'TX-88190',
          type: TxType.debit,
          amount: 500000,
          time: _at(0, 7, 10),
          withdrawStatus: WithdrawStatus.pending,
        ),
        WalletTransaction(
          code: '#MC2298',
          txnId: 'TX-88041',
          type: TxType.credit,
          amount: 112000,
          time: _at(1, 14, 10),
          orderCode: '#MC2298',
          serviceName: 'Xẹp lốp',
          customerName: 'Trần Văn Khách',
          customerPhone: '0900000012',
          finalPrice: 120000,
          platformFee: 8000,
        ),
        WalletTransaction(
          code: '#MC2287',
          txnId: 'TX-87960',
          type: TxType.credit,
          amount: 141000,
          time: _at(2, 9, 48),
          orderCode: '#MC2287',
          serviceName: 'Chết máy',
          customerName: 'Trần Văn Khách',
          customerPhone: '0900000012',
          finalPrice: 150000,
          platformFee: 9000,
        ),
        WalletTransaction(
          code: '#RT0031',
          txnId: 'TX-87802',
          type: TxType.debit,
          amount: 300000,
          time: _at(3, 18, 20),
          withdrawStatus: WithdrawStatus.approved,
        ),
      ];

  /// Thu nhập theo ngày T2..CN (nghìn đồng đã nhân sẵn). Ngày hôm nay được cộng dồn khi hoàn thành đơn.
  static List<int> dailyIncome() => [82000, 105000, 60000, 118000, 85000, 131000, 55000];
}
