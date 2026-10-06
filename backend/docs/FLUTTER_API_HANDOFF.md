# MotoCare API handoff cho Flutter

Cập nhật: 2026-10-06. Đây là hợp đồng tích hợp cho UI Khách, Thợ và Admin. Backend hiện tại là **sandbox demo**: không nhận, chuyển hoặc hoàn tiền ngân hàng thật.

## Cấu hình ứng dụng

- Nhận URL API khi build bằng `--dart-define=API_BASE_URL=...`; không hard-code `localhost` trong APK gửi sang máy khác.
- Dùng một `Dio` client chung, timeout rõ ràng, tự gắn `Authorization: Bearer <JWT>` và ánh xạ lỗi HTTP về thông báo tiếng Việt.
- Lưu JWT trong `flutter_secure_storage`; không log token và không đưa DB/JWT secret vào Flutter.
- REST và Socket.IO dùng cùng origin. HTTPS tương ứng với WSS.
- Tiền là chuỗi decimal VND, ví dụ `"100000.00"`; không tính tiền bằng `double`.
- Request vị trí dùng `{ "latitude": 10.7769, "longitude": 106.7009 }`. GeoJSON response dùng `[longitude, latitude]`.

Ví dụ Android Emulator gọi backend trên cùng laptop:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

APK dùng ở mạng khác phải nhận URL HTTPS của môi trường demo.

## Khởi tạo phiên đăng nhập

1. Gọi `POST /auth/login`.
2. Lưu `accessToken` an toàn.
3. Điều hướng theo `user.role`: `CUSTOMER`, `PROVIDER`, hoặc `ADMIN`.
4. Khi API trả `401`, xóa phiên và đưa người dùng về đăng nhập. Khi `403`, giữ phiên nhưng báo không đủ quyền hoặc trạng thái tài khoản chưa hợp lệ.

Provider mới đăng ký ở trạng thái chờ duyệt. Admin dùng `GET /admin/providers/pending` và `PATCH /admin/providers/:id/approval`. Provider chỉ bật online sau khi được duyệt và đã gửi vị trí mới.

### Quên mật khẩu

1. Màn hình quên mật khẩu gửi `{ "email": "..." }` tới `POST /auth/password/forgot`.
2. Luôn hiển thị thông báo trung tính kiểu “Nếu email đã đăng ký, mã khôi phục sẽ được gửi”; không tiết lộ email có tồn tại hay không.
3. Màn hình nhập mã gửi `{ "email": "...", "code": "123456", "newPassword": "..." }` tới `POST /auth/password/reset`.
4. Mã có sáu chữ số, hết hạn sau 10 phút và dùng một lần. Sau khi thành công, xóa JWT đang lưu và đưa người dùng về màn hình đăng nhập.
5. Tài khoản chỉ có số điện thoại chưa thể nhận mã email; UI nên giải thích rõ và khuyến khích đăng ký email trong bản demo.

## Luồng Khách

1. `GET /incident-types` để hiển thị lựa chọn nhanh và giá cơ bản.
2. `POST /orders` với loại sự cố và GPS khách. Đơn mới là `AWAITING_PREPAYMENT`.
3. Trong sandbox, gọi `POST /payments/demo/orders/:id/confirm`. Sau đó backend mới matching.
4. Theo dõi bằng `GET /orders/:id`; socket chỉ giúp cập nhật nhanh hơn, REST vẫn là nguồn snapshot khi reconnect.
5. Khi thợ nhận đơn: xem marker từ `providerLocation`, chat chữ/ảnh qua `GET/POST /orders/:id/messages`.
6. Khi trạng thái `ARRIVED`, gọi `GET /orders/:id/start-token` và hiển thị token dưới dạng QR hoặc chữ cho thợ. Đây không phải QR ngân hàng.
7. Khi `COMPLETED`, gọi `GET/POST /orders/:id/reviews`.
8. Trước khi bắt đầu sửa, khách có thể `POST /orders/:id/cancel`; đơn đã trả sandbox chuyển sang `REFUND_PENDING`.

## Luồng Thợ

