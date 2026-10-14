# MotoCare — hợp đồng nghiệp vụ cho UI

Cập nhật: 2026-10-08. Tài liệu này là điểm bắt đầu cho Cam Thu/Vy khi nối Flutter. Swagger là hợp đồng payload thực tế; tài liệu này giải thích **khi nào** hiển thị màn hình/nút nào. Backend hiện là sandbox demo, không chuyển tiền ngân hàng thật.

## Nguyên tắc tích hợp

- REST là nguồn trạng thái chuẩn. Socket.IO chỉ báo có thay đổi; sau reconnect phải tải lại REST.
- UI không tự chuyển trạng thái, tự tính tiền hay tự suy ra quyền. Luôn dùng response mới nhất từ backend.
- Tiền là chuỗi decimal VND; không dùng `double`. Hiển thị `sandboxOnly=true` như giao dịch mô phỏng.
- `401`: xóa phiên và về đăng nhập. `403`: giữ phiên, báo thiếu quyền. `404`: không tiết lộ tài nguyên của người khác. `409`: tải lại snapshot vì trạng thái vừa thay đổi hoặc có request cạnh tranh. `429`: chờ rồi thử lại.
- Nhãn phạm vi: **MVP** chạy được; **SANDBOX** mô phỏng tiền; **FUTURE** chưa được phép đưa vào UI như tính năng thật.

## Hành trình theo vai trò

| Vai trò | Màn hình/khối UI | API chính | Realtime/fallback | Phạm vi |
| --- | --- | --- | --- | --- |
| Customer | Đăng ký/đăng nhập/quên mật khẩu | `/auth/*`, `/users/me` | Không | MVP |
| Customer | Chọn sự cố và tạo SOS | `GET /incident-types`, `POST /orders` | `GET /orders/:id` | MVP |
| Customer | Xác nhận trả trước | `POST /payments/demo/orders/:id/confirm` | Tải lại order | SANDBOX |
| Customer | Theo dõi thợ/chat | `GET /orders/:id`, `/messages` | room `order:{id}` | MVP |
| Customer | Mã bắt đầu sửa | `GET /orders/:id/start-token` | Tải lại order | MVP |
| Customer | Duyệt/từ chối giá cuối | `/price-proposals/:proposalId/approve|reject` | `order.status_changed` | SANDBOX |
| Customer | Xác nhận thu thêm | `/payments/demo/orders/:id/adjustment/confirm` | Tải lại order | SANDBOX |
| Customer | Đánh giá/lịch sử | `/reviews`, `GET /orders` | Không bắt buộc | MVP |
| Provider | Trạng thái online/GPS nền | `PATCH /providers/me/status|location` | room `provider:{id}` | MVP |
| Provider | Offer đang chờ | `GET /providers/me/offers/pending`, accept/reject | `offer.created|expired` | MVP |
| Provider | Đến nơi/bắt đầu/GPS theo đơn | `/arrive`, `/start`, location theo order | room `order:{id}` | MVP |
| Provider | Giá cuối và tranh chấp | `/price-proposals`, `/dispute` | `order.status_changed` | SANDBOX |
| Provider | Ví và yêu cầu rút | `/wallets/me`, `GET/POST /withdrawals` | Poll khi quay lại màn hình | SANDBOX |
| Admin | Duyệt thợ | `/admin/providers/*` | Poll | MVP |
| Admin | Dashboard/đối soát | `/admin/dashboard/*`, `/admin/reconciliation` | Poll/refresh | SANDBOX |
| Admin | Hoàn tiền/giá tranh chấp | `/admin/refunds/*`, `/admin/price-disputes/*` | Poll | SANDBOX |
| Admin | Duyệt rút tiền | `/admin/withdrawals/*` | Poll | SANDBOX |
| Khách | QR mô phỏng + webhook SePay Test mode | `GET /payments/orders/:id/instructions`; chỉ VA giả `SBSEPAY...`, response `simulationOnly=true`; webhook do SePay gọi | Có, khi backend bật Test mode | OPTIONAL_TEST |
| Mọi vai trò | SePay Live/chuyển-hoàn-rút ngân hàng thật | Chưa có | Không | FUTURE |

## State machine đơn hàng và hành động UI

