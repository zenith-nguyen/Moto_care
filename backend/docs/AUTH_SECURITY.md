# MotoCare — đăng nhập và khôi phục mật khẩu

Cập nhật: 2026-10-06. Tài liệu này mô tả hợp đồng backend cho bản demo; không chứa mật khẩu hoặc SMTP secret.

## Luồng đăng nhập

- `POST /auth/login` nhận email hoặc số điện thoại trong `identity` và mật khẩu.
- Năm lần sai liên tiếp khóa tạm tài khoản 15 phút. Đăng nhập đúng xóa bộ đếm sai.
- JWT chứa `authVersion`. REST và Socket.IO đều đối chiếu phiên bản này với user trong database.
- Khi đặt lại mật khẩu thành công, backend tăng `authVersion`; mọi JWT cũ bị từ chối ngay ở request/kết nối tiếp theo.

## Luồng quên mật khẩu

1. Client gọi `POST /auth/password/forgot` với email.
2. Backend luôn trả HTTP 202 và cùng một thông báo, dù email tồn tại hay không.
3. Với email hợp lệ, backend tạo mã ngẫu nhiên sáu số, chỉ lưu HMAC của mã và gửi mã qua SMTP.
4. Mã hết hạn sau 10 phút, chỉ dùng một lần, tối đa năm lần nhập sai và có khoảng chờ gửi lại 60 giây.
5. Client gọi `POST /auth/password/reset` với email, mã và mật khẩu mới dài 8–72 ký tự.
6. Backend băm mật khẩu mới bằng Argon2, vô hiệu mã còn lại, mở khóa tài khoản và vô hiệu JWT cũ.

Không log hoặc trả mã qua API. Khi `EMAIL_ENABLED=false` hoặc gửi email thất bại, mã vừa tạo bị vô hiệu và response vẫn trung tính. Tài khoản chỉ có số điện thoại chưa dùng được luồng email này.

## Cấu hình Gmail demo

1. Dùng một tài khoản Gmail riêng cho demo và bật xác minh hai bước.
2. Tạo Google App Password cho ứng dụng mail.
3. Chỉ ghi các biến sau vào `backend/.env` cục bộ:

```dotenv
EMAIL_ENABLED=true
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=demo-account@example.com
SMTP_PASSWORD=<google-app-password>
SMTP_FROM=MotoCare <demo-account@example.com>
```

Không commit `.env`, không gửi App Password qua chat và không chụp màn hình có secret. Nếu secret từng lộ, thu hồi App Password cũ và tạo cái mới.

## Hợp đồng UI

- Sau `forgot`, luôn hiển thị thông báo trung tính; không phân biệt email đã đăng ký.
- Màn nhập mã cần cho phép gửi lại sau 60 giây, nhưng không tự gửi request liên tục.
- Khi reset thành công, xóa JWT khỏi secure storage và điều hướng về đăng nhập.
- HTTP 400 ở bước reset nghĩa là mã sai, hết hạn, đã dùng hoặc đã quá số lần thử; không cần phân biệt chi tiết trên UI.
- HTTP 401 khi đang dùng app có thể do JWT cũ bị vô hiệu sau reset; xóa phiên và đăng nhập lại.
