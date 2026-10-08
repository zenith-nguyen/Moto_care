import '../models/chat_conversation.dart';
import '../models/admin_message.dart';

const mockRescueConversations = [
  ChatConversation(
    mechanicName: 'Nguyễn Minh Tuấn',
    avatarInitials: 'MT',
    licensePlate: '59-X1 123.45',
    phoneNumber: '0900000001',
    status: RescueStatus.arriving,
    lastMessage: 'Mình sắp đến rồi. Bạn chờ ở vị trí đã ghim nhé!',
    timeLabel: '14:32',
  ),
  ChatConversation(
    mechanicName: 'Trần Quốc Bảo',
    avatarInitials: 'QB',
    licensePlate: '59-X1 123.45',
    phoneNumber: '0900000002',
    status: RescueStatus.completed,
    lastMessage: 'Xe đã được sửa xong. Cảm ơn bạn đã chọn MotoCare!',
    timeLabel: 'Hôm qua',
  ),
  ChatConversation(
    mechanicName: 'Lê Hoàng Nam',
    avatarInitials: 'HN',
    licensePlate: '51-F2 678.90',
    phoneNumber: '0900000003',
    status: RescueStatus.completed,
    lastMessage: 'Bạn nhớ kiểm tra áp suất lốp trước chuyến đi nhé.',
    timeLabel: '28/09',
  ),
  ChatConversation(
    mechanicName: 'Phạm Đức Huy',
    avatarInitials: 'DH',
    licensePlate: '51-F2 678.90',
    phoneNumber: '0900000004',
    status: RescueStatus.completed,
    lastMessage: 'Mình đã gửi thông tin bảo hành cho bạn rồi nhé.',
    timeLabel: '25/09',
  ),
];

const demoSupportMessages = [
  AdminMessage(
    title: 'CSKH MotoCare',
    message: 'Xin chào! MotoCare có thể giúp gì cho bạn hôm nay?',
    time: '09:00',
  ),
  AdminMessage(
    title: 'Hỗ trợ đơn cứu hộ',
    message: 'Nếu cần hỗ trợ về đơn cứu hộ, hãy gửi mã đơn cho đội ngũ CSKH.',
    time: 'Hôm qua',
  ),
];

const demoAdminNotifications = [
  AdminMessage(
    title: 'Chào mừng đến với MotoCare',
    message: 'Đội ngũ MotoCare luôn sẵn sàng đồng hành và hỗ trợ bạn trên mọi hành trình.',
    time: '08:30',
  ),
  AdminMessage(
    title: 'Đơn cứu hộ đã hoàn tất',
    message: 'Cảm ơn bạn đã sử dụng dịch vụ. Hãy đánh giá trải nghiệm để MotoCare phục vụ tốt hơn.',
    time: 'Hôm qua',
  ),
  AdminMessage(
    title: 'Nhắc nhở bảo dưỡng xe',
    message:
        'Kiểm tra lốp, phanh và dầu máy định kỳ để chuyến đi luôn an toàn.',
    time: '28/09',
  ),
];

const chatQuickReplies = [
  'Tôi đang ở đúng vị trí ghim',
  'Anh đến đâu rồi?',
  'Xe tôi bị thủng lốp / không nổ máy',
];
