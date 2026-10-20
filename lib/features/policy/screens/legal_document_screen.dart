import 'package:flutter/material.dart';

import '../../auth/theme/auth_theme.dart';

enum LegalDocument { terms, privacy }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final content = switch (document) {
      LegalDocument.terms => _termsContent,
      LegalDocument.privacy => _privacyContent,
    };
    return Scaffold(
      backgroundColor: AuthColors.background,
      appBar: AppBar(
        backgroundColor: AuthColors.background,
        foregroundColor: AuthColors.text,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(content.title),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(
              'Cập nhật ngày 20/10/2026',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AuthColors.secondary),
            ),
            const SizedBox(height: 12),
            Text(
              content.introduction,
              style: const TextStyle(fontSize: 15, height: 1.55),
            ),
            const SizedBox(height: 20),
            for (final section in content.sections) ...[
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section.body,
                style: const TextStyle(fontSize: 15, height: 1.55),
              ),
              const SizedBox(height: 18),
            ],
            const SizedBox(height: 4),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tôi đã hiểu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalContent {
  const _LegalContent({
    required this.title,
    required this.introduction,
    required this.sections,
  });

  final String title;
  final String introduction;
  final List<_LegalSection> sections;
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}

const _termsContent = _LegalContent(
  title: 'Điều khoản sử dụng',
  introduction: 'Khi tạo tài khoản REVO, bạn đồng ý cung cấp thông tin chính xác và sử dụng dịch vụ cứu hộ đúng mục đích.',
  sections: [
    _LegalSection(
      '1. Tài khoản và xác minh',
      'Bạn chịu trách nhiệm bảo vệ mật khẩu và cập nhật thông tin liên hệ. Tài khoản Thợ cứu hộ cần được quản trị viên duyệt trước khi nhận đơn.',
    ),
    _LegalSection(
      '2. Yêu cầu cứu hộ',
      'Khách hàng cần cung cấp vị trí, loại sự cố và thông tin phương tiện chính xác. Thợ cứu hộ chỉ sử dụng các thông tin này để tiếp nhận và thực hiện dịch vụ.',
    ),
    _LegalSection(
      '3. Giá và thanh toán',
      'Chi phí dự kiến được hiển thị trước khi xác nhận. Mọi điều chỉnh giá cần được thông báo và xác nhận trong ứng dụng trước khi hoàn tất dịch vụ.',
    ),
    _LegalSection(
      '4. An toàn và hành vi',
      'Không sử dụng REVO cho hành vi gian lận, quấy rối hoặc gây nguy hiểm. Trong tình huống khẩn cấp liên quan đến tính mạng, hãy liên hệ cơ quan chức năng.',
    ),
    _LegalSection(
      '5. Hỗ trợ',
      'Bạn có thể phản ánh đơn hàng hoặc yêu cầu hỗ trợ qua mục CSKH trong ứng dụng hoặc hotline 1130.',
    ),
  ],
);

const _privacyContent = _LegalContent(
  title: 'Chính sách quyền riêng tư',
  introduction: 'REVO xử lý dữ liệu cá nhân ở mức cần thiết để vận hành tài khoản, kết nối cứu hộ và bảo vệ người dùng.',
  sections: [
    _LegalSection(
      '1. Dữ liệu được thu thập',
      'Dữ liệu có thể gồm họ tên, email, số điện thoại, thông tin phương tiện, địa chỉ đã lưu, vị trí khi yêu cầu cứu hộ, nội dung chat và lịch sử đơn hàng.',
    ),
    _LegalSection(
      '2. Mục đích sử dụng',
      'Thông tin được dùng để xác thực tài khoản, tìm Thợ phù hợp, thực hiện đơn cứu hộ, hỗ trợ thanh toán, gửi thông báo và giải quyết khiếu nại.',
    ),
    _LegalSection(
      '3. Chia sẻ dữ liệu',
      'REVO chỉ chia sẻ dữ liệu cần thiết với bên tham gia đơn hàng và đơn vị hỗ trợ thanh toán hoặc vận hành hệ thống. Vị trí cứu hộ không được dùng để quảng cáo.',
    ),
    _LegalSection(
      '4. Lưu trữ và bảo vệ',
      'Dữ liệu được lưu trong thời gian cần thiết cho hoạt động dịch vụ, nghĩa vụ đối soát và xử lý tranh chấp. Quyền truy cập được giới hạn theo vai trò.',
    ),
    _LegalSection(
      '5. Quyền của bạn',
      'Bạn có thể xem, chỉnh sửa thông tin hồ sơ hoặc liên hệ REVO để yêu cầu hỗ trợ về dữ liệu cá nhân qua mục CSKH hay hotline 1130.',
    ),
  ],
);
