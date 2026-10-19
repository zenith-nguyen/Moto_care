import 'package:motocare_mechanic/models/models.dart';

/// UI-only visual fixture from the user's six-card reference. Never imported
/// by lib/, never dispatched as actual order/approval/Wallet events.
List<RevoNotification> notificationVisualReference(DateTime now) {
  final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
  return [
    RevoNotification(
        'Đơn cứu hộ khẩn cấp mới', 'Đơn #RVO3291 · Hết bình · Quận 1, TP.HCM',
        id: 'visual-emergency',
        type: RevoNotificationType.emergency,
        orderRelated: true,
        orderId: '#RVO3291',
        time: now.subtract(const Duration(minutes: 2)),
        detail: 'Vui lòng xác nhận trong 3 phút.'),
    RevoNotification(
        'Khách hàng gửi tin nhắn', 'Thùy An vừa nhắn về đơn #RVO3281',
        id: 'visual-chat',
        type: RevoNotificationType.message,
        orderRelated: true,
        orderId: '#RVO3281',
        time: now.subtract(const Duration(minutes: 8)),
        detail: '"Anh đến chưa ạ?"'),
    RevoNotification('Khách đã duyệt báo giá', 'Đơn #RVO3281 · Honda Vision',
        id: 'visual-quote',
        type: RevoNotificationType.quoteApproved,
        orderRelated: true,
        orderId: '#RVO3281',
        time: DateTime(now.year, now.month, now.day - 1, 16, 20),
        isRead: true,
        detail: 'Bạn có thể tiếp tục sửa chữa.'),
    RevoNotification('Thu nhập đã cộng vào Ví', '+150.000đ từ đơn #RVO3276',
        id: 'visual-income',
        type: RevoNotificationType.income,
        orderRelated: false,
        orderId: '#RVO3276',
        time: DateTime(now.year, now.month, now.day - 1, 9, 15),
        isRead: true,
        detail: 'Số dư ví đã được cập nhật.'),
    RevoNotification('Chứng chỉ nghề đã được xác minh',
        'Hồ sơ kỹ thuật viên của bạn đã được cập nhật.',
        id: 'visual-certificate',
        type: RevoNotificationType.certificate,
        orderRelated: false,
        time: DateTime(monday.year, monday.month, monday.day - 4, 14, 10),
        isRead: true,
        detail: 'Bạn có thể nhận thêm dịch vụ mới.'),
    RevoNotification(
        'Bạn nhận được đánh giá 5 sao', 'Khách Minh Tuấn đánh giá đơn #RVO3262',
        id: 'visual-review',
        type: RevoNotificationType.review,
        orderRelated: true,
        orderId: '#RVO3262',
        time: DateTime(monday.year, monday.month, monday.day - 6, 18, 40),
        isRead: true,
        detail: '"Làm việc nhanh, hỗ trợ rất nhiệt tình."'),
  ];
}
