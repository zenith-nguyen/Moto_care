# MotoCare — Bối cảnh dự án (AI đọc trước khi code)

## 1. Dự án

MotoCare là app cứu hộ xe máy lưu động (đồ án môn Tạo app mobile, làm trong khoảng 1 tháng, sản phẩm cuối là APK). Kết nối khách gặp sự cố (hết xăng, xẹp lốp, chết máy, hết bình, va quẹt nhẹ) với thợ sửa lưu động gần nhất. Giá tạm tính minh bạch trước khi xác nhận, theo dõi thợ real-time. Phạm vi: xe máy.

## 2. Vai trò

- Khách hàng: gửi SOS, theo dõi thợ, chat, thanh toán, đánh giá.
- Thợ: nhận/từ chối đơn gần vị trí, xử lý đơn, nhập chi phí phát sinh, xem thu nhập, yêu cầu rút tiền. Phải được Admin duyệt hồ sơ trước khi nhận đơn.
- Admin: duyệt hồ sơ thợ, dashboard thống kê, xử lý khiếu nại, duyệt rút tiền.

## 3. Flow chính (12 bước)

1. Đăng nhập/đăng ký (chọn vai trò).
2. Trang chủ khách (bản đồ + nút SOS).
3. Chọn loại sự cố + giá tạm tính.
4. Gửi yêu cầu, hệ thống tìm thợ.
5. Thợ nhận/từ chối.
6. Theo dõi thợ đến (real-time, ETA).
7. Chat (song song bước 6).
8. Xác nhận bắt đầu bằng QR.
9. Xác nhận giá cuối (thợ nhập phát sinh, khách đồng ý).
10. Thanh toán.
11. Đánh giá 2 chiều.
12. Lưu lịch sử, cập nhật Admin.

Ngoại lệ: không có thợ rảnh -> báo khách, thử lại/mở rộng bán kính; thợ từ chối hoặc không phản hồi -> chuyển thợ kế tiếp; khách hủy giữa chừng -> lưu lý do; thợ nhận rồi hủy -> đơn quay lại tìm thợ khác. Hóa đơn chỉ là summary từ hệ thống, không có giá trị VAT.

## 4. Stack đã chốt

- Mobile: Flutter/Dart (do 2 thành viên FE làm, không thuộc phạm vi backend).
- Backend: NestJS (TypeScript), REST + WebSocket (Socket.io), JWT.
- DB: PostgreSQL + PostGIS. ORM TypeORM + migrations; query địa lý bằng SQL thô (`ST_DWithin`, `ST_Distance`, chỉ mục GiST); không dùng Prisma.
- Push: chưa tích hợp FCM; bản demo ưu tiên Socket.IO + REST polling. Bản đồ Flutter ưu tiên `flutter_map` với nguồn tile tuân thủ chính sách OSM vì yêu cầu không phát sinh phí; Google Maps cần billing nên không tự đưa vào. Đã có adapter QR/webhook SePay Test mode mặc định tắt; thanh toán Live chưa tích hợp.
- Admin: API đã có duyệt thợ, danh sách đơn/refund; UI do Cam Thu/Vy làm.
- Demo không phí: NestJS + Docker/PostGIS trên laptop, HTTPS/WSS công khai tạm qua Tailscale Funnel (cần máy luôn bật). Không dùng Railway/Render trả phí ở mốc này; chưa có server 24/7. Xem `docs/DEMO_RUNBOOK.md`.

## 5. Module backend (NestJS)

`auth`, `users` (khách/thợ/hồ sơ, duyệt thợ), `orders` (tạo đơn, giá tạm tính theo loại sự cố, matching, trạng thái), `realtime` (gateway: vị trí thợ, chat, sự kiện đơn), `payments` (SePay webhook, ví thợ, rút tiền), `reviews`, `admin` (thống kê, duyệt), `common` (DTO, guard, pipe).

## 6. Mô hình dữ liệu

`users` | `providers` | `incident_types` | `orders` | `order_offers` | `order_price_proposals` | `messages` | `reviews` | `payments` | `payment_adjustments` | `wallets` | `wallet_transactions` | `withdrawal_requests`. `orders` giữ snapshot giá cơ bản/thời tiết, giá tạm tính, chi phí thêm, giảm giá và giá cuối. `payments` giữ nguyên khoản trả trước gốc; `payment_adjustments` giữ khoản `CHARGE`/`REFUND` dương để không sửa mất lịch sử.

## 7. Quy tắc nghiệp vụ cốt lõi

