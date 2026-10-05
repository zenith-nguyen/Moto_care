# MotoCare — demo một laptop, ba vai trò (không dùng tiền thật)

Cập nhật: 2026-10-05. Tài liệu này là **hướng dẫn chuẩn bị**, không phải xác nhận APK đã hoàn thiện. Hiện repo `main` vẫn có Flutter counter starter; Cam Thu/Vy cần merge UI và tích hợp API trước khi có thể phát APK cho thầy.

## Kiến trúc và giới hạn

`APK/Flutter (Khách, Thợ, Admin) → HTTPS/WSS → NestJS trên laptop → PostgreSQL/PostGIS trong Docker trên laptop`. DBeaver chỉ xem DB; Docker không tự nằm trong APK. Nếu laptop tắt/ngủ, mất mạng, NestJS/Docker/Tailscale dừng thì APK của thầy **không dùng được**. Đây là demo không có cam kết 24/7, không phải production. Tuyệt đối không thử chuyển khoản thật.

Để mở API miễn phí cho máy khác mạng, có thể dùng [Tailscale Funnel](https://tailscale.com/docs/features/tailscale-funnel) trên gói [Personal miễn phí](https://tailscale.com/pricing); Funnel hiện được ghi là beta. URL HTTPS của Funnel là *công khai* cho bất kỳ ai có URL. Không mở cổng PostgreSQL 5432 ra Internet. Không dùng Quick Tunnel làm URL gắn cứng cho APK nộp bài vì URL tạm. Tailscale không thay thế việc giữ laptop hoạt động; điều khoản/gói miễn phí có thể thay đổi.

## Điều kiện an toàn trước khi bật Funnel

1. Dùng **database demo riêng**, không dùng DB `motocare` local từng seed bằng mật khẩu mẫu. Sao lưu DB nếu cần. Tạo DB mới, chạy migrations và seed với `DEMO_MODE=true` cùng ba biến `SEED_CUSTOMER_PASSWORD`, `SEED_PROVIDER_PASSWORD`, `SEED_ADMIN_PASSWORD`, mỗi giá trị khác nhau, dài tối thiểu 16 ký tự và không phải mật khẩu mẫu. Seed chỉ tạo user mới, không cập nhật mật khẩu user đã tồn tại; nếu đã seed DB đó bằng mật khẩu mẫu thì tạo DB demo mới, không chỉ chạy seed lại.
2. Đổi `JWT_SECRET` và `DATABASE_PASSWORD` đã từng lộ trong chat/ảnh. Đổi mật khẩu PostgreSQL thực tế qua SQL an toàn rồi cập nhật `.env`; **chỉ sửa `.env` không đổi mật khẩu DB đã được khởi tạo trong Docker volume**. Không gửi giá trị mới vào chat/commit/APK. Chạy API bằng biến môi trường riêng cho demo; không commit `.env`.
3. Bật `DEMO_MODE=true`, giữ `NODE_ENV=development` cho tính năng giả lập. **Đây là sandbox công khai, không có nghĩa là production an toàn**. Không chạy webhook/QR ngân hàng hoặc lấy tiền thật. Tắt Funnel ngay sau buổi demo. Không gửi URL cho người ngoài lớp.
4. `DEMO_MODE=true` sẽ tắt Swagger `/docs`. Login/register có giới hạn 10 request/phút theo IP ở mức một NestJS process (không thay thế WAF); vẫn cần kiểm tra log không có token/secret, backup và phục hồi DB. Chưa hoàn tất các mục đó ở mốc này thì chỉ demo với nhóm tin cậy trong thời gian ngắn.

## Khởi động và thử truy cập

Trong PowerShell bình thường tại `mobilecare_1/backend`:

```powershell
docker compose up -d
docker compose ps
npm run migration:run
npm run start:dev
```

`npm run seed` chỉ chạy **một lần trên DB demo mới**, sau khi đã cấu hình mật khẩu demo riêng. Trên PowerShell thứ hai, sau khi cài/đăng nhập Tailscale và cho phép Funnel trong trình duyệt theo hướng dẫn chính thức:

```powershell
tailscale funnel 3000
```

Giữ cửa sổ này chạy; ghi lại URL `https://...ts.net` mà lệnh in ra. Thử `https://...ts.net/health/ready` trên điện thoại **khác mạng Wi-Fi** (dùng 4G). Cần thấy `{"status":"ok","database":"ok"}`; điều này chứng minh API và DB truy cập được, **không chứng minh mọi tính năng đã hoạt động**. Sau demo dừng Funnel bằng `Ctrl+C`, kiểm tra lại trạng thái bằng `tailscale funnel status`. Trước khi mở Internet, kiểm tra máy không tự ngủ và Docker container healthy.

Flutter phải nhận API base URL ở lúc build, ví dụ `--dart-define=API_BASE_URL=https://...ts.net`; **không dùng `localhost` hay IP LAN trong APK gửi thầy**. Cả REST và Socket.IO dùng cùng URL; với HTTPS, kết nối WebSocket đi qua WSS. Nếu dùng Flutter web/Admin trên trình duyệt, thêm đúng origin của web vào `CORS_ORIGIN` trên server (các origin cách nhau bằng dấu phẩy), không dùng `*`. Không đưa mật khẩu DB/JWT secret vào `dart-define`. Sau khi UI đã merge, tạo APK release theo [hướng dẫn Flutter Android](https://docs.flutter.dev/deployment/android), cài thử đúng file APK đó trên điện thoại ngoài mạng LAN, không chỉ chạy emulator/debug.

## Ba màn hình trên một laptop

Có thể demo 3 vai trò cùng lúc **khi UI của cả ba đã có**: dùng 1 Android emulator hoặc điện thoại thật cho Khách, một thiết bị/emulator thứ hai cho Thợ và cửa sổ Flutter web/Windows cho Admin nếu UI hỗ trợ web/Windows. Nếu Admin chỉ có giao diện mobile, dùng emulator/điện thoại thứ ba. Máy 16 GB RAM có thể chậm với 3 emulator cùng Docker; nên thử trước, ưu tiên 1 emulator + 2 máy thật/trình duyệt nếu nhóm hỗ trợ. Ba phiên phải đăng nhập tài khoản **khác vai trò**; không dùng cùng JWT. Trình chiếu/mirror từng màn hình chỉ là vấn đề hiển thị, không thay đổi kiến trúc API.

## Hợp đồng API tối thiểu cho nhóm Flutter

| Bước | Khách | Thợ | Admin |
| --- | --- | --- | --- |
| Đăng nhập | `POST /auth/login` | `POST /auth/login` | `POST /auth/login` |
| Khởi tạo | `GET /incident-types`, `POST /orders` | `PATCH /providers/me/location`, `PATCH /providers/me/status` | `GET /admin/providers/pending` |
| Demo trả trước | `POST /payments/demo/orders/:id/confirm` | — | — |
| Nhận đơn | `GET /orders`, `GET /orders/:id` | `GET /orders`, `GET /providers/me/offers/pending`, `POST /orders/:id/offers/:offerId/accept` hoặc `/reject` | `PATCH /admin/providers/:id/approval`, `GET /admin/orders` |
| Theo dõi/chat | `GET /orders/:id`, `GET/POST /orders/:id/messages` | `PATCH /providers/me/orders/:id/location`, `GET/POST /orders/:id/messages` | — |
| Tới nơi/bắt đầu | `GET /orders/:id/start-token` (hiện mã cho thợ quét/nhập) | `POST /orders/:id/arrive`, `POST /orders/:id/start` với token | — |
| Hoàn tất/đánh giá | `GET/POST /orders/:id/reviews` | `POST /orders/:id/complete`, `GET /wallets/me`, `GET/POST /orders/:id/reviews` | — |
| Hủy/hoàn giả lập | `POST /orders/:id/cancel` | — | `GET /admin/refunds/pending`, `POST /payments/demo/orders/:id/refund` |

`POST /orders` trả `AWAITING_PREPAYMENT`, không matching trước xác nhận giả lập. `GET /orders/:id` trả payment và vị trí thợ khi đơn active. Token bắt đầu có hiệu lực 5 phút; đây là mã xác nhận gặp mặt, **không phải QR ngân hàng**. Hiện `complete` chỉ cho giá cuối đúng bằng giá tạm tính đã trả giả lập; ví thợ chỉ là số liệu demo, không có rút tiền. Trường `amount`/`estimatedPrice` là decimal string VND, không parse bằng floating-point cho phép tính tiền. Toạ độ PostGIS/JSON GeoPoint là `[longitude, latitude]`, còn request vị trí dùng `{latitude, longitude}`. Cần refresh snapshot bằng REST khi reconnect vì event socket có thể bị bỏ lỡ.

Socket.IO handshake `auth: { token, orderId? }`, không để JWT trong URL. `provider:{id}` được join lúc provider kết nối và đã approved+online; sau khi bật online phải reconnect. Provider nhận `offer.created`, `offer.expired`; người tham gia đơn nhận `order.status_changed`, `provider.location_updated`, `message.created` trong `order:{id}`. REST pending-offers và order-details là fallback. Không cung cấp ETA/tuyến đường qua API hiện tại; PostGIS chỉ tìm gần theo khoảng cách thẳng, không vẽ bản đồ. Với yêu cầu không tốn phí, nhóm Flutter có thể dùng [flutter_map](https://pub.dev/packages/flutter_map) + GPS thiết bị qua [geolocator](https://pub.dev/packages/geolocator) + [socket_io_client](https://pub.dev/packages/socket_io_client); không tự thêm Google Maps API key/billing. Nếu dùng OpenStreetMap tiles, tuân thủ [chính sách tile](https://operations.osmfoundation.org/policies/tiles/) (attribution, user agent, cache, không tải hàng loạt) và không giả định hạ tầng tile công cộng phục vụ lượng truy cập lớn miễn phí. GPS nền trên Android cần quyền/cấu hình riêng; demo foreground trước, không hứa liên tục khi app bị đóng.

## Checklist nghiệm thu trước khi gửi APK

- [ ] UI Khách/Thợ/Admin đã merge, nối hết API cần dùng, không còn Flutter counter starter.
- [ ] Có DB demo riêng, mật khẩu/secret mạnh, không chứa tài khoản seed mật khẩu mẫu; chỉ dữ liệu thử.
- [ ] API qua HTTPS/WSS từ 4G, không dùng localhost; mất mạng/reconnect/offer 15 giây được thử.
- [ ] Đăng ký → duyệt thợ → cập nhật GPS → đặt đơn → giả lập thanh toán → offer → nhận đơn → GPS/chat → tới nơi → mã bắt đầu → hoàn tất giá gốc → ví demo/đánh giá; chạy thêm nhánh hủy/hoàn thử.
- [ ] Các bước **chưa được code** (QR ngân hàng, giá thay đổi/thu bù/hoàn chênh lệch, rút tiền, tranh chấp sau sửa, tiền thật) không quảng cáo là đã chạy.
- [ ] Cài APK release trên máy khác, thử khi laptop bật và khi laptop tắt; thông báo rõ phụ thuộc server.
- [ ] Tắt Funnel sau demo và lưu bản backup DB.
