# MotoCare Backend — danh mục API hiện tại

Cập nhật: 2026-10-06. Có 38 REST endpoints và 5 Socket.IO events. Mặc định mọi API cần `Authorization: Bearer <JWT>`; chỉ Auth và Health là public. Swagger local: `http://localhost:3000/docs` khi `DEMO_MODE=false` và không chạy production.

## Auth, tài khoản và health

| Method | Path | Quyền | Trạng thái / mục đích |
| --- | --- | --- | --- |
| POST | `/auth/register` | Public, rate-limit | Đăng ký Customer/Provider; Provider chờ Admin duyệt |
| POST | `/auth/login` | Public, rate-limit | Đăng nhập bằng email/phone và trả JWT |
| POST | `/auth/password/forgot` | Public, 3 lần/phút | Nếu email tồn tại, gửi mã sáu số dùng một lần; response luôn chung chung |
| POST | `/auth/password/reset` | Public, 10 lần/phút | Đổi mật khẩu bằng email + mã + mật khẩu mới; vô hiệu mọi JWT cũ |
| GET | `/users/me` | Đã đăng nhập | Hồ sơ tài khoản hiện tại |
| GET | `/health` | Public | NestJS process đang phản hồi |
| GET | `/health/ready` | Public | API gọi được PostgreSQL |

Mã đặt lại mật khẩu hết hạn sau 10 phút, giới hạn năm lần nhập sai và chỉ gửi lại sau 60 giây. Sau năm lần đăng nhập sai liên tiếp, tài khoản tạm khóa 15 phút. Chưa có refresh token, xác minh email và đăng xuất server-side.

## Danh mục sự cố và thợ

| Method | Path | Quyền | Trạng thái / mục đích |
| --- | --- | --- | --- |
| GET | `/incident-types` | Đã đăng nhập | 5 loại sự cố active và giá cơ bản |
| PATCH | `/providers/me/location` | Provider | GPS nền khi online/chưa có đơn |
| PATCH | `/providers/me/status` | Provider đã duyệt | Bật/tắt sẵn sàng nhận đơn |
| PATCH | `/providers/me/orders/:orderId/location` | Provider được gán | GPS theo đơn và phát realtime |
| GET | `/providers/me/offers/pending` | Provider | REST fallback cho offer đang chờ |

Matching dùng PostGIS, vị trí tối đa 120 giây, bán kính mặc định 10 km và offer mặc định 15 giây.

## Đơn cứu hộ

| Method | Path | Quyền | Trạng thái / mục đích |
| --- | --- | --- | --- |
| GET | `/orders` | Customer/Provider | 30 đơn gần nhất của chính mình |
| POST | `/orders` | Customer | Tạo đơn, snapshot giá cơ bản + thời tiết; chờ thanh toán sandbox |
| GET | `/orders/:orderId` | Người tham gia | Snapshot trạng thái/payment/GPS |
| POST | `/orders/:orderId/retry-match` | Customer | Thử matching lại |
| POST | `/orders/:orderId/cancel` | Customer | Hủy trước khi bắt đầu sửa |
| POST | `/orders/:orderId/offers/:offerId/accept` | Provider của offer | Nhận đơn atomic, chống race condition |
| POST | `/orders/:orderId/offers/:offerId/reject` | Provider của offer | Từ chối và tìm thợ kế tiếp ngay |
| POST | `/orders/:orderId/arrive` | Provider được gán | Báo đã đến nơi |
| GET | `/orders/:orderId/start-token` | Customer | Mã HMAC 5 phút để xác nhận bắt đầu; không phải QR ngân hàng |
| POST | `/orders/:orderId/start` | Provider được gán | Bắt đầu sửa bằng token của khách |
| POST | `/orders/:orderId/complete` | Provider được gán | Hoàn tất đúng giá gốc và cộng ví demo một lần |

## Chat và đánh giá

| Method | Path | Quyền | Trạng thái / mục đích |
| --- | --- | --- | --- |
| GET | `/orders/:orderId/messages` | Người tham gia | 100 tin gần nhất, kể cả đơn đã đóng |
| POST | `/orders/:orderId/messages` | Người tham gia, đơn active | Text JSON hoặc multipart text/ảnh |
| GET | `/orders/:orderId/messages/:messageId/image` | Người tham gia | Tải ảnh có JWT, không public static |
| GET | `/orders/:orderId/reviews` | Người tham gia | Hai đánh giá sau hoàn tất |
| POST | `/orders/:orderId/reviews` | Người tham gia | Mỗi bên đánh giá một lần |

