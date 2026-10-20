import '../data/home_catalog.dart' show homeSearchKey;

enum SupportActionKind { openPaymentGuide, openWallet, openFaq, contactAdmin }

class SupportAction {
  const SupportAction(this.label, this.kind);
  final String label;
  final SupportActionKind kind;
}

class AssistantReply {
  const AssistantReply(this.text, {this.actions = const []});
  final String text;
  final List<SupportAction> actions;
}

/// Where the assistant's answers come from. A real implementation must call
/// the REVO backend (which talks to the AI provider); no key lives in the app.
abstract class SupportAssistant {
  /// True only for an implementation backed by a live service.
  bool get isLive;
  Future<List<AssistantReply>> reply(String message);
}

/// FAQ content shared by the support centre and the demo assistant.
class SupportFaq {
  SupportFaq._();
  static const orders = [
    (
      'Khách chưa cung cấp mã xác nhận?',
      'Nhắn tin hoặc liên hệ khách từ màn hình đơn hàng. Chỉ bắt đầu sửa khi đã xác nhận đúng mã.'
    ),
    (
      'Khi nào được sửa hạng mục phát sinh?',
      'Gửi báo giá và chờ khách đồng ý trước khi thực hiện công việc bổ sung.'
    ),
    (
      'Làm sao liên hệ hỗ trợ nhanh?',
      'Chọn "Nhắn Trợ lý REVO" ở cuối màn hình này. Kênh liên hệ Admin hiện chưa được kết nối trong bản trình diễn.'
    ),
  ];
  static const payments = [
    (
      'Thu nhập được tính như thế nào?',
      'Thu nhập bằng giá khách đã duyệt trừ chiết khấu hiển thị trong chi tiết đơn hàng.'
    ),
    (
      'Rút tiền mất bao lâu?',
      'Yêu cầu được ghi nhận trong lịch sử giao dịch. Luồng hiện tại mô phỏng, chưa chuyển tiền thật.'
    ),
  ];
}

/// Offline demo assistant: keyword-matched, fixed answers. It is NOT an AI and
/// never reads user data; [isLive] is false so the UI says so.
class MockSupportAssistant implements SupportAssistant {
  MockSupportAssistant({this.delay = const Duration(milliseconds: 700)});
  final Duration delay;

  @override
  bool get isLive => false;

  @override
  Future<List<AssistantReply>> reply(String message) async {
    await Future<void>.delayed(delay);
    final k = homeSearchKey(message);
    bool has(String s) => k.contains(s);
    if (has('cam on')) {
      return const [
        AssistantReply('Rất vui được hỗ trợ anh.'),
        AssistantReply('Vẫn chưa nhận được tiền sau 24 giờ?', actions: [
          SupportAction('Gặp Admin', SupportActionKind.contactAdmin)
        ]),
      ];
    }
    if (has('chua nhan') && (has('tien') || has('thanh toan'))) {
      return const [
        AssistantReply(
            'Anh kiểm tra trạng thái đề nghị chi trả trong mục **Ví** hoặc **Theo dõi thanh toán**.\n'
            'Nếu đề nghị đang ở trạng thái "Đang xử lý", khoản tiền chưa được xác nhận là đã chi trả. Admin sẽ kiểm tra và xử lý theo quy trình hiện hành.',
            actions: [
              SupportAction('Xem hướng dẫn thanh toán',
                  SupportActionKind.openPaymentGuide)
            ]),
      ];
    }
    if (has('de nghi chi tra') || has('gui de nghi')) {
      return const [
        AssistantReply(
            'Anh làm theo 3 bước:\n'
            '1. Vào mục **Ví Thợ**\n'
            '2. Chọn **Gửi đề nghị chi trả**\n'
            '3. Nhập số tiền và gửi yêu cầu\n'
            'Sau khi gửi, Admin sẽ kiểm tra và xử lý. Anh có thể theo dõi trạng thái trong mục **Theo dõi thanh toán**.',
            actions: [
              SupportAction('Mở Ví Thợ', SupportActionKind.openWallet)
            ]),
      ];
    }
    if (has('otp') || has('ma xac nhan')) {
      return [
        AssistantReply(
            '${SupportFaq.orders[0].$2}\nKhông chia sẻ mã OTP trong cuộc trò chuyện này.'),
      ];
    }
    if (has('phat sinh')) {
      return [AssistantReply(SupportFaq.orders[1].$2)];
    }
    if (has('rut tien')) {
      return [AssistantReply(SupportFaq.payments[1].$2)];
    }
    if (has('thu nhap')) {
      return [AssistantReply(SupportFaq.payments[0].$2)];
    }
    if (has('admin') || has('nguoi that')) {
      return const [
        AssistantReply(
            'Kênh liên hệ Admin hiện chưa được kết nối trong bản trình diễn.',
            actions: [
              SupportAction('Gặp Admin', SupportActionKind.contactAdmin)
            ]),
      ];
    }
    if (has('don hang')) {
      return const [
        AssistantReply(
            'Anh có thể xem các câu hỏi thường gặp về đơn hàng: mã xác nhận, hạng mục phát sinh và cách liên hệ hỗ trợ.',
            actions: [
              SupportAction('Xem câu hỏi thường gặp', SupportActionKind.openFaq)
            ]),
      ];
    }
    return const [
      AssistantReply(
          'Mình chưa có câu trả lời mẫu cho nội dung này. Anh thử chọn một chủ đề bên dưới hoặc xem câu hỏi thường gặp.',
          actions: [
            SupportAction('Xem câu hỏi thường gặp', SupportActionKind.openFaq)
          ]),
    ];
  }
}
