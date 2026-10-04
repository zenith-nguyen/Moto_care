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
- Push: Firebase Cloud Messaging. Bản đồ: Google Maps. Thanh toán: SePay webhook.
- Admin web: React (làm mỏng, ưu tiên thấp).
- Deploy: Railway hoặc Render (HTTPS). Local: docker-compose (`postgis/postgis`).

## 5. Module backend (NestJS)

`auth`, `users` (khách/thợ/hồ sơ, duyệt thợ), `orders` (tạo đơn, giá tạm tính theo loại sự cố, matching, trạng thái), `realtime` (gateway: vị trí thợ, chat, sự kiện đơn), `payments` (SePay webhook, ví thợ, rút tiền), `reviews`, `admin` (thống kê, duyệt), `common` (DTO, guard, pipe).

## 6. Mô hình dữ liệu

`users` (id, role, phone/email, password_hash, name, status) | `providers` (user_id, is_online, approval_status, current_location geography Point, last_seen_at, giấy tờ/hồ sơ) | vehicles của khách (tùy chọn) | `incident_types` (code, tên, giá cơ bản) | `orders` (id, code, customer_id, provider_id, incident_type_id, status, customer_location geography, estimated_price, extra_cost, final_price, cancel_reason, cancelled_by, timestamps) | `order_offers` (order_id, provider_id, status, offered_at, expires_at) | `messages` (order_id, sender_id, content, image_url) | `reviews` (order_id, reviewer_id, reviewee_id, rating, comment) | `payments` (order_id, amount, sepay_transaction_id UNIQUE, status, paid_at) | `wallets` (provider_id, balance) | `wallet_transactions` (wallet_id, type, amount, order_id/withdrawal_id, created_at) | `withdrawal_requests` (provider_id, amount, status PENDING/APPROVED/REJECTED, processed_by, processed_at).

## 7. Quy tắc nghiệp vụ cốt lõi

- Matching: query PostGIS thợ online + rảnh + đã duyệt trong bán kính X km, gần nhất trước. Gửi đơn cho một thợ tại một thời điểm (bản ghi `order_offers`), chờ 15s. Từ chối/hết giờ -> thợ kế tiếp. Hết thợ -> báo khách. Việc thợ nhận đơn phải atomic (`UPDATE` có điều kiện trạng thái đơn).
- Trạng thái đơn: `PENDING_MATCH -> OFFERED -> ACCEPTED -> ARRIVED -> IN_PROGRESS -> AWAITING_PAYMENT -> PAID -> COMPLETED`; nhánh `CANCELLED` lưu lý do, bên hủy.
- Realtime: thợ gửi GPS mỗi 3-5s khi có đơn active qua WebSocket; server đẩy cho khách của đơn đó. Không lưu lịch sử tọa độ, chỉ giữ vị trí hiện tại. Socket phải xác thực JWT và kiểm tra quyền theo đơn.
- QR xác nhận bắt đầu dịch vụ: payload = `orderId + timestamp + HMAC` do server ký; app chỉ hiển thị/quét, thợ gửi lên server verify. Secret HMAC chỉ ở server.
- Thanh toán: MotoCare nhận tiền. Khách chuyển khoản vào tài khoản MotoCare, nội dung = mã đơn. SePay webhook đối chiếu mã đơn + số tiền -> đơn `PAID` (idempotent theo `sepay_transaction_id`) -> cộng ví thợ (trừ phí nền tảng nếu có). Rút tiền được Admin duyệt và chuyển khoản tay ngoài hệ thống. Mọi thay đổi số dư dùng DB transaction.
- **Đang xem xét thay đổi** sang thu giá tạm tính trước khi matching, giữ khoản đã thu trên sổ hệ thống và hoàn khi hủy; không nhầm với escrow tại ngân hàng. Chưa code/chưa chốt chính sách, xem `docs/NEXT_MILESTONES.md` trước khi làm payment.

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

- Chat có lưu DB lịch sử hay chỉ realtime.
- Phí nền tảng (nếu có) trừ bao nhiêu khi cộng ví thợ.
- Bán kính tìm thợ mặc định và quy tắc mở rộng.
