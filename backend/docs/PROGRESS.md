# MotoCare Backend — Trạng thái hiện tại

Cập nhật lần cuối: 2026-10-07

## Đã xong

- Prompt A: NestJS, Auth JWT/argon2, RolesGuard, Swagger, health; migration PostGIS và users. Đã thử đăng ký, đăng nhập, `/users/me`.
- Prompt B: 11 bảng lõi (users, providers, incident_types, orders, order_offers, messages, reviews, payments, wallets, wallet_transactions, withdrawal_requests); migration, seed local, index GiST, tiền `numeric`, test truy vấn `ST_DWithin`.
- Prompt C (đã merge PR #5): loại sự cố, GPS/online của thợ, tạo đơn, matching PostGIS, accept/reject, offer 15 giây, job hết hạn 5 giây, retry, REST polling, khóa dòng + unique index chống nhận trùng. CI/lint/test đã xanh khi merge.
- PR #7 đã merge vào `main`: API admin duyệt thợ; demo trả trước/hoàn 100% giả lập; hủy trước khi bắt đầu; chat lưu DB; Socket.IO offer/trạng thái/GPS/chat; tới nơi/mã bắt đầu/hoàn tất đúng giá gốc; ví demo và đánh giá hai chiều; `/health/ready` kiểm tra DB; hướng dẫn demo một laptop. Migration local đã chạy đủ 6 bản; Docker/PostGIS và readiness đã kiểm tra OK ngày 2026-10-05. Đây vẫn là sandbox, không phải thanh toán thật.
- PR #8 đã merge vào `main`: test HTTP xuyên suốt ba vai trò, PostGIS test trong CI và hợp đồng tích hợp Flutter. Mốc merge đã qua 25 database/HTTP tests, 5 unit tests, lint, build, audit và Flutter checks.
- PR #9 đã merge vào `main`: chat nhận text/ảnh JPEG-PNG-WebP tối đa 5 MiB, lưu file local ngoài public web root, metadata trong DB, URL tải có JWT/quyền theo đơn, realtime payload có ảnh, và lịch sử đọc được sau khi đơn đóng. Đã thêm catalog API và backlog non-functional; migration upload là `0006`.
- PR #10 đã merge vào `main`: quên/đặt lại mật khẩu bằng mã email dùng một lần, khóa tạm sau đăng nhập sai và vô hiệu JWT cũ cho REST/Socket sau reset; migration `0007`. CI Backend, Flutter và branch policy đều xanh.
- PR #11 đã merge vào `main`: dashboard Admin, chuỗi thời gian và đối soát order/payment/wallet; bộ lọc thời gian, phân trang, decimal strings và cờ bất thường. Mốc merge đã qua 9 unit tests, 28 database/HTTP tests, lint và build.
- PR #12 đã merge vào `main`: request ID, log JSON không chứa query/body/header, response lỗi an toàn, Helmet, CORS không wildcard, rate limit REST/auth/upload, giới hạn multipart/socket, secret HMAC tách biệt và CI chặn file/chuỗi nhạy cảm. Mốc merge đã qua 15 unit tests, 28 database/HTTP tests, lint, build và production audit không có lỗ hổng đã biết.
- PR #13 đã merge vào `main`: kiểm tra dung lượng, snapshot PostgreSQL + ảnh chat + checksum và restore có chốt an toàn. Đã phục hồi độc lập và xác nhận 8 migrations / 6 users / 5 incident types; readiness `200`, DB restore thử đã xóa.
- PR #15 đã merge vào `main`: weather pricing snapshot với Open-Meteo cache/timeout/fallback, tính tiền bằng `BigInt`, migration `0008`, breakdown cho Swagger/Flutter; mặc định tắt.
- PR #16 đã merge vào `main`: proposal giá cuối, khách duyệt/từ chối, tranh chấp Admin, charge/refund adjustment sandbox, đối soát và wallet credit theo giá cuối; migration `0009–0010`, CI xanh.
- PR #17 đã merge vào `main`: rút tiền sandbox atomic, `lockedBalance`/`availableBalance`, một yêu cầu chờ mỗi ví, Admin duyệt/từ chối và debit duy nhất; migration `0011`, CI xanh.
- PR #18 đã merge vào `main`: test bảo mật/room/event Socket.IO, smoke-load REST chỉ đọc và checklist reconnect/REST fallback/ba màn hình; 28 unit, 35 PostgreSQL/PostGIS/HTTP tests và CI xanh.
- PR #19 đã merge vào `main`: đồ thị state transition tập trung, tách Orders query/presenter khỏi command service và tài liệu modular monolith; giữ nguyên 51 Swagger operation/schema, CI xanh.

## Đang làm / Tiếp theo

1. Nhánh `refactor/zenith/realtime-publisher-port`: mọi application service phụ thuộc port thuần TypeScript; Socket.IO gateway là adapter `useExisting`. Event name/room/payload và API Flutter giữ nguyên; đã đạt lint, build, 47 unit và 35 PostgreSQL/PostGIS/HTTP tests.
2. PR refactor kế tiếp: chuyển settlement/payment/wallet ra khỏi Orders bằng port thuộc Payments, giữ nguyên transaction và unique constraint.
3. Sau refactor có mục tiêu: thiết kế SePay webhook/QR thật ở chế độ tắt mặc định; chưa nối tiền thật khi chưa có sandbox/tài khoản ngân hàng và quy trình đối soát được duyệt.
4. Cấu hình SMTP Gmail demo bằng App Password trong `.env` cục bộ; không commit/chụp/gửi secret.
5. Cam Thu/Vy merge UI Flutter Khách/Thợ/Admin và nối API theo [FLUTTER_API_HANDOFF.md](FLUTTER_API_HANDOFF.md); `lib/main.dart` trên main hiện vẫn là counter starter. Chưa có APK MotoCare hoàn chỉnh để gửi thầy.
6. Test APK release trên điện thoại khác mạng với HTTPS/WSS tới laptop qua Tailscale Funnel **sau khi** tách DB demo, đổi secret/mật khẩu đã lộ và hoàn tất checklist [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md). Laptop phải bật; không có bảo đảm 24/7.
7. Thanh toán thật còn thiếu webhook SePay, hoàn tiền thật và đối soát ngân hàng. Không quảng cáo sandbox là xử lý tiền thật.

## Quyết định đã chốt

- PostgreSQL + PostGIS, TypeORM migration thủ công; không `synchronize`.
- Tất cả tiền `numeric`/`decimal`, không float; vị trí `geography(Point,4326)` có GiST.
- Thu trước giá tạm tính rồi mới matching. Không tìm được thợ hoặc hủy trước khi sửa: hoàn 100%; sau khi bắt đầu sửa: Admin xét từng trường hợp. Thu/hoàn **thực** cần xác nhận ngân hàng/SePay, không tự giả định có escrow hoặc API hoàn tự động. Bản hiện tại chỉ sandbox, không nhận/chuyển tiền.
- Provider online gửi REST GPS 30–60 giây; matching chỉ dùng vị trí trong 120 giây, bán kính mặc định 10 km. Khi có đơn có thể gửi GPS theo đơn vài giây/lần; socket đẩy tới người tham gia và REST là fallback.
- UI Flutter do Cam Thu/Vy phụ trách; backend/DB chạy trên laptop khi demo không nằm trong APK. Không dùng `localhost` trong APK gửi người khác. Ưu tiên giải pháp không mất phí, nhưng miễn phí không đồng nghĩa uptime/băng thông không giới hạn.
- `wallet_transactions.amount` dương; chiều cộng/trừ suy từ `type`. Không seed mật khẩu mẫu ra môi trường công khai.
- Chat dùng PostgreSQL cho lịch sử/metadata, Socket.IO để báo realtime, REST để đồng bộ lại. Ảnh lưu local có URL bảo vệ; backup DB phải đi kèm backup thư mục ảnh.
- Secret public/production tách theo mục đích: JWT, HMAC mã bắt đầu sửa và HMAC mã reset mật khẩu; không đưa vào Flutter. Webhook thanh toán thật phải xác thực chữ ký raw body, chống replay và idempotent trước khi được mở.

## Không dùng nữa / ghi chú vận hành

- `D:\mobile_app_motocare\motocare-backend` đã bỏ; backend chính là `mobilecare_1/backend`.
- `.env` không commit. Đổi JWT secret/DB password nếu từng hiện trong chat/ảnh; chỉ sửa `.env` không đổi password role trong PostgreSQL volume.
- Chạy local theo [README.md](../README.md); trước khi mở Funnel làm checklist trong [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md).
