import '../models/admin_account_models.dart';
import '../models/admin_models.dart';

abstract final class AdminAccountData {
  static const version = 'Phiên bản Revo Admin v1.0.2 (Build 2026)';

  static AdminAccountState initial(AdminSession? session, DateTime now) =>
      AdminAccountState(
        profile: AdminAccountProfile(
          name: session?.name ?? '',
          email: session?.email ?? '',
        ),
        settings: const AdminOperatingSettings(),
        staff: session?.isAdmin == true
            ? const [
                AdminStaffMember(
                  id: 'STAFF-01',
                  name: 'Điều phối ca sáng',
                  email: 'morning@example.test',
                  role: AdminStaffRole.admin,
                ),
                AdminStaffMember(
                  id: 'STAFF-02',
                  name: 'Điều phối ca tối',
                  email: 'evening@example.test',
                  onDuty: false,
                ),
              ]
            : const [],
        logins: session?.isAdmin == true
            ? [
                AdminLoginEntry(
                  device: 'Phiên quản trị hiện tại',
                  description: 'Đăng nhập bằng tài khoản ${session!.email}',
                  at: now,
                  current: true,
                ),
              ]
            : const [],
      );

  static const guide = [
    (
      'Theo dõi vận hành',
      'Mở Tổng quan để xem ca cứu hộ và dòng tiền. Chọn khoảng ngày để đối chiếu xu hướng; các hàng chờ luôn phản ánh yêu cầu hiện tại.',
    ),
    (
      'Duyệt hồ sơ thợ',
      'Mở Duyệt thợ, chọn Chi tiết và kiểm tra thông tin. Khi từ chối, nhập lý do. Xem lại nội dung trước khi xác nhận.',
    ),
    (
      'Đối soát và duyệt tiền',
      'Kiểm tra trạng thái thu, hoàn và cộng ví tại Tài chính. Trong Xử lý yêu cầu, đối chiếu lịch sử ví trước khi duyệt rút tiền. Yêu cầu hoàn tiền hiện có thể xem và đối chiếu.',
    ),
    (
      'Cấu hình vận hành',
      'Cập nhật phí, hệ số thời tiết và SOS tại Tài khoản Quản trị. Cấu hình mới không thay đổi giá đã ghi nhận trên các đơn cũ.',
    ),
    (
      'Bảo mật tài khoản',
      'Không chia sẻ tài khoản hoặc mật khẩu. Kiểm tra Nhật ký thao tác và Lịch sử đăng nhập; chỉ cấp quyền cần thiết cho mỗi ca trực.',
    ),
  ];
}
