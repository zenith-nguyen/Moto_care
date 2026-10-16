import '../models/admin_models.dart';

/// Explicit, session-only fixtures. Every financial identifier is sandbox data.
abstract final class AdminMockData {
  // Synthetic contact numbers for the session-only sandbox records.
  static const _mechanicPhones = {
    'Trần Quốc Huy': '0900 000 101',
    'Lê Văn Phúc': '0900 000 102',
    'Nguyễn Đức Tín': '0900 000 103',
  };

  static List<AdminOrder> orders(DateTime now) {
    final templates = [
      (
        'MC-2601',
        'Nguyễn Minh Anh',
        'Thủng lốp',
        'Trần Quốc Huy',
        180000,
        AdminOrderStatus.completed,
        AdminPaymentStatus.settled,
        180000,
        0,
        180000,
        null,
      ),
      (
        'MC-2602',
        'Lê Hoàng Nam',
        'Hết bình điện',
        'Lê Văn Phúc',
        240000,
        AdminOrderStatus.working,
        AdminPaymentStatus.held,
        240000,
        0,
        0,
        null,
      ),
      (
        'MC-2603',
        'Phạm Thanh Hà',
        'Xe không khởi động',
        null,
        150000,
        AdminOrderStatus.searching,
        AdminPaymentStatus.unpaid,
        0,
        0,
        0,
        null,
      ),
      (
        'MC-2604',
        'Trần Bảo Ngọc',
        'Kéo xe',
        'Trần Quốc Huy',
        350000,
        AdminOrderStatus.assigned,
        AdminPaymentStatus.held,
        350000,
        0,
        0,
        'Giá thợ đề xuất đang có tranh chấp',
      ),
      (
        'MC-2605',
        'Đỗ Đức Long',
        'Thủng lốp',
        'Lê Văn Phúc',
        160000,
        AdminOrderStatus.cancelled,
        AdminPaymentStatus.refunded,
        160000,
        160000,
        0,
        null,
      ),
      (
        'MC-2606',
        'Vũ Mai Chi',
        'Hết xăng',
        'Nguyễn Đức Tín',
        120000,
        AdminOrderStatus.completed,
        AdminPaymentStatus.settled,
        120000,
        0,
        100000,
        'Thiếu 20.000 đ quyết toán ví thợ',
      ),
      (
        'MC-2607',
        'Bùi Gia Hân',
        'Xe ngập nước',
        'Nguyễn Đức Tín',
        300000,
        AdminOrderStatus.working,
        AdminPaymentStatus.held,
        300000,
        0,
        0,
        'Cần đối chiếu phụ phí và hệ số thời tiết',
      ),
      (
        'MC-2608',
        'Lý Hải Yến',
        'Hết bình điện',
        null,
        200000,
        AdminOrderStatus.cancelled,
        AdminPaymentStatus.unpaid,
        0,
        0,
        0,
        null,
      ),
    ];
    return List.unmodifiable(
      List.generate(templates.length, (index) {
        final t = templates[index];
        final created = now.subtract(
          Duration(days: index ~/ 2, hours: index + 1),
        );
        final weather = index == 6 ? 1.2 : 1.0;
        final travel = index == 6 ? 60000 : 40000;
        final service = index == 6 ? 200000 : t.$5 - travel;
        return AdminOrder(
          id: t.$1,
          customer: t.$2,
          incident: t.$3,
          provider: t.$4,
          estimatedPrice: t.$5,
          finalPrice:
              t.$6 == AdminOrderStatus.completed ||
                  t.$6 == AdminOrderStatus.cancelled
              ? t.$5
              : null,
          status: t.$6,
          payment: t.$7,
          createdAt: created,
          collected: t.$8,
          refunded: t.$9,
          credited: t.$10,
          warning: t.$11,
          paymentId: t.$8 == 0 ? null : 'SB-PAY-${2601 + index}',
          weatherFactor: weather,
          servicePrice: service,
          travelPrice: travel,
          providerPosition: t.$4 == null ? null : (10.7810, 106.6950),
          locationUpdatedAt: t.$4 == null
              ? null
              : created.add(const Duration(minutes: 10)),
          address: '${12 + index} Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
          customerPhone: '0900 100 ${201 + index}',
          providerPhone: _mechanicPhones[t.$4],
          timeline: List.unmodifiable([
            AdminTimelineEvent(
              'Đã tạo yêu cầu',
              created,
              milestone: AdminOrderMilestone.created,
            ),
            if (t.$4 != null)
              AdminTimelineEvent(
                'Thợ nhận đơn',
                created.add(const Duration(minutes: 3)),
                milestone: AdminOrderMilestone.accepted,
              ),
            if (t.$6 == AdminOrderStatus.working ||
                t.$6 == AdminOrderStatus.completed)
              AdminTimelineEvent(
                'Bắt đầu cứu hộ',
                created.add(const Duration(minutes: 12)),
                milestone: AdminOrderMilestone.started,
              ),
            if (t.$6 == AdminOrderStatus.completed)
              AdminTimelineEvent(
                'Hoàn thành',
                created.add(const Duration(minutes: 35)),
                milestone: AdminOrderMilestone.completed,
              ),
            if (t.$6 == AdminOrderStatus.cancelled)
              AdminTimelineEvent(
                'Đã hủy theo yêu cầu khách',
                created.add(const Duration(minutes: 8)),
              ),
          ]),
          offers: List.unmodifiable([
            if (t.$4 != null) AdminOffer(t.$4!, t.$5, 'Đã chọn'),
            AdminOffer('Võ Thành Đạt', t.$5 + 20000, 'Chưa chọn'),
          ]),
          payments: List.unmodifiable([
            if (t.$8 > 0)
              AdminPaymentEvent(
                'SB-PAY-${2601 + index}',
                'Khách chuyển',
                t.$8,
                created.add(const Duration(minutes: 1)),
              ),
            if (t.$9 > 0)
              AdminPaymentEvent(
                'SB-RF-${2601 + index}',
                'Hoàn tiền khách',
                t.$9,
                created.add(const Duration(minutes: 10)),
              ),
            if (t.$10 > 0)
              AdminPaymentEvent(
                'SB-WAL-${2601 + index}',
                'Quyết toán ví thợ',
                t.$10,
                created.add(const Duration(minutes: 36)),
              ),
          ]),
          chat: List.unmodifiable([
            if (t.$4 != null) ...[
              AdminChatMessage(
                t.$2,
                'Tôi đang đứng trước cửa hàng tại địa chỉ đã gửi.',
                created.add(const Duration(minutes: 4)),
              ),
              AdminChatMessage(
                t.$4!,
                'Tôi đã nhận vị trí và đang di chuyển đến.',
                created.add(const Duration(minutes: 5)),
              ),
            ],
          ]),
          dispute: index == 3 || index == 6
              ? 'Thợ đề xuất bổ sung phí vật tư. Khách yêu cầu giải thích trước khi chấp nhận.'
              : null,
        );
      }),
    );
  }

