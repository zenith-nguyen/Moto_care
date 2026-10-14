# MotoCare Backend — Trạng thái hiện tại

Cập nhật lần cuối: 2026-10-12

## Đã xong

- Prompt A: NestJS, Auth JWT/argon2, RolesGuard, Swagger, health; migration PostGIS và users. Đã thử đăng ký, đăng nhập, `/users/me`.
- Prompt B: 11 bảng lõi (users, providers, incident_types, orders, order_offers, messages, reviews, payments, wallets, wallet_transactions, withdrawal_requests); migration, seed local, index GiST, tiền `numeric`, test truy vấn `ST_DWithin`.
- Prompt C (đã merge PR #5): loại sự cố, GPS/online của thợ, tạo đơn, matching PostGIS, accept/reject, offer 15 giây, job hết hạn 5 giây, retry, REST polling, khóa dòng + unique index chống nhận trùng. CI/lint/test đã xanh khi merge.
- PR #7 đã merge vào `main`: API admin duyệt thợ; demo trả trước/hoàn 100% giả lập; hủy trước khi bắt đầu; chat lưu DB; Socket.IO offer/trạng thái/GPS/chat; tới nơi/mã bắt đầu/hoàn tất đúng giá gốc; ví demo và đánh giá hai chiều; `/health/ready` kiểm tra DB; hướng dẫn demo một laptop. Migration local đã chạy đủ 6 bản; Docker/PostGIS và readiness đã kiểm tra OK ngày 2026-10-05. Đây vẫn là sandbox, không phải thanh toán thật.
- PR #8 đã merge vào `main`: test HTTP xuyên suốt ba vai trò, PostGIS test trong CI và hợp đồng tích hợp Flutter. Mốc merge đã qua 25 database/HTTP tests, 5 unit tests, lint, build, audit và Flutter checks.
- PR #9 đã merge vào `main`: chat nhận text/ảnh JPEG-PNG-WebP tối đa 5 MiB, lưu file local ngoài public web root, metadata trong DB, URL tải có JWT/quyền theo đơn, realtime payload có ảnh, và lịch sử đọc được sau khi đơn đóng. Đã thêm catalog API và backlog non-functional; migration upload là `0006`.
- PR #10 đã merge vào `main`: quên/đặt lại mật khẩu bằng mã email dùng một lần, khóa tạm sau đăng nhập sai và vô hiệu JWT cũ cho REST/Socket sau reset; migration `0007`. CI Backend, Flutter và branch policy đều xanh.
- PR #11 đã merge vào `main`: dashboard Admin, chuỗi thời gian và đối soát order/payment/wallet; bộ lọc thời gian, phân trang, decimal strings và cờ bất thường. Mốc merge đã qua 9 unit tests, 28 database/HTTP tests, lint và build.
- PR #12 đã merge vào `main`: request ID, log JSON không chứa query/body/header, response lỗi an toàn, Helmet, CORS không wildcard, rate limit REST/auth/upload, giới hạn multipart/socket, secret HMAC tách biệt và CI chặn file/chuỗi nhạy cảm. Mốc merge đã qua 15 unit tests, 28 database/HTTP tests, lint, build và production audit không có lỗ hổng đã biết.
- PR #13 đã merge vào `main`: kiểm tra dung lượng, snapshot PostgreSQL + ảnh chat + checksum và restore có chốt an toàn. Đã phục hồi độc lập và xác nhận 8 migrations / 6 users / 5 incident types; readiness `200`, DB restore thử đã xóa.
- PR #15 đã merge vào `main`: weather pricing snapshot với Open-Meteo cache/timeout/fallback, tính tiền bằng `BigInt`, migration `0008`, breakdown cho Swagger/Flutter; mặc định tắt.
- PR #16 đã merge vào `main`: proposal giá cuối, khách duyệt/từ chối, tranh chấp Admin, charge/refund adjustment sandbox, đối soát và wallet credit theo giá cuối; migration `0009–0010`, CI xanh.
- PR #17 đã merge vào `main`: rút tiền sandbox atomic, `lockedBalance`/`availableBalance`, một yêu cầu chờ mỗi ví, Admin duyệt/từ chối và debit duy nhất; migration `0011`, CI xanh.
- PR #18 đã merge vào `main`: test bảo mật/room/event Socket.IO, smoke-load REST chỉ đọc và checklist reconnect/REST fallback/ba màn hình; 28 unit, 35 PostgreSQL/PostGIS/HTTP tests và CI xanh.
- PR #19 đã merge vào `main`: đồ thị state transition tập trung, tách Orders query/presenter khỏi command service và tài liệu modular monolith; giữ nguyên 51 Swagger operation/schema, CI xanh.
- PR #20 đã merge vào `main`: application service phát event qua `RealtimePublisher`; Socket.IO gateway chỉ là adapter, không đổi event/room/payload/API; CI xanh.
- PR #21 đã merge vào `main`: Orders dùng port do Payments sở hữu; prepayment, refund, adjustment, wallet credit và ledger đã về payment adapter nhưng vẫn dùng chung transaction/row lock; API/schema không đổi, CI xanh.
- PR #24 đã merge vào `main`: strict typecheck cho `src + test`, Jest mocks có kiểu cụ thể và Backend CI bắt buộc `npm run typecheck`; 51 unit tests ở mốc nhánh tiếp theo vẫn xanh.
- PR #25 đã merge vào `main`: adapter SePay **Test mode** mặc định tắt, VietQR mô phỏng có `simulationOnly=true`, xác thực webhook HMAC raw-body/timestamp, chống replay/idempotency, audit tối thiểu và migration `0012`. Migration local đã xác nhận đủ 13 bước và bảng `sepay_webhook_events` tồn tại; `/health` và `/docs` trả `200` ngày 2026-10-08.
- PR #27 đã merge vào `main`: nền Flutter dùng cấu hình API build-time, Dio/Bearer/request ID, secure token, session `/users/me`, role routing, lỗi an toàn, tiền decimal và client SePay Test mode chỉ nhận QR mô phỏng. 16 Flutter tests, analyze và APK debug/release đã xanh ở mốc nhánh.
- PR #29 đã merge vào `main`: Flutter Socket.IO dùng chung session/API origin, JWT chỉ nằm trong handshake auth, typed event cho offer/order/GPS/chat, private provider/order scope, reconnect yêu cầu REST resync và cleanup khi logout. Analyze, 24 tests, APK debug và CI đều xanh.
- PR #30 đã merge vào `main`: Flutter Customer core có incident catalog, tạo/danh sách/chi tiết đơn, snapshot giá thời tiết/GPS/payment, retry/cancel, SePay Test QR và xác nhận thanh toán sandbox; tiền decimal nghiêm ngặt và realtime luôn đồng bộ lại qua REST. 37 tests, APK debug và CI xanh.
- PR #31 đã merge vào `main`: Flutter Customer service có chat text/ảnh bảo vệ, realtime de-duplicate/resync, mã bắt đầu sửa, duyệt/từ chối giá cuối và đánh giá. 52 tests, analyze, APK và CI xanh.
- PR #32 đã merge vào `main`: Flutter Provider service có online/offline, GPS chờ đơn và theo đơn, offer, vòng đời cứu hộ, giá cuối/tranh chấp, ví và rút tiền sandbox; realtime chỉ báo hiệu và REST resync là nguồn chuẩn. 59 tests, analyze, APK và CI xanh.
- PR #33 đã merge vào `main`: Flutter Admin có dashboard/timeseries, đối soát, duyệt thợ, tranh chấp, hoàn tiền và rút tiền sandbox; quyết định tài chính không tự retry. 67 tests, analyze, APK và CI xanh. Nền repository/controller cho cả ba vai trò đã hoàn tất.
- PR #34 đã merge vào `main`: Flutter có GPS foreground cho thợ ở trạng thái chờ/đang làm đơn và chọn ảnh chat từ camera/thư viện với kiểm tra dung lượng/chữ ký; không xin quyền vị trí nền.
- PR #35 đã merge vào `main`: sửa hồ sơ tên/điện thoại an toàn, CRUD xe Customer, snapshot xe vào order và endpoint bấm Gọi chỉ cho hai người tham gia đơn active; CI Backend/Flutter/branch policy đều xanh.
- PR #36 đã merge vào `main`: hồ sơ nghề nghiệp, skill claim/xác minh, tier chỉ Admin sửa, thống kê tuần tính từ dữ liệu nguồn; `service_locations` PostGIS và importer snapshot OSM TP.HCM. Lần chạy local ngày 2026-10-11 import 482 marker có tên (127 repair, 9 charging, 328 fuel, 18 parts); GiST được xác nhận bằng `EXPLAIN`.
- Nhánh `feat/zenith/notifications-email` đã hoàn tất chờ PR: Gmail SMTP thật có kiểm tra credential/fail-fast; notification inbox bền vững; Firebase Cloud Messaging qua Admin SDK/ADC; đăng ký, rotation và revoke token theo installation; delivery worker có `SKIP LOCKED`, retry/backoff và vô hiệu token chết; thông báo offer/trạng thái đơn/chat/thợ ở gần; Flutter push foundation và inbox controller. Đã qua 59 unit tests backend, 44 PostgreSQL/PostGIS/HTTP tests, 78 Flutter tests, lint, strict typecheck, build backend, Flutter analyze, APK debug, secret scan và production audit 0 vulnerability. Migration hiện có 18 bước.

## Đang làm / Tiếp theo

1. Mở và merge PR của nhánh `feat/zenith/notifications-email`; sau đó chạy migration `0016–0017` trên DB demo.
2. Chủ repo cấu hình Gmail App Password và Firebase Spark/ADC theo [NOTIFICATIONS_EMAIL.md](NOTIFICATIONS_EMAIL.md), rồi chạy bốn lệnh kiểm tra thật `email:check`, `email:test`, `push:check`, `push:test`. Không commit/chụp/gửi credential.
3. PR #22 UI Customer sẽ được đóng và team UI sẽ mở PR mới từ `main`; không merge lại nhánh cũ conflict/generated duplicate. Khi PR mới sẵn sàng, tích hợp từng màn hình theo [UI integration guardrails](../../docs/UI_INTEGRATION_GUARDRAILS.md).
4. Sau khi UI Customer/Provider/Admin sạch và ổn định: nối profile/vehicles, service-location marker, order/realtime/chat/notification vào repository/controller hiện có; không giữ mock làm nguồn dữ liệu runtime.
5. Test ba vai trò end-to-end trên thiết bị thật: vòng đời đơn, offer hết hạn, GPS/reconnect, chat ảnh, push nền, email reset, giá cuối, thanh toán/hoàn tiền/rút tiền sandbox và các hàng đợi Admin.
6. Hoàn thiện release signing cục bộ, DB demo tách biệt, secret rotation và HTTPS/WSS Funnel; chạy checklist thiết bị thật trước khi tạo APK nộp bài.
7. Chủ repo có thể tạo webhook SePay Test mode theo [SEPAY_TEST_MODE.md](SEPAY_TEST_MODE.md); tuyệt đối chưa bật Live. Thanh toán Live còn thiếu quy trình merchant, hoàn tiền thật và đối soát ngân hàng định kỳ; adapter hiện cố ý chỉ chấp nhận `SEPAY_MODE=test`.
8. Tiếp theo backend sau mốc thiết bị thật: marketplace/phụ tùng read-only catalog; checkout/stock/payment chỉ làm sau khi chốt delivery/refund và payment purpose riêng.

## Quyết định đã chốt

- PostgreSQL + PostGIS, TypeORM migration thủ công; không `synchronize`.
- POI TP.HCM dùng snapshot OpenStreetMap import thủ công, không scrape Google Maps, không yêu cầu API key/billing. OSM rows mặc định không verified/partner và chỉ để hiển thị marker.
- Tier và xác minh kỹ năng thuộc quyền Admin. Thống kê tuần của thợ được tính từ order/review/wallet, không lưu counter có thể lệch.
- Tất cả tiền `numeric`/`decimal`, không float; vị trí `geography(Point,4326)` có GiST.
- Thu trước giá tạm tính rồi mới matching. Không tìm được thợ hoặc hủy trước khi sửa: hoàn 100%; sau khi bắt đầu sửa: Admin xét từng trường hợp. Thu/hoàn **thực** cần xác nhận ngân hàng/SePay, không tự giả định có escrow hoặc API hoàn tự động. Bản hiện tại chỉ sandbox, không nhận/chuyển tiền.
- Provider online gửi REST GPS 30–60 giây; matching chỉ dùng vị trí trong 120 giây, bán kính mặc định 10 km. Khi có đơn có thể gửi GPS theo đơn vài giây/lần; socket đẩy tới người tham gia và REST là fallback.
- UI Flutter do Cam Thu/Vy phụ trách; backend/DB chạy trên laptop khi demo không nằm trong APK. Không dùng `localhost` trong APK gửi người khác. Ưu tiên giải pháp không mất phí, nhưng miễn phí không đồng nghĩa uptime/băng thông không giới hạn.
- `wallet_transactions.amount` dương; chiều cộng/trừ suy từ `type`. Không seed mật khẩu mẫu ra môi trường công khai.
- Chat dùng PostgreSQL cho lịch sử/metadata, Socket.IO để báo realtime, REST để đồng bộ lại. Ảnh lưu local có URL bảo vệ; backup DB phải đi kèm backup thư mục ảnh.
- Secret public/production tách theo mục đích: JWT, HMAC mã bắt đầu sửa và HMAC mã reset mật khẩu; không đưa vào Flutter. Webhook thanh toán thật phải xác thực chữ ký raw body, chống replay và idempotent trước khi được mở.
- Adapter SePay đầu tiên chỉ hỗ trợ Test mode, mặc định tắt và từ chối mọi account không đúng VA giả `SBSEPAY` + 12 chữ/số. Flutter chỉ nhận chỉ dẫn QR có `simulationOnly=true`; `SEPAY_WEBHOOK_SECRET` không bao giờ đi xuống app. Transaction webhook chỉ áp dụng một lần khi account/code/amount/status cùng khớp.
- Email khôi phục dùng Gmail SMTP thật khi môi trường có App Password; push dùng FCM Spark + Firebase Admin ADC. Hai adapter fail-closed/mặc định tắt trên máy/CI chưa có credential, nhưng không có mock delivery khi đã bật. Socket.IO + REST inbox vẫn hoạt động độc lập khi FCM bị gián đoạn.

## Không dùng nữa / ghi chú vận hành

- `D:\mobile_app_motocare\motocare-backend` đã bỏ; backend chính là `mobilecare_1/backend`.
- `.env` không commit. Đổi JWT secret/DB password nếu từng hiện trong chat/ảnh; chỉ sửa `.env` không đổi password role trong PostgreSQL volume.
- Chạy local theo [README.md](../README.md); trước khi mở Funnel làm checklist trong [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md).
