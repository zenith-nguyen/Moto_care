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

## Đang làm / Tiếp theo

- Prompt B đã hoàn thành phần schema/seed. Bước tiếp theo là thiết kế API nghiệp vụ matching, payment và realtime; chưa triển khai logic trong Prompt B.

## Quyết định đã chốt (không hỏi lại)

- DB: PostgreSQL + PostGIS, TypeORM, migration thủ công; không dùng `synchronize`.
- Thanh toán: khách chuyển khoản vào tài khoản MotoCare, SePay webhook, cộng ví thợ, Admin duyệt rút tay.
- Mọi cột tiền dùng `numeric`/`decimal`, không dùng `float`.
- Vị trí dùng `geography(Point, 4326)` và GiST index.
- `provider.approval_status` tách khỏi `users.status` để phân biệt duyệt hồ sơ thợ và trạng thái tài khoản.
- `payments.sepay_transaction_id` unique nhưng nullable để cho phép tạo payment pending trước webhook.
- Branch milestone schema là `feat/db-schema`; PR policy đã cho phép riêng branch này.

## Việc đã bỏ / không dùng nữa

- Thư mục `D:\mobile_app_motocare\motocare-backend` không dùng nữa; backend chính là `mobilecare_1/backend`.

## Ghi chú vận hành

- Chạy local theo `README.md` phần cách chạy backend.
- `.env` không commit.
- Đổi `JWT_SECRET` nếu secret hoặc access token từng lộ ra ngoài chat/ảnh.
