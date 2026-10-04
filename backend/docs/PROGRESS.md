# MotoCare Backend — Trạng thái hiện tại

Cập nhật lần cuối: 2026-10-04

## Đã xong

- Prompt A: khung NestJS, Auth (JWT + argon2), RolesGuard, Swagger, health check.
- Migration: `EnablePostgis`, `CreateUsers`.
- TypeORM kết nối PostgreSQL/PostGIS, không dùng `synchronize`.
- Docker Compose chạy PostgreSQL + PostGIS local.
- Đã kiểm tra đăng ký qua Swagger, JWT và `GET /users/me` thành công.
- Backend đã nằm trong `mobilecare_1/backend` và đã merge vào `main`.
- Đã sửa kiểu cột nullable của `users.email` và `users.phone` để migration PostgreSQL chạy được.
- Prompt B: tạo entity + migration cho providers, incident_types, orders, order_offers, messages, reviews, payments, wallets, wallet_transactions và withdrawal_requests.
- Mọi cột tiền dùng PostgreSQL `numeric`, có check không âm; location dùng PostGIS geography + GiST.
- Seed 5 incident types, 3 provider approved/online quanh TP.HCM, 1 customer, 1 admin và provider wallets.
- Script `db:check-nearest-provider` kiểm chứng `ST_DWithin` + thứ tự `ST_Distance`.
- Đã chạy migration, seed, nearest-provider check, lint, test và build thành công.
- Đã bỏ quan hệ entity hai chiều `User`-`Provider` để tránh vòng import Jest; quan hệ database vẫn giữ FK 1-1 từ provider tới user.
- Prompt C: API incident types, provider GPS/online, tạo đơn, matching PostGIS, retry, accept/reject, danh sách offer đang chờ và job hết hạn offer.
- Đăng ký thợ nay tạo hồ sơ provider PENDING/offline cùng transaction với user.
- Migration `PreventConcurrentOffers` thêm unique index bảo vệ một offer PENDING cho mỗi order/provider và một order active cho mỗi provider.
- Đã kiểm tra migration từ DB test trống, 12 test PostGIS/concurrency, 5 unit test, lint, build, HTTP thực tế và Swagger `/docs-json`.
- Test đồng thời phát hiện snapshot query cũ có thể nhìn thợ rảnh sau khi transaction khác vừa tạo offer; matching nay kiểm tra lại dưới khóa provider bằng statement mới, trả PENDING_MATCH thay vì lỗi unique. Đã chạy lặp lại bộ test DB 3 lần.

## Đang làm / Tiếp theo

- Hoàn tất PR cho Prompt C. Sau đó Flutter có thể poll REST; bước sau là Google Maps/GPS hiển thị, WebSocket realtime/chat rồi payment SePay/wallet.

## Quyết định đã chốt (không hỏi lại)

- DB: PostgreSQL + PostGIS, TypeORM, migration thủ công; không dùng `synchronize`.
- Thanh toán: khách chuyển khoản vào tài khoản MotoCare, SePay webhook, cộng ví thợ, Admin duyệt rút tay.
- Mọi cột tiền dùng `numeric`/`decimal`, không dùng `float`.
- Vị trí dùng `geography(Point, 4326)` và GiST index.
- `provider.approval_status` tách khỏi `users.status` để phân biệt duyệt hồ sơ thợ và trạng thái tài khoản.
- `payments.sepay_transaction_id` unique nhưng nullable để cho phép tạo payment pending trước webhook.
- Branch milestone schema là `feat/db-schema`; PR policy đã cho phép riêng branch này.
- Prompt C dùng branch `feat/zenith/orders-matching`, không sửa PR Policy.
- Provider gửi GPS qua REST mỗi 30–60 giây khi online; matching chỉ nhận GPS còn mới trong 120 giây, mặc định bán kính 10 km.
- Offer hết hạn sau 15 giây; `@nestjs/schedule` quét mỗi 5 giây. PostgreSQL transaction/row lock xử lý race condition.
- WebSocket giai đoạn sau: `provider:{providerId}` nhận offer.created/expired; `order:{orderId}` nhận trạng thái đơn, GPS theo đơn, tin nhắn. REST pending offers/order là fallback.

## Việc đã bỏ / không dùng nữa

- Thư mục `D:\mobile_app_motocare\motocare-backend` không dùng nữa; backend chính là `mobilecare_1/backend`.

## Ghi chú vận hành

- Chạy local theo `README.md` phần cách chạy backend.
- `.env` không commit.
- Đổi `JWT_SECRET` nếu secret hoặc access token từng lộ ra ngoài chat/ảnh.