- Matching: query PostGIS thợ online + rảnh + đã duyệt trong bán kính X km, gần nhất trước. Gửi đơn cho một thợ tại một thời điểm (bản ghi `order_offers`), chờ 15s. Từ chối/hết giờ -> thợ kế tiếp. Hết thợ -> báo khách. Việc thợ nhận đơn phải atomic (`UPDATE` có điều kiện trạng thái đơn).
- Trạng thái đã chạy trong sandbox: `AWAITING_PREPAYMENT -> PENDING_MATCH -> OFFERED -> ACCEPTED -> ARRIVED -> IN_PROGRESS -> AWAITING_PRICE_APPROVAL -> AWAITING_PAYMENT/PAID -> COMPLETED`; nhánh `PRICE_DISPUTED`, `CANCELLED`, `REFUND_PENDING`, `REFUNDED`.
- Realtime: thợ gửi GPS mỗi 3-5s khi có đơn active qua WebSocket; server đẩy cho khách của đơn đó. Không lưu lịch sử tọa độ, chỉ giữ vị trí hiện tại. Socket phải xác thực JWT và kiểm tra quyền theo đơn.
- QR xác nhận bắt đầu dịch vụ: payload = `orderId + timestamp + HMAC` do server ký; app chỉ hiển thị/quét, thợ gửi lên server verify. Secret HMAC chỉ ở server.
- Quyết định đã chốt: thu giá tạm tính **trước** matching. Nếu không tìm được thợ hoặc hủy trước khi bắt đầu sửa thì hoàn 100%; sau khi bắt đầu, Admin xét từng trường hợp. Khoản tiền thật (khi tích hợp) vào tài khoản MotoCare, **không phải escrow ngân hàng**. SePay webhook đối chiếu mã đơn, số tiền, giao dịch duy nhất; không cộng ví thợ tại lúc nhận tiền, chỉ quyết toán khi hoàn tất và xử lý chênh lệch/tranh chấp.
- Nhánh demo có trả trước, giá cuối, thu thêm/hoàn chênh, ví, tranh chấp và duyệt rút giả lập; không nhận/chuyển/hoàn tiền thật. Adapter SePay Test mode chỉ tạo VietQR mô phỏng cho VA giả `SBSEPAY...` và nhận giao dịch mô phỏng khi được bật chủ động; Live, hoàn/rút ngân hàng và đối soát merchant còn phải review riêng. Không chạy seed mật khẩu mẫu khi mở API công khai. Xem `docs/PROGRESS.md`, `docs/SEPAY_TEST_MODE.md`, `docs/FINAL_PRICE_WORKFLOW.md`, `docs/UI_WORKFLOW_CONTRACT.md` và `docs/DEMO_RUNBOOK.md`.

## 8. Bảo mật

- Secret chỉ ở server (`.env`, GitHub Secrets), không commit, không log, không trả qua API. App không truy cập DB, không tự ký hay verify HMAC.
- Mọi endpoint mặc định cần JWT + guard theo role, trừ auth và webhook (webhook xác thực theo cấu hình SePay). Validate DTO nghiêm ngặt.
- Chạy HTTPS khi deploy, cấu hình CORS đúng. Không bao giờ đưa private key (RSA/HMAC secret) xuống app.

## 9. Repo và quy trình

- Repo: `github.com/zenith-nguyen/Moto_care`; Flutter lives at the repository root and the NestJS backend lives under `backend/`.
- Branches: `main`, `cam-thu`, and `thanh-vy`; all changes go through pull requests and CI.
- Bám tài liệu gốc: 15 màn hình, user flow 12 bước.

## 10. Nguyên tắc cho AI

- Đọc code hiện có trước khi sửa; nêu kế hoạch ngắn trước khi làm việc lớn.
- Ưu tiên đơn giản, làm được trong 1 tháng. Không microservices, không thêm Redis/queue/cache nếu chưa thật sự cần.
- Thay đổi nhỏ, có test cho logic matching và payment; chạy lint + test trước khi báo xong.
- Đổi endpoint thì cập nhật Swagger, vì FE phụ thuộc vào đó.
- Giải thích ngắn gọn logic đi kèm; không commit secret; không ghi đè việc của người khác.

## 11. Còn mở (chưa chốt)

- Chat đã chốt lưu lịch sử DB, phát realtime và có ảnh lưu local được bảo vệ; xem `docs/CHAT_WORKFLOW.md`. Nếu triển khai server 24/7 sau đồ án mới chọn object storage/retention phù hợp.
- Phí nền tảng (nếu có) trừ bao nhiêu khi cộng ví thợ.
- Bán kính tìm thợ mặc định và quy tắc mở rộng.
