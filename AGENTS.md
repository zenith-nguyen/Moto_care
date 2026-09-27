# Moto Care: hướng dẫn cho AI coding assistant

Đọc tệp này trước khi đề xuất hoặc thay đổi mã nguồn. Sau đó đọc `CONTRIBUTING.md` và tài liệu của nhánh đích:

- `docs/branches/cam-thu.md` khi PR có base là `cam-thu`.
- `docs/branches/thanh-vy.md` khi PR có base là `thanh-vy`.
- `docs/WORKFLOW.md` khi PR có base là `main`.

## Quy tắc bắt buộc

1. Không commit hoặc push trực tiếp vào `main`, `cam-thu`, hay `thanh-vy`. Tạo một nhánh công việc và mở PR vào nhánh tích hợp tương ứng.
2. Chỉ thay đổi phần cần thiết cho một yêu cầu. Không sửa định dạng hàng loạt, nâng dependency, hoặc sửa tệp nền tảng nếu yêu cầu không cần đến.
3. Không thêm khóa API, mật khẩu, tệp keystore, tệp `.env`, hay dữ liệu người dùng vào Git. Dùng GitHub Secrets cho bí mật CI/CD.
4. Mỗi thay đổi phải giữ `dart format`, `flutter analyze`, `flutter test`, và Android build chạy được. Không tắt lint hay test chỉ để workflow qua.
5. Cập nhật test khi thay đổi hành vi. Cập nhật tài liệu khi thay đổi quy trình, kiến trúc, cấu hình, hay cách phát hành.
6. Giữ `pubspec.lock` nhất quán khi thay đổi dependency. Không đổi `version:` trừ khi đang chuẩn bị phát hành trên `main`.

## Quy ước mã nguồn

- Đặt tên và cấu trúc theo Dart/Flutter idiomatic; ưu tiên widget nhỏ, có mục đích rõ ràng.
- Không trộn thay đổi UI, logic nghiệp vụ và dependency không liên quan trong một PR.
- Dùng commit Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
- PR cần mô tả mục tiêu, cách kiểm tra và ảnh chụp màn hình nếu thay đổi UI.

Khi thiếu ngữ cảnh, AI phải dừng ở phạm vi nhỏ nhất an toàn và nêu rõ giả định trong mô tả PR.
