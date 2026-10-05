# MotoCare Backend — Trạng thái hiện tại

Cập nhật lần cuối: 2026-10-05

## Đã xong

- Prompt A: NestJS, Auth JWT/argon2, RolesGuard, Swagger, health; migration PostGIS và users. Đã thử đăng ký, đăng nhập, `/users/me`.
- Prompt B: 11 bảng lõi (users, providers, incident_types, orders, order_offers, messages, reviews, payments, wallets, wallet_transactions, withdrawal_requests); migration, seed local, index GiST, tiền `numeric`, test truy vấn `ST_DWithin`.
- Prompt C (đã merge PR #5): loại sự cố, GPS/online của thợ, tạo đơn, matching PostGIS, accept/reject, offer 15 giây, job hết hạn 5 giây, retry, REST polling, khóa dòng + unique index chống nhận trùng. CI/lint/test đã xanh khi merge.
- PR #7 đã merge vào `main`: API admin duyệt thợ; demo trả trước/hoàn 100% giả lập; hủy trước khi bắt đầu; chat lưu DB; Socket.IO offer/trạng thái/GPS/chat; tới nơi/mã bắt đầu/hoàn tất đúng giá gốc; ví demo và đánh giá hai chiều; `/health/ready` kiểm tra DB; hướng dẫn demo một laptop. Migration local đã chạy đủ 6 bản; Docker/PostGIS và readiness đã kiểm tra OK ngày 2026-10-05. Đây vẫn là sandbox, không phải thanh toán thật.
- Nhánh `test/zenith/demo-e2e-handoff` đã bổ sung test HTTP xuyên suốt ba vai trò, PostGIS test trong CI và hợp đồng tích hợp Flutter. Local đã qua 25 database/HTTP tests, 5 unit tests, lint, build, audit và Flutter checks; chờ CI/review/merge.

## Đang làm / Tiếp theo

1. Mở PR, chạy CI và review/merge nhánh `test/zenith/demo-e2e-handoff`.
2. Cam Thu/Vy merge UI Flutter Khách/Thợ/Admin và nối API theo [FLUTTER_API_HANDOFF.md](FLUTTER_API_HANDOFF.md); `lib/main.dart` trên main hiện vẫn là counter starter. Chưa có APK MotoCare hoàn chỉnh để gửi thầy.
3. Test APK release trên điện thoại khác mạng với HTTPS/WSS tới laptop qua Tailscale Funnel **sau khi** tách DB demo, đổi secret/mật khẩu đã lộ và hoàn tất checklist [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md). Laptop phải bật; không có bảo đảm 24/7.
4. Thiếu giá cuối **khác** giá tạm tính/thu bù/hoàn chênh lệch, rút tiền, webhook SePay thật, hoàn tiền thật và khiếu nại Admin sau khi bắt đầu sửa. Không quảng cáo sandbox là xử lý tiền thật.

## Quyết định đã chốt

- PostgreSQL + PostGIS, TypeORM migration thủ công; không `synchronize`.
- Tất cả tiền `numeric`/`decimal`, không float; vị trí `geography(Point,4326)` có GiST.
- Thu trước giá tạm tính rồi mới matching. Không tìm được thợ hoặc hủy trước khi sửa: hoàn 100%; sau khi bắt đầu sửa: Admin xét từng trường hợp. Thu/hoàn **thực** cần xác nhận ngân hàng/SePay, không tự giả định có escrow hoặc API hoàn tự động. Bản hiện tại chỉ sandbox, không nhận/chuyển tiền.
- Provider online gửi REST GPS 30–60 giây; matching chỉ dùng vị trí trong 120 giây, bán kính mặc định 10 km. Khi có đơn có thể gửi GPS theo đơn vài giây/lần; socket đẩy tới người tham gia và REST là fallback.
- UI Flutter do Cam Thu/Vy phụ trách; backend/DB chạy trên laptop khi demo không nằm trong APK. Không dùng `localhost` trong APK gửi người khác. Ưu tiên giải pháp không mất phí, nhưng miễn phí không đồng nghĩa uptime/băng thông không giới hạn.
- `wallet_transactions.amount` dương; chiều cộng/trừ suy từ `type`. Không seed mật khẩu mẫu ra môi trường công khai.

## Không dùng nữa / ghi chú vận hành

- `D:\mobile_app_motocare\motocare-backend` đã bỏ; backend chính là `mobilecare_1/backend`.
- `.env` không commit. Đổi JWT secret/DB password nếu từng hiện trong chat/ảnh; chỉ sửa `.env` không đổi password role trong PostgreSQL volume.
- Chạy local theo [README.md](../README.md); trước khi mở Funnel làm checklist trong [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md).
