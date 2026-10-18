# Dịch vụ thật và các bước kích hoạt cục bộ

Cập nhật: 2026-10-18. Tài liệu này phân biệt rõ phần đã chạy thật trong code,
phần cần tài khoản/credential của chủ dự án và phần tài chính chưa được phép bật.
Không chép secret vào Git, APK, ảnh chụp hoặc tin nhắn nhóm.

## Ma trận hiện trạng

| Hạng mục | Trong code | Cần thao tác ngoài |
| --- | --- | --- |
| GPS khách/thợ | GPS thiết bị thật qua `geolocator`; thợ phát vị trí theo đơn qua Socket.IO | Cấp quyền vị trí trên từng máy; đặt vị trí giả cho emulator nếu test |
| Bản đồ | OpenStreetMap thật là mặc định miễn phí; Google Maps là adapter tùy chọn | Cần Internet để tải tile; Google Maps chỉ bật khi có project, billing và API key bị giới hạn |
| Thời tiết | Backend gọi Open-Meteo theo tọa độ thật, cache và snapshot giá lúc tạo đơn | Đặt `WEATHER_PRICING_ENABLED=true`; giữ attribution trên UI |
| Trạm dịch vụ | Marker từ snapshot OpenStreetMap TP.HCM trong PostGIS; viewport/nearby là API thật | Chạy import lại khi cần làm mới snapshot; OSM không bảo đảm đủ phone, giờ mở cửa hay rating |
| Hồ sơ khách | Tên, phone, liên hệ khẩn cấp, ghi chú y tế, nhà/cơ quan lưu PostgreSQL | Chạy migration mới trước khi test |
| Email quên mật khẩu | SMTP thật, fail-fast khi credential sai | Chủ dự án tạo Gmail demo + 2FA + App Password và nhập vào `.env` cục bộ |
| Backend công khai | REST và Socket.IO dùng chung HTTPS/WSS URL | Cài/đăng nhập Tailscale, chạy Funnel và giữ laptop + Docker + API luôn bật |
| Thanh toán | Luồng nghiệp vụ, QR/webhook HMAC/idempotency hiện chỉ an toàn ở SePay Test mode | Live cần tài khoản SePay/ngân hàng, webhook HTTPS và một adapter Live được review riêng; không bật bằng cách sửa một biến |

## Bật hồ sơ lưu thật

Sau khi nhánh này được merge, tại `backend`:

```powershell
npm run migration:run
npm run start:dev
```

Đăng nhập lại, sửa hồ sơ rồi đóng/mở app. `GET /users/me` phải trả lại đúng dữ
liệu. Avatar và tùy chọn sinh trắc học vẫn thuộc thiết bị/phiên, chưa upload qua
endpoint này.

## Bật email thật

Làm theo `backend/docs/NOTIFICATIONS_EMAIL.md`. App Password phải được tạo và
nhập trực tiếp trên máy chạy backend. Sau khi cấu hình:

```powershell
cd D:\mobile_app_motocare\mobilecare_1\backend
npm run email:check
$env:SMTP_TEST_RECIPIENT='dia-chi-cua-ban@example.com'
npm run email:test
Remove-Item Env:SMTP_TEST_RECIPIENT
npm run start:dev
```

Không gửi App Password cho coding agent; code không cần biết giá trị để tích hợp.

## Công khai backend miễn phí cho APK

Làm checklist secret/database trong `backend/docs/DEMO_RUNBOOK.md`, cài và đăng
nhập Tailscale, rồi mở PowerShell riêng:

```powershell
tailscale funnel 3000
```

Kiểm tra `https://<ten-may>.<tailnet>.ts.net/health/ready` bằng 4G. Build APK với:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://<ten-may>.<tailnet>.ts.net
```

Funnel không biến laptop thành hosting 24/7: APK mất backend khi laptop ngủ/tắt,
Docker/API dừng hoặc mạng nhà mất. Không public cổng PostgreSQL `5432`.

## GPS và bản đồ trên emulator

Emulator không biết vị trí thật của laptop. Trong cửa sổ Android Emulator mở
`...` → **Location**, nhập tọa độ TP.HCM và bấm **Set location**; trong Android
Settings cấp quyền Location cho MotoCare. Điện thoại thật sẽ dùng GPS của chính
điện thoại sau khi người dùng đồng ý quyền.

OpenStreetMap trong app chỉ là nền bản đồ. Tìm kiếm địa chỉ bằng Google Places
vẫn cần Google credential/billing; khi chưa bật, người dùng có thể dùng GPS và
di chuyển ghim. Không scrape Google Maps. Dữ liệu trạm dùng snapshot OSM và API
PostGIS của MotoCare.

## Cổng kiểm soát trước thanh toán Live

Không đưa tiền thật qua adapter Test hiện tại. Nhánh Live riêng chỉ được merge
khi có đủ: tài khoản SePay chính chủ, account mapping, webhook HTTPS, HMAC/IP
allowlist, replay/idempotency, đối soát, quy trình hoàn tiền thực tế, audit log
không chứa bí mật, test số tiền nhỏ và xác nhận pháp lý/ngân hàng. Hoàn tiền tự
động phụ thuộc ngân hàng/tài khoản hỗ trợ; nếu chưa đáp ứng, Admin xử lý hoàn thủ
công có bằng chứng thay vì báo sai là tự động.

