import '../models/models.dart';
import '../models/payout_request.dart';

/// Toàn bộ dữ liệu mẫu của app (không gọi API).
class MockData {
  MockData._();

  static const quoteServices = [
    ('Thay ắc quy', 450000),
    ('Vá lốp', 80000),
    ('Công dịch vụ', 100000)
  ];

  static String get weekRange {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return '${monday.day}/${monday.month} – ${sunday.day}/${sunday.month}/${sunday.year}';
  }

  static const double weekRating = 4.9;
  static const String weekActiveHours = '~18 giờ';

  static const int weatherTemp = 32;
  static const String weatherTitle = '32°C · Nắng nóng';
  static const String weatherNote =
      'Dễ nổ lốp giữa trưa, đừng tắt nhận đơn nhé';

  static const String supportHotline = '1900 6868';

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

  static MechanicProfile profile() => MechanicProfile(
        name: 'Võ Thành Đạt',
        avatarAsset: 'assets/images/mechanic_vo_thanh_dat.png',
        verificationStatus: VerificationStatus.verified,
        specialty: 'Sửa chữa xe máy tại chỗ',
        bio:
            'Thợ cứu hộ xe máy khu vực Quận 10, 3 năm kinh nghiệm sửa xe số và xe tay ga.',
        tierName: 'Bạc',
        nextTierName: 'Vàng',
        tierOrders: 18,
        nextTierTarget: 24,
        experienceYears: 3,
        radiusKm: 5,
        rating: 4.9,
        ratingCount: 132,
        area: 'Quận 1, TP.HCM',
        skills: [
          Skill(name: 'Vá xe, thay lốp', status: VerificationStatus.verified),
          Skill(
              name: 'Kích bình, câu điện', status: VerificationStatus.pending),
          Skill(name: 'Cẩu kéo xe', status: VerificationStatus.rejected),
        ],
        documents: const [
          VerificationDoc(name: 'CCCD', status: VerificationStatus.verified),
          VerificationDoc(
              name: 'Chứng chỉ nghề', status: VerificationStatus.pending),
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
      code: '#RVO2341',
      issue: 'Hết bình',
      description:
          '"Xe không đề được, cần hỗ trợ kích bình. Em đang đứng bên lề đường."',
      vehicle: 'Honda Vision',
      plate: '59-X1 123.45',
      customerName: 'Thùy An',
      customerPhone: '0905551298',
      customerEmail: 'thuyan@example.test',
      address: '144 Nguyễn Thị Minh Khai, Quận 1, TP.HCM',
      distanceKm: 1.8,
      etaMinutes: 4,
      price: 150000,
      platformFee: 0,
    ),
    OrderOffer(
      code: '#RVO2342',
      issue: 'Xẹp lốp',
      description:
          '"Lốp sau bị xẹp hơi, em dắt xe vào lề đường trước cổng bệnh viện."',
      vehicle: 'Yamaha Exciter 155',
      plate: '59-P2 456.78',
      customerName: 'Lê Thị Hạnh',
      customerPhone: '0912345678',
      customerEmail: 'hanh@example.test',
      address: '56 Nguyễn Tri Phương, P.4, Q.10',
      distanceKm: 2.1,
      etaMinutes: 9,
      price: 120000,
      platformFee: 8000,
    ),
  ];

  /// Hội thoại mẫu theo ảnh C9; messages luôn thuộc cùng đơn hiện tại.
  static List<ChatMessage> openingChat(DateTime acceptedAt) => [
        ChatMessage(
            fromMechanic: false,
            time: acceptedAt,
            text: 'Bạn sắp tới nơi chưa ạ?'),
        ChatMessage(
            fromMechanic: true,
            time: acceptedAt,
            text: 'Mình đang trên đường, khoảng 5 phút nữa.',
            status: MessageStatus.seen),
        ChatMessage(
            fromMechanic: false,
            time: acceptedAt,
            text: 'Dạ em chờ ạ, cảm ơn anh!'),
      ];