Chi tiết chat: [CHAT_WORKFLOW.md](CHAT_WORKFLOW.md).

## Thanh toán/ví sandbox và Admin

| Method | Path | Quyền | Trạng thái / mục đích |
| --- | --- | --- | --- |
| POST | `/payments/demo/orders/:orderId/confirm` | Customer | Giả lập trả đúng giá tạm tính rồi matching |
| POST | `/payments/demo/orders/:orderId/refund` | Admin | Giả lập hoàn 100% |
| GET | `/wallets/me` | Provider | Số dư/giao dịch demo, không rút tiền thật |
| GET | `/admin/orders` | Admin | 50 đơn gần nhất |
| GET | `/admin/refunds/pending` | Admin | Danh sách chờ hoàn sandbox |
| GET | `/admin/providers/pending` | Admin | Hồ sơ thợ chờ duyệt |
| PATCH | `/admin/providers/:providerId/approval` | Admin | Duyệt/từ chối hồ sơ một lần |
| GET | `/admin/dashboard/summary` | Admin | Tổng user/thợ/đơn và các nhóm tiền sandbox |
| GET | `/admin/dashboard/timeseries` | Admin | Số đơn, thu, hoàn, quyết toán theo ngày |
| GET | `/admin/reconciliation` | Admin | Đối soát order/payment/wallet, phân trang và cờ bất thường |

Không có QR ngân hàng, webhook SePay, chuyển/hoàn tiền thật, thu bù/hoàn chênh lệch, yêu cầu rút tiền hay xử lý tranh chấp sau khi sửa. Không trình bày các endpoint demo như thanh toán thật.

Dashboard mặc định 7 ngày, tối đa 366 ngày và nhóm ngày theo `Asia/Ho_Chi_Minh`. Tiền luôn là chuỗi decimal. `collectedInPeriod`, `heldCurrent`, `settledToProvidersInPeriod`, `refundPendingCurrent` và `refundedInPeriod` là các khái niệm riêng; chưa có `platformRevenue` vì nhóm chưa chốt phí nền tảng. Chi tiết ở [ADMIN_ANALYTICS_PLAN.md](ADMIN_ANALYTICS_PLAN.md).

## Socket.IO

Handshake cùng API origin, dùng `auth: { token, orderId? }`; không đặt JWT trong URL.

| Room | Event | Payload chính |
| --- | --- | --- |
| `provider:{providerId}` | `offer.created` | `orderId`, `offerId`, `expiresAt` |
| `provider:{providerId}` | `offer.expired` | `orderId`, `offerId` |
| `order:{orderId}` | `order.status_changed` | `orderId`, `status` |
| `order:{orderId}` | `provider.location_updated` | `providerId`, lat/lng, `updatedAt` |
| `order:{orderId}` | `message.created` | Tin nhắn đầy đủ, gồm metadata ảnh nếu có |

Socket giúp cập nhật nhanh, không thay REST. Sau reconnect client phải gọi lại order, offers và messages.

## Non-functional hiện có và khoảng trống

Đã có: DTO validation/whitelist, JWT + role guard, global REST throttling và giới hạn riêng cho auth/upload, request ID, log JSON không ghi query/body/header, response lỗi an toàn thống nhất, Helmet, CORS không wildcard, atomic transaction/row lock, unique/check constraints, `numeric` cho tiền, GiST cho location, upload size/type/signature/part checks, protected image access, readiness DB, migrations thủ công, CI + unit/HTTP/PostGIS tests, kiểm tra file nhạy cảm, sandbox bị chặn trong production và snapshot DB + ảnh chat có checksum/restore rehearsal. Chi tiết: [SECURITY.md](SECURITY.md), [BACKUP_RESTORE.md](BACKUP_RESTORE.md).

Cần tăng cường theo thứ tự:

1. Test tải nhẹ REST/WebSocket trên laptop demo; đo reconnect và upload chậm.
2. Bổ sung rate limit WebSocket/phân tán nếu chuyển sang nhiều process hoặc public 24/7.
3. Khi có nhu cầu 24/7: lịch backup tự động ra thiết bị khác, object storage, retention/cleanup file, secret manager và server công khai ổn định. Đây chưa phải yêu cầu bản demo không phí.
4. Giá theo thời tiết mới ở mức thiết kế, chưa chạy trong API; xem [WEATHER_PRICING_PLAN.md](WEATHER_PRICING_PLAN.md).
