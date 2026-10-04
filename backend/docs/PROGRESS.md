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

## Đang làm / Tiếp theo

- Prompt B: schema lõi gồm providers, orders, payments, wallets và các bảng liên quan — chờ duyệt kế hoạch trước khi code.

## Quyết định đã chốt (không hỏi lại)

- DB: PostgreSQL + PostGIS, TypeORM, migration thủ công; không dùng `synchronize`.
- Thanh toán: khách chuyển khoản vào tài khoản MotoCare, SePay webhook, cộng ví thợ, Admin duyệt rút tay.
- Mọi cột tiền dùng `numeric`/`decimal`, không dùng `float`.
- Vị trí dùng `geography(Point, 4326)` và GiST index.

## Việc đã bỏ / không dùng nữa

- Thư mục `D:\mobile_app_motocare\motocare-backend` không dùng nữa; backend chính là `mobilecare_1/backend`.

## Ghi chú vận hành

- Chạy local theo `README.md` phần cách chạy backend.
- `.env` không commit.
- Đổi `JWT_SECRET` nếu secret hoặc access token từng lộ ra ngoài chat/ảnh.
