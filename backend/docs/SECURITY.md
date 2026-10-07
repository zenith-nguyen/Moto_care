# MotoCare Backend — bảo mật secret, API và webhook

Cập nhật: 2026-10-06. Tài liệu này áp dụng cho code dùng chung trong nhóm và bản demo công khai tạm thời.

## Ranh giới tin cậy

- Flutter chỉ giữ API base URL và JWT phiên đăng nhập. APK **không** chứa mật khẩu database, JWT signing secret, SMTP App Password, HMAC secret hay webhook secret.
- Secret chỉ nằm trong biến môi trường của backend. `.env`, file khóa, keystore và file upload runtime không được commit; CI chạy `npm run security:check-files` để chặn các file/pattern phổ biến bị đưa vào Git.
- Không gửi secret qua chat, issue, PR, ảnh chụp hoặc log. Nếu đã lộ, phải thu hồi/đổi secret; xóa tin nhắn hay commit không làm secret cũ an toàn trở lại.
- Mỗi môi trường dùng bộ secret riêng. Production/public phải có `JWT_SECRET`, `ORDER_START_HMAC_SECRET` và `PASSWORD_RESET_HMAC_SECRET` độc lập, ngẫu nhiên, tối thiểu 64 ký tự.

## Bảo vệ API hiện tại

- Mặc định endpoint cần JWT và role guard; chỉ Auth và Health public.
- DTO dùng whitelist và từ chối field thừa. Response lỗi có schema thống nhất, gắn `X-Request-ID`, không trả stack trace, SQL hay thông tin exception nội bộ.
- Access log dạng JSON chỉ ghi method, path không có query string, status, thời gian và request ID; không ghi body, Authorization, cookie, token hay email.
- Helmet thêm security headers và tắt `X-Powered-By`. CORS chỉ nhận danh sách origin HTTP(S) cụ thể; ký tự `*` bị từ chối.
- REST có rate limit mặc định 120 request/phút/client. Register 5, login/reset 10, forgot-password 3 và upload chat 20 request/phút. Đây là lớp bảo vệ demo trong một process, không thay WAF hay rate limiter phân tán.
- Chat chỉ nhận một JPEG/PNG/WebP thật tối đa 5 MiB; số part/field multipart cũng bị giới hạn. Ảnh nằm ngoài public web root và chỉ người tham gia đơn được tải bằng JWT.
- Socket.IO xác thực JWT và quyền theo order, không nhận token trong URL; handshake bị giới hạn kích thước và thời gian kết nối.

## Quy tắc cho webhook thanh toán thật (chưa triển khai)

Không mở webhook nhận tiền thật cho tới khi có tài liệu chính thức và credential sandbox/merchant. Khi triển khai phải đồng thời có:

1. Xác thực chữ ký/HMAC trên **raw request body** bằng secret server-side; so sánh constant-time.
2. Kiểm tra timestamp với cửa sổ ngắn và chống replay bằng event/transaction ID unique.
3. Idempotency: cùng một sự kiện gọi lại nhiều lần chỉ tạo một kết quả tài chính.
4. Đối chiếu order code, số tiền decimal, tài khoản nhận và trạng thái; không tin amount/status do Flutter gửi.
5. Ghi ledger trong transaction database; không sửa số dư bằng phép tính float và không cộng ví thợ trước khi order hoàn tất.
6. Chỉ log mã tham chiếu đã che bớt, không log raw payload, chữ ký, số tài khoản đầy đủ hay secret. IP allowlist chỉ là lớp phụ, không thay chữ ký.
7. Tách secret sandbox/production, có quy trình rotate và rollback; test duplicate, sai chữ ký, sai amount, replay và request đến sai thứ tự.

Hiện các endpoint `/payments/demo/...` chỉ mô phỏng nội bộ khi `DEMO_MODE=true`; tuyệt đối không giới thiệu là thanh toán hay hoàn tiền ngân hàng thật.

## Checklist cho thành viên

Trước commit chạy:

```powershell
npm run security:check-files
npm run lint
npm test
```

Nếu cần thêm biến bí mật, chỉ thêm **tên biến và placeholder** vào `.env.example`; gửi giá trị thật qua password manager/kênh bí mật phù hợp, không qua Git. Trước khi mở Tailscale Funnel, làm toàn bộ checklist trong [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md).