| Trạng thái | Customer | Provider | Admin |
| --- | --- | --- | --- |
| `AWAITING_PREPAYMENT` | Hiện giá tạm tính; nút xác nhận sandbox/hủy | Không thấy offer | Theo dõi |
| `PENDING_MATCH` | Hiện đang tìm; cho retry/hủy | Không có hành động | Theo dõi |
| `OFFERED` | Hiện đang chờ thợ; cho hủy | Provider đúng offer thấy nhận/từ chối + countdown | Theo dõi |
| `ACCEPTED` | Bản đồ/chat; cho hủy trước sửa | Đi tới khách, gửi GPS, nút đã đến | Theo dõi |
| `ARRIVED` | Hiện token/QR bắt đầu | Nhập/quét token | Theo dõi |
| `IN_PROGRESS` | Chat; chờ giá cuối; không tự hủy | Đề xuất giá cuối | Theo dõi |
| `AWAITING_PRICE_APPROVAL` | Duyệt hoặc từ chối proposal | Chờ khách | Theo dõi |
| `PRICE_DISPUTED` | Chờ Admin | Chờ Admin | Duyệt/bác tranh chấp |
| `AWAITING_PAYMENT` | Nếu `CHARGE`: xác nhận thu thêm; nếu `REFUND`: chờ Admin | Chờ quyết toán | Xử lý refund adjustment |
| `PAID` | Hiện đã quyết toán | Nút hoàn tất | Theo dõi |
| `COMPLETED` | Đánh giá/xem lịch sử | Đánh giá/xem ví | Đối soát |
| `CANCELLED` | Trạng thái cuối | Trạng thái cuối | Theo dõi |
| `REFUND_PENDING` | Chờ Admin hoàn | Trạng thái cuối | Nút hoàn sandbox |
| `REFUNDED` | Đã hoàn sandbox | Trạng thái cuối | Đối soát |

Luồng chuẩn: `AWAITING_PREPAYMENT → PENDING_MATCH → OFFERED → ACCEPTED → ARRIVED → IN_PROGRESS → AWAITING_PRICE_APPROVAL → PAID/AWAITING_PAYMENT → PAID → COMPLETED`.

## Ví và rút tiền sandbox

`GET /wallets/me` và response withdrawal trả ba số do server tính:

- `balance`: tổng tiền demo còn trong ví.
- `lockedBalance`: phần đang giữ cho yêu cầu `PENDING`.
- `availableBalance`: phần có thể tạo yêu cầu mới; UI không tự trừ lại.

State machine withdrawal:

| Trạng thái | Provider UI | Admin UI | Ảnh hưởng ví |
| --- | --- | --- | --- |
| `PENDING` | Hiện “đang duyệt”, không coi là đã chuyển | Duyệt hoặc từ chối | Tăng `lockedBalance`, chưa tạo `DEBIT` |
| `APPROVED` | Hiện “đã duyệt sandbox” | Chỉ xem | Giảm `balance` và `lockedBalance`, tạo đúng một `DEBIT` |
| `REJECTED` | Hiện lý do | Chỉ xem | Giảm `lockedBalance`, không giảm `balance` |

Mỗi thợ chỉ có một yêu cầu `PENDING`; disable nút tạo mới cho tới khi Admin xử lý. Không nhập số tài khoản ngân hàng trong MVP. Không hiển thị “đã chuyển khoản”; dùng cụm “đã duyệt sandbox”.

## Realtime và đồng bộ lại

- `provider:{providerId}`: `offer.created`, `offer.expired`.
- `order:{orderId}`: `order.status_changed`, `provider.location_updated`, `message.created`.
- Mỗi event chỉ kích hoạt cập nhật UI nhanh. Khi socket mất/kết nối lại: tải order, pending offer và messages qua REST.
- Ví, dashboard và withdrawal hiện dùng REST refresh/poll; không cần thêm Socket event cho bản demo.

## Checklist cho mỗi màn hình

1. Có loading, empty, success và error/retry.
2. Disable nút ngay sau tap; nếu `409`, tải lại trạng thái thay vì gửi lặp mù.
3. Không log JWT, mã reset, token bắt đầu sửa hoặc nội dung ảnh riêng tư.
4. Không hard-code base URL, giá, thời gian offer hay state transition.
5. Hiển thị nhãn sandbox ở payment/wallet/withdrawal/Admin money dashboard.
6. Test mất mạng và reconnect; Socket không thay REST.