1. Khi mở chế độ sẵn sàng, gửi `PATCH /providers/me/location`, rồi `PATCH /providers/me/status` với `isOnline=true`.
2. Khi chưa có đơn, cập nhật location khoảng 30–60 giây/lần. Matching bỏ qua vị trí cũ hơn 120 giây.
3. Lấy offer bằng socket room `provider:{providerId}` hoặc fallback `GET /providers/me/offers/pending`.
4. Nhận/từ chối tại `POST /orders/:id/offers/:offerId/accept|reject`.
5. Khi đang tới khách, gửi `PATCH /providers/me/orders/:id/location` khoảng 3–5 giây/lần trong foreground.
6. Tại nơi: `POST /orders/:id/arrive`; nhập/quét token khách rồi `POST /orders/:id/start`.
7. Hoàn tất sandbox bằng `POST /orders/:id/complete`; xem số dư giả lập ở `GET /wallets/me`.
8. Khi không nhận đơn nữa, gửi `PATCH /providers/me/status` với `isOnline=false`.

## Luồng Admin

- Duyệt hồ sơ: `GET /admin/providers/pending`, `PATCH /admin/providers/:id/approval`.
- Theo dõi đơn gần nhất: `GET /admin/orders`.
- Xử lý hoàn sandbox: `GET /admin/refunds/pending`, sau đó `POST /payments/demo/orders/:id/refund`.

Không hiển thị các thao tác sandbox như giao dịch ngân hàng thật.

Backend hiện chưa có API tổng hợp dashboard. UI chưa được tự cộng “doanh thu” từ danh sách đơn vì tiền đã thu, tiền đang giữ, tiền đã quyết toán vào ví, tiền chờ hoàn và tiền đã hoàn là các chỉ số khác nhau. Một API metrics/đối soát riêng sẽ được cung cấp ở milestone Admin tiếp theo.

## Realtime và fallback

Handshake Socket.IO:

```json
{ "auth": { "token": "<JWT>", "orderId": 123 } }
```

- `provider:{providerId}`: `offer.created`, `offer.expired`.
- `order:{orderId}`: `order.status_changed`, `provider.location_updated`, `message.created`.
- Provider bật online sau khi socket đã kết nối cần reconnect để join provider room.
- Sau mất mạng/reconnect, luôn tải lại order, pending offers và messages qua REST; event socket có thể đã bị bỏ lỡ.
- Demo GPS foreground trước. Không hứa cập nhật liên tục khi Android khóa màn hình, tắt quyền vị trí hoặc dừng app.

## Chat chữ và ảnh

- Tin chữ: gửi JSON `{ "content": "..." }`.
- Tin ảnh hoặc chữ + ảnh: gửi `multipart/form-data`, field `content` tùy chọn và file field `image`.
- Chấp nhận một JPEG/PNG/WebP tối đa 5 MiB. Client nên nén ảnh trước khi gửi để demo qua mạng ổn định hơn.
- Response và event `message.created` có `content` nullable và `image` nullable. `image.url` là đường dẫn API có bảo vệ; ghép với `API_BASE_URL` và tải bằng `Dio` có Bearer token, không dùng widget tải ảnh ẩn danh.
- Chỉ gửi tin khi đơn active; người tham gia vẫn đọc lịch sử sau khi hoàn tất/hủy. Sau reconnect gọi lại `GET /orders/:id/messages`.

Chi tiết payload, quyền và sơ đồ xử lý ở [CHAT_WORKFLOW.md](CHAT_WORKFLOW.md).

## Trạng thái đơn cần hiển thị

| Trạng thái            | Ý nghĩa UI                                   |
| --------------------- | -------------------------------------------- |
| `AWAITING_PREPAYMENT` | Chờ xác nhận thanh toán sandbox              |
| `PENDING_MATCH`       | Chưa tìm được thợ; cho phép thử matching lại |
| `OFFERED`             | Đang chờ một thợ phản hồi                    |
| `ACCEPTED`            | Thợ đã nhận và đang tới                      |
| `ARRIVED`             | Thợ đã đến; khách hiển thị mã bắt đầu        |
| `IN_PROGRESS`         | Đang sửa, không cho khách tự hủy             |
| `COMPLETED`           | Hoàn tất, cho phép đánh giá                  |
| `CANCELLED`           | Hủy khi chưa có khoản cần hoàn               |
| `REFUND_PENDING`      | Admin cần hoàn sandbox                       |
| `REFUNDED`            | Đã hoàn sandbox                              |

UI không tự suy diễn trạng thái mới; dùng response mới nhất từ server.

## Nghiệm thu tích hợp

Backend có bài test HTTP dùng DB test riêng cho hai luồng: hoàn tất dịch vụ ba vai trò và hủy/hoàn 100%. Chạy:

```powershell
$env:TEST_DATABASE_NAME = 'motocare_orders_test'
npm run test:db
```

Trước khi gửi APK, chạy checklist đầy đủ trong [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md).