  static List<AdminProviderApplication> providers(DateTime now) => [
    AdminProviderApplication(
      id: 'P-101',
      name: 'Võ Thành Đạt',
      email: 'dat@example.test',
      phone: '0900 000 101',
      vehicle: 'Honda Wave • Bộ dụng cụ cứu hộ',
      plate: '59-X1 101.01',
      registeredAt: now.subtract(const Duration(hours: 5)),
    ),
    AdminProviderApplication(
      id: 'P-102',
      name: 'Phan Minh Khoa',
      email: 'khoa@example.test',
      phone: '0900 000 102',
      vehicle: 'Yamaha Sirius • Bình kích điện',
      plate: '59-X2 102.02',
      registeredAt: now.subtract(const Duration(days: 1)),
    ),
    AdminProviderApplication(
      id: 'P-103',
      name: 'Ngô Hữu An',
      email: 'an@example.test',
      phone: '0900 000 103',
      vehicle: 'Honda Future • Xe kéo chuyên dụng',
      plate: '59-X3 103.03',
      registeredAt: now.subtract(const Duration(days: 2)),
    ),
  ];

  static const refunds = [
    AdminRefund(
      id: 'RF-01',
      orderId: 'MC-2604',
      customer: 'Trần Bảo Ngọc',
      amount: 50000,
      reason: 'Điều chỉnh phí di chuyển',
      sandboxTransaction: 'SB-RF-01',
      source: 'refund',
    ),
    AdminRefund(
      id: 'RF-02',
      orderId: 'MC-2607',
      customer: 'Bùi Gia Hân',
      amount: 30000,
      reason: 'Đối chiếu phụ phí thời tiết',
      sandboxTransaction: 'SB-RF-02',
      source: 'refund',
    ),
    AdminRefund(
      id: 'ADJ-01',
      orderId: 'MC-2606',
      customer: 'Vũ Mai Chi',
      amount: 20000,
      reason: 'Hoàn chênh lệch sau điều chỉnh thanh toán',
      sandboxTransaction: 'SB-ADJ-01',
      source: 'payment-adjustment',
    ),
  ];

  static const disputes = [
    AdminPriceDispute(
      id: 'DP-01',
      orderId: 'MC-2604',
      originalPrice: 350000,
      proposedPrice: 420000,
      providerReason: 'Cần kéo xe thêm 3 km.',
      customerReply: 'Tôi cần xác nhận quãng đường tính thêm.',
    ),
    AdminPriceDispute(
      id: 'DP-02',
      orderId: 'MC-2607',
      originalPrice: 300000,
      proposedPrice: 280000,
      providerReason: 'Không cần thay phụ tùng như dự tính.',
      customerReply: 'Đồng ý giảm giá, vui lòng đối chiếu phần đã thanh toán.',
    ),
  ];

  static List<AdminWithdrawal> withdrawals(DateTime now) => [
    AdminWithdrawal(
      id: 'WD-01',
      providerId: 'P-01',
      providerName: 'Trần Quốc Huy',
      amount: 200000,
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    AdminWithdrawal(
      id: 'WD-02',
      providerId: 'P-02',
      providerName: 'Lê Văn Phúc',
      amount: 150000,
      createdAt: now.subtract(const Duration(hours: 6)),
    ),
  ];

  static List<AdminWallet> wallets(DateTime now) => [
    AdminWallet(
      providerId: 'P-01',
      available: 480000,
      locked: 200000,
      history: [
        AdminWalletEntry(
          'SB-WAL-OPEN-01',
          'Số dư mở đầu phiên sandbox',
          500000,
          now.subtract(const Duration(days: 7)),
        ),
        AdminWalletEntry(
          'SB-WAL-2601',
          'Quyết toán MC-2601',
          180000,
          now.subtract(const Duration(hours: 1)),
        ),
        AdminWalletEntry(
          'SB-LOCK-01',
          'Khóa chờ rút WD-01',
          -200000,
          now.subtract(const Duration(hours: 2)),
        ),
      ],
    ),
    AdminWallet(
      providerId: 'P-02',
      available: 350000,
      locked: 150000,
      history: [
        AdminWalletEntry(
          'SB-WAL-OPEN-02',
          'Số dư mở đầu phiên sandbox',
          500000,
          now.subtract(const Duration(days: 7)),
        ),
        AdminWalletEntry(
          'SB-LOCK-02',
          'Khóa chờ rút WD-02',
          -150000,
          now.subtract(const Duration(hours: 6)),
        ),
      ],
    ),
  ];
}
