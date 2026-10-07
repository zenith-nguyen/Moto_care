# MotoCare — demo một laptop, ba vai trò (không dùng tiền thật)

Cập nhật: 2026-10-05. Tài liệu này là **hướng dẫn chuẩn bị**, không phải xác nhận APK đã hoàn thiện. Hiện repo `main` vẫn có Flutter counter starter; Cam Thu/Vy cần merge UI và tích hợp API trước khi có thể phát APK cho thầy.

## Kiến trúc và giới hạn

`APK/Flutter (Khách, Thợ, Admin) → HTTPS/WSS → NestJS trên laptop → PostgreSQL/PostGIS trong Docker trên laptop`. DBeaver chỉ xem DB; Docker không tự nằm trong APK. Nếu laptop tắt/ngủ, mất mạng, NestJS/Docker/Tailscale dừng thì APK của thầy **không dùng được**. Đây là demo không có cam kết 24/7, không phải production. Tuyệt đối không thử chuyển khoản thật.

Để mở API miễn phí cho máy khác mạng, có thể dùng [Tailscale Funnel](https://tailscale.com/docs/features/tailscale-funnel) trên gói [Personal miễn phí](https://tailscale.com/pricing); Funnel hiện được ghi là beta. URL HTTPS của Funnel là *công khai* cho bất kỳ ai có URL. Không mở cổng PostgreSQL 5432 ra Internet. Không dùng Quick Tunnel làm URL gắn cứng cho APK nộp bài vì URL tạm. Tailscale không thay thế việc giữ laptop hoạt động; điều khoản/gói miễn phí có thể thay đổi.

## Điều kiện an toàn trước khi bật Funnel

1. Dùng **database demo riêng**, không dùng DB `motocare` local từng seed bằng mật khẩu mẫu. Sao lưu DB nếu cần. Tạo DB mới, chạy migrations và seed với `DEMO_MODE=true` cùng ba biến `SEED_CUSTOMER_PASSWORD`, `SEED_PROVIDER_PASSWORD`, `SEED_ADMIN_PASSWORD`, mỗi giá trị khác nhau, dài tối thiểu 16 ký tự và không phải mật khẩu mẫu. Seed chỉ tạo user mới, không cập nhật mật khẩu user đã tồn tại; nếu đã seed DB đó bằng mật khẩu mẫu thì tạo DB demo mới, không chỉ chạy seed lại.
2. Đổi `JWT_SECRET` và `DATABASE_PASSWORD` đã từng lộ trong chat/ảnh. Đổi mật khẩu PostgreSQL thực tế qua SQL an toàn rồi cập nhật `.env`; **chỉ sửa `.env` không đổi mật khẩu DB đã được khởi tạo trong Docker volume**. Không gửi giá trị mới vào chat/commit/APK. Chạy API bằng biến môi trường riêng cho demo; không commit `.env`.
3. Bật `DEMO_MODE=true`, giữ `NODE_ENV=development` cho tính năng giả lập. **Đây là sandbox công khai, không có nghĩa là production an toàn**. Không chạy webhook/QR ngân hàng hoặc lấy tiền thật. Tắt Funnel ngay sau buổi demo. Không gửi URL cho người ngoài lớp.
4. `DEMO_MODE=true` sẽ tắt Swagger `/docs`. REST mặc định giới hạn 120 request/phút/client; register 5, login/reset 10, forgot-password 3 và upload chat 20 request/phút trong một NestJS process (không thay thế WAF). Kiểm tra log không có token/secret, backup và phục hồi DB. Nếu demo chat ảnh, backup cả DB lẫn `CHAT_UPLOAD_DIR` (mặc định `storage/chat`); file ảnh không nằm trong DB. Chưa hoàn tất các mục đó ở mốc này thì chỉ demo với nhóm tin cậy trong thời gian ngắn.

## Chuẩn bị DB demo và khởi động

Làm một lần trong PowerShell bình thường tại `mobilecare_1/backend` (không cần Administrator):

```powershell
docker compose up -d
docker compose ps
docker exec motocare-postgres createdb -U motocare motocare_demo
Copy-Item .env.example .env.demo
```

Nếu `createdb` báo database đã tồn tại, **không xóa/ghi đè**; kiểm tra xem DB đó đã có dữ liệu/mật khẩu mẫu chưa, hoặc chọn tên DB demo mới. Mở `.env.demo` (file này được `.gitignore` bỏ qua), chỉnh `DATABASE_NAME=motocare_demo`, `DATABASE_PASSWORD` khớp role PostgreSQL, `DEMO_MODE=true`, `NODE_ENV=development`, ba `SEED_*_PASSWORD` riêng nhau (16+ ký tự) và một `JWT_SECRET` mới dài ít nhất 32 ký tự. Ghi các mật khẩu demo vào password manager riêng; không gửi chat. Trước khi public, đổi mật khẩu **thực tế** của role DB bằng `docker exec -it motocare-postgres psql -U motocare -d motocare`, nhập `\password motocare` trong psql, làm theo hai prompt ẩn mật khẩu, rồi `\q`. Sau đó cập nhật cả `.env` và `.env.demo` nếu còn dùng DB local cũ. Không đặt mật khẩu vào lệnh PowerShell/SQL lưu lịch sử. Sao lưu DB trước khi đổi nếu đang có dữ liệu cần giữ.

Mỗi PowerShell chạy backend/migration/seed cần chọn file config demo trước:

```powershell
$env:DOTENV_CONFIG_PATH = '.env.demo'
npm run migration:run
npm run seed
npm run start:dev
```

Chỉ chạy `npm run seed` **một lần trên DB demo mới**; lần khởi động sau chỉ cần đặt `DOTENV_CONFIG_PATH` rồi chạy `npm run start:dev`. Kiểm tra `http://localhost:3000/health/ready` trên laptop. Trên PowerShell thứ hai, sau khi cài/đăng nhập Tailscale và cho phép Funnel trong trình duyệt theo hướng dẫn chính thức:

```powershell
tailscale funnel 3000
```

Giữ cửa sổ này chạy; ghi lại URL `https://...ts.net` mà lệnh in ra. Thử `https://...ts.net/health/ready` trên điện thoại **khác mạng Wi-Fi** (dùng 4G). Cần thấy `{"status":"ok","database":"ok"}`; điều này chứng minh API và DB truy cập được, **không chứng minh mọi tính năng đã hoạt động**. Sau demo dừng Funnel bằng `Ctrl+C`, kiểm tra lại trạng thái bằng `tailscale funnel status`. Trước khi mở Internet, kiểm tra máy không tự ngủ và Docker container healthy.

Flutter phải nhận API base URL ở lúc build, ví dụ `--dart-define=API_BASE_URL=https://...ts.net`; **không dùng `localhost` hay IP LAN trong APK gửi thầy**. Cả REST và Socket.IO dùng cùng URL; với HTTPS, kết nối WebSocket đi qua WSS. Nếu dùng Flutter web/Admin trên trình duyệt, thêm đúng origin của web vào `CORS_ORIGIN` trên server (các origin cách nhau bằng dấu phẩy), không dùng `*`. Không đưa mật khẩu DB/JWT secret vào `dart-define`. Sau khi UI đã merge, tạo APK release theo [hướng dẫn Flutter Android](https://docs.flutter.dev/deployment/android), cài thử đúng file APK đó trên điện thoại ngoài mạng LAN, không chỉ chạy emulator/debug.

## Ba màn hình trên một laptop

Có thể demo 3 vai trò cùng lúc **khi UI của cả ba đã có**: dùng 1 Android emulator hoặc điện thoại thật cho Khách, một thiết bị/emulator thứ hai cho Thợ và cửa sổ Flutter web/Windows cho Admin nếu UI hỗ trợ web/Windows. Hiện máy đã nhận Windows, Chrome, Edge và có 1 AVD `Medium_Phone` (chưa chạy); phương án thực tế là emulator + hai cửa sổ trình duyệt hoặc điện thoại, **chỉ nếu UI Flutter hỗ trợ web**. Có thể chạy emulator bằng `flutter emulators --launch Medium_Phone` và kiểm tra `flutter devices`. Nếu Admin chỉ có giao diện mobile, cần thiết bị/emulator khác. Máy 16 GB RAM có thể chậm với 3 emulator cùng Docker; nên thử trước. Ba phiên phải đăng nhập tài khoản **khác vai trò**; không dùng cùng JWT. Trình chiếu/mirror từng màn hình chỉ là vấn đề hiển thị, không thay đổi kiến trúc API.

## Hợp đồng API tối thiểu cho nhóm Flutter

| Bước | Khách | Thợ | Admin |
| --- | --- | --- | --- |
| Đăng nhập | `POST /auth/login` | `POST /auth/login` | `POST /auth/login` |
| Khởi tạo | `GET /incident-types`, `POST /orders` | `PATCH /providers/me/location`, `PATCH /providers/me/status` | `GET /admin/providers/pending` |
| Demo trả trước | `POST /payments/demo/orders/:id/confirm` | — | — |
| Nhận đơn | `GET /orders`, `GET /orders/:id` | `GET /orders`, `GET /providers/me/offers/pending`, `POST /orders/:id/offers/:offerId/accept` hoặc `/reject` | `PATCH /admin/providers/:id/approval`, `GET /admin/orders` |
| Theo dõi/chat | `GET /orders/:id`, `GET/POST /orders/:id/messages`, tải ảnh bằng URL có JWT | `PATCH /providers/me/orders/:id/location`, `GET/POST /orders/:id/messages`, tải ảnh bằng URL có JWT | — |
| Tới nơi/bắt đầu | `GET /orders/:id/start-token` (hiện mã cho thợ quét/nhập) | `POST /orders/:id/arrive`, `POST /orders/:id/start` với token | — |
| Giá cuối | Duyệt/từ chối proposal; xác nhận charge sandbox nếu có | Tạo proposal/tranh chấp | Xử lý tranh chấp hoặc refund adjustment |
| Hoàn tất/đánh giá | `GET/POST /orders/:id/reviews` | `POST /orders/:id/complete`, `GET /wallets/me`, `GET/POST /orders/:id/reviews` | — |
| Rút ví sandbox | — | `GET/POST /withdrawals` | `GET /admin/withdrawals/pending`, `PATCH /admin/withdrawals/:id/resolve` |
| Hủy/hoàn giả lập | `POST /orders/:id/cancel` | — | `GET /admin/refunds/pending`, `POST /payments/demo/orders/:id/refund` |

`POST /orders` trả `AWAITING_PREPAYMENT`, không matching trước xác nhận giả lập. `GET /orders/:id` trả payment và vị trí thợ khi đơn active. Token bắt đầu có hiệu lực 5 phút; đây là mã xác nhận gặp mặt, **không phải QR ngân hàng**. Giá cuối có thể bằng/cao/thấp hơn khoản trả trước; charge/refund, ví và rút tiền đều chỉ là ledger sandbox, không chuyển tiền. Trường tiền là decimal string VND, không parse bằng floating-point cho phép tính. Toạ độ PostGIS/JSON GeoPoint là `[longitude, latitude]`, còn request vị trí dùng `{latitude, longitude}`. Cần refresh snapshot bằng REST khi reconnect vì event socket có thể bị bỏ lỡ. Chi tiết màn hình/nút ở [UI_WORKFLOW_CONTRACT.md](UI_WORKFLOW_CONTRACT.md).

Socket.IO handshake `auth: { token, orderId? }`, không để JWT trong URL. `provider:{id}` được join lúc provider kết nối và đã approved+online; sau khi bật online phải reconnect. Provider nhận `offer.created`, `offer.expired`; người tham gia đơn nhận `order.status_changed`, `provider.location_updated`, `message.created` trong `order:{id}`. REST pending-offers và order-details là fallback. Không cung cấp ETA/tuyến đường qua API hiện tại; PostGIS chỉ tìm gần theo khoảng cách thẳng, không vẽ bản đồ. Với yêu cầu không tốn phí, nhóm Flutter có thể dùng [flutter_map](https://pub.dev/packages/flutter_map) + GPS thiết bị qua [geolocator](https://pub.dev/packages/geolocator) + [socket_io_client](https://pub.dev/packages/socket_io_client); không tự thêm Google Maps API key/billing. Nếu dùng OpenStreetMap tiles, tuân thủ [chính sách tile](https://operations.osmfoundation.org/policies/tiles/) (attribution, user agent, cache, không tải hàng loạt) và không giả định hạ tầng tile công cộng phục vụ lượng truy cập lớn miễn phí. GPS nền trên Android cần quyền/cấu hình riêng; demo foreground trước, không hứa liên tục khi app bị đóng.

## Checklist nghiệm thu trước khi gửi APK

- [ ] UI Khách/Thợ/Admin đã merge, nối hết API cần dùng, không còn Flutter counter starter.
- [ ] Có DB demo riêng, mật khẩu/secret mạnh, không chứa tài khoản seed mật khẩu mẫu; chỉ dữ liệu thử.
- [ ] API qua HTTPS/WSS từ 4G, không dùng localhost; mất mạng/reconnect/offer 15 giây được thử.
- [ ] Chạy `npm run backup:check`, `npm run backup:create` và phục hồi thử theo [BACKUP_RESTORE.md](BACKUP_RESTORE.md); cất snapshot ngoài Git và không chia sẻ công khai.
- [ ] Đăng ký → duyệt thợ → cập nhật GPS → đặt đơn → giả lập thanh toán → offer → nhận đơn → GPS/chat chữ + ảnh → tới nơi → mã bắt đầu → giá cuối/thu hoặc hoàn chênh → hoàn tất → ví/yêu cầu rút sandbox/đánh giá; chạy thêm nhánh hủy/hoàn và tranh chấp.
- [ ] Các bước **chưa được code** (QR ngân hàng, webhook SePay, chuyển/hoàn/rút ngân hàng thật) không quảng cáo là đã chạy.
- [ ] Cài APK release trên máy khác, thử khi laptop bật và khi laptop tắt; thông báo rõ phụ thuộc server.
- [ ] Tắt Funnel sau demo và lưu snapshot DB + ảnh chat ở nơi riêng tư.
