# Xác minh hệ thống MotoCare

Tài liệu này tách rõ kiểm thử tự động, smoke-load và thử nghiệm thủ công trên thiết bị. Socket.IO chỉ tăng tốc cập nhật; REST và PostgreSQL vẫn là nguồn dữ liệu chuẩn sau reconnect.

## Cổng chất lượng tự động

Chạy trong `backend/`:

```powershell
npm run lint
npm test
$env:TEST_DATABASE_NAME = 'motocare_orders_test'
npm run test:db
Remove-Item Env:TEST_DATABASE_NAME
npm run build
npm run security:check-files
```

Test HTTP/DB hiện chứng minh vòng đời khách–thợ–admin, matching PostGIS, accept đồng thời, hết hạn offer, chat ảnh có quyền, GPS, giá cuối, hoàn tiền, ví/rút sandbox, đối soát và SePay Test mode đúng amount/idempotent. Unit test SePay kiểm tra raw-body HMAC, payload bị sửa và timestamp replay. Test gateway chứng minh JWT đã bị vô hiệu không thể nối lại, chỉ thợ đã duyệt + online vào room riêng, người ngoài không vào room đơn và từng event đi đúng room.

## Smoke-load laptop demo

Khởi động Docker/PostGIS và API trước, sau đó mở PowerShell thứ hai:

```powershell
cd D:\mobile_app_motocare\mobilecare_1\backend
npm run test:smoke-load
```

Mặc định script gửi 40 request, concurrency 5, chia đều `/health` và `/health/ready`; thất bại nếu có response lỗi hoặc p95 quá 1500 ms. Có thể cấu hình mà không sửa code:

```powershell
$env:SMOKE_BASE_URL = 'http://localhost:3000'
$env:SMOKE_REQUESTS = '100'
$env:SMOKE_CONCURRENCY = '10'
$env:SMOKE_P95_LIMIT_MS = '2000'
npm run test:smoke-load
```

Đây là smoke-load có kiểm soát, không phải chứng nhận production hay stress test. Không chạy vào URL của bên thứ ba khi chưa được phép.

## Reconnect và REST fallback

Khi socket mất kết nối, Flutter không suy đoán event đã bỏ lỡ. Sau reconnect:

1. Khách/thợ gọi `GET /orders/:orderId` để lấy trạng thái, payment và GPS mới nhất.
2. Thợ gọi `GET /providers/me/offers/pending` để lấy offer còn hiệu lực.
3. Hai bên gọi `GET /orders/:orderId/messages` để đồng bộ lịch sử chat.
4. Provider đã bật online phải reconnect socket để join lại `provider:{providerId}`.

## Checklist ba màn hình trước khi demo

- Admin duyệt provider; provider cập nhật GPS, bật online.
- Khách tạo đơn và xác nhận trả trước sandbox; provider nhận đúng offer gần nhất.
- Tắt mạng provider trong vài giây, bật lại và xác minh REST fallback khôi phục offer/order.
- Provider accept, gửi GPS theo đơn; marker khách cập nhật và snapshot REST khớp.
- Hai bên gửi text + ảnh; người ngoài không tải được ảnh.
- Đi hết arrive → start token → final price → complete; ví chỉ được credit một lần.
- Provider tạo rút sandbox; Admin reject một lần và approve một yêu cầu khác; số dư khóa/khả dụng đúng.
- Dashboard và reconciliation khớp đơn vừa demo.

Phần WebSocket mạng thật và Android background GPS phải thử với UI Flutter trên thiết bị; backend unit/HTTP test không thể chứng minh hệ điều hành luôn cấp quyền vị trí hoặc giữ app chạy nền.