  static DateTime _at(int daysAgo, int h, int m) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - daysAgo, h, m);
  }

  static List<TimelineEvent> _timeline(DateTime done,
          {bool cancelled = false}) =>
      cancelled
          ? [
              TimelineEvent(
                  'Đã nhận đơn', done.subtract(const Duration(minutes: 12))),
              TimelineEvent('Đơn bị hủy', done),
            ]
          : [
              TimelineEvent(
                  'Đã nhận đơn', done.subtract(const Duration(minutes: 41))),
              TimelineEvent(
                  'Đã đến nơi', done.subtract(const Duration(minutes: 33))),
              TimelineEvent(
                  'Bắt đầu sửa', done.subtract(const Duration(minutes: 31))),
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

  static OrderHistoryItem _cancelled(
      String code, String issue, int daysAgo, int h, int m) {
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
        _done('#RVO2298', 'Xẹp lốp', 1, 14, 2, 120000, 8000,
            customerRating: 5,
            customerReview: 'Thợ tới nhanh, nhiệt tình, giá hợp lý!'),
        _done('#RVO2287', 'Chết máy', 2, 9, 40, 150000, 9000,
            vehicle: 'Toyota Vios',
            customer: 'Lê Minh Quân',
            phone: '0900000013',
            customerRating: 5,
            customerReview: 'Làm việc gọn gàng.'),
        _cancelled('#RVO2279', 'Hết xăng', 3, 19, 21),
        _cancelled('#RVO2271', 'Xẹp lốp', 4, 8, 5),
      ];

  /// Showcase-only orders: five different services, kept apart from the real
  /// history and wallet. Amounts follow the demo price table used by
  /// AppState.nextOffer (tyre fee 8.000đ, the others 0đ); nothing here is ever
  /// credited to the wallet.
  static List<OrderHistoryItem> showcaseOrders() => [
        _done('#DEMO-S001', 'Xẹp lốp', 1, 10, 20, 120000, 8000,
            vehicle: 'Yamaha Exciter 155',
            plate: '59-P2 456.78',
            customer: 'Lê Thị Hạnh',
            phone: '0912345678',
            address: '56 Nguyễn Tri Phương, P.4, Q.10'),
        _done('#DEMO-S002', 'Kích bình', 2, 16, 35, 150000, 0,
            vehicle: 'Toyota Vios',
            plate: '51K-123.45',
            customer: 'Thùy An',
            phone: '0905551298',
            address: '144 Nguyễn Thị Minh Khai, Quận 1, TP.HCM'),
        _cancelled('#DEMO-S003', 'Hết xăng', 3, 19, 21),
        _done('#DEMO-S004', 'Kéo xe', 4, 9, 18, 500000, 0,
            vehicle: 'Toyota Camry',
            plate: '51H-678.90',
            address: 'Quận 7, TP.HCM'),
        _done('#DEMO-S005', 'Ngập nước', 5, 14, 5, 350000, 0,
            vehicle: 'Toyota Hilux',
            plate: '51D-246.80',
            address: 'Quận 2, TP.HCM'),
      ];

  /// Demo-only payout requests (no Admin backend yet). Linked to a real
  /// history order and its recorded credit (#RVO2298 -> 112.000đ); creating one
  /// never touches the wallet balance or the ledger.
  static List<PayoutRequest> payoutRequests() => [
        PayoutRequest(
          id: '#PO0001',
          orderCode: '#RVO2298',
          amount: 112000,
          serviceName: 'Xẹp lốp',
          status: PayoutStatus.processing,
          receivedAt: _at(0, 10, 12),
          processingAt: _at(0, 10, 18),
        ),
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
          code: '#RVO2298',
          txnId: 'TX-88041',
          type: TxType.credit,
          amount: 112000,
          time: _at(1, 14, 10),
          orderCode: '#RVO2298',
          serviceName: 'Xẹp lốp',
          customerName: 'Trần Văn Khách',
          customerPhone: '0900000012',
          finalPrice: 120000,
          platformFee: 8000,
        ),
        WalletTransaction(
          code: '#RVO2287',
          txnId: 'TX-87960',
          type: TxType.credit,
          amount: 141000,
          time: _at(2, 9, 48),
          orderCode: '#RVO2287',
          serviceName: 'Chết máy',
          customerName: 'Lê Minh Quân',
          customerPhone: '0900000013',
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
  static List<int> dailyIncome() {
    final values = [82000, 105000, 60000, 118000, 85000, 131000, 55000];
    values[DateTime.now().weekday - 1] = 1250000;
    return values;
  }
}
