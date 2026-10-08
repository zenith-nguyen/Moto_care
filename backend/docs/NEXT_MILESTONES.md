# MotoCare — các mốc sau Prompt C (thiết kế và trạng thái)

Cập nhật: 2026-10-08. Chính sách thu trước và hoàn 100% trước khi sửa **đã được duyệt**. Hệ thống đã có sandbox thanh toán/hoàn, realtime, admin duyệt thợ và adapter SePay Test mode tắt mặc định; chưa có tiền thật hoặc APK hoàn chỉnh. Trạng thái chính xác theo `PROGRESS.md`; hợp đồng Flutter theo `FLUTTER_API_HANDOFF.md`; hướng dẫn demo theo `DEMO_RUNBOOK.md`. Các dòng mô tả triển khai production bên dưới là kế hoạch, không phải chức năng đã chạy.

## Phạm vi và trách nhiệm

- Sản phẩm cuối là APK Android cài trên điện thoại người khác. Cam Thu và Vy phụ trách UI Flutter cho khách, thợ/tài xế và Admin; backend cung cấp API, hợp đồng dữ liệu, xác thực, database, sự kiện realtime và hướng dẫn tích hợp. Việc nối UI phụ thuộc tiến độ của hai bạn.
- APK chỉ chứa ứng dụng và cấu hình URL API, **không chứa PostgreSQL, thông tin đăng nhập DB hay bí mật thanh toán**. Mọi điện thoại gọi cùng một backend HTTPS; backend kết nối tới cùng một PostgreSQL + PostGIS có lưu trữ bền và backup. Không dùng `localhost` làm URL API trong APK phát cho người khác.
- Docker Compose/PostGIS trên máy phát triển tiếp tục phục vụ local. Môi trường public (hosting, domain, DB và chi phí) phải được chọn và tạo riêng; chưa chọn nhà cung cấp hoặc triển khai production.
- Khi deploy: cấu hình biến môi trường bí mật ở server, chạy migration trước khi nhận traffic, không chạy seed dev, kiểm tra HTTPS/API từ điện thoại khác mạng và thử restore backup. `/health` hiện chỉ là liveness của API, chưa kiểm tra DB.

## GPS và bản đồ — mục tiêu đã xác nhận

- Khi thợ online nhưng chưa có đơn: app gửi vị trí qua `PATCH /providers/me/location` mỗi 30–60 giây; matching chỉ dùng vị trí còn mới trong 120 giây (Prompt C đã có).
- Khi thợ đã nhận đơn và đang di chuyển: app gửi GPS khoảng mỗi 3–5 giây khi có quyền vị trí và mạng. Backend xác thực JWT, quyền tham gia đơn và chuyển sự kiện tới `order:{orderId}`. App khách cập nhật marker thợ trên bản đồ (có thể nội suy để chuyển động mượt); marker khách lấy từ vị trí trong đơn. Không chia sẻ GPS thợ cho người ngoài đơn, không lưu lịch sử hành trình mặc định.
- Cần test riêng khi app thợ chuyển sang nền/khóa màn hình: Android yêu cầu quyền và cơ chế chạy nền phù hợp; không cam kết 3–5 giây liên tục khi người dùng tắt định vị, mất mạng hoặc hệ điều hành dừng app.
- `provider:{providerId}` nhận `offer.created`/`offer.expired`; `order:{orderId}` nhận trạng thái đơn, GPS theo đơn và chat. Mất WebSocket thì dùng REST polling; khi kết nối lại lấy snapshot mới để tránh mất sự kiện. Chỉ tính ETA/tuyến đường khi đã chọn giải pháp bản đồ/định tuyến.
- PostGIS giải quyết tìm thợ theo khoảng cách; nó **không vẽ bản đồ**. Chọn SDK/nguồn bản đồ sau khi kiểm tra khóa, chi phí và điều khoản. Google Maps for Flutter hiện yêu cầu tài khoản billing và API key theo tài liệu chính thức: https://developers.google.com/maps/flutter-package/overview.

## Hai QR khác nhau

- QR xác nhận bắt đầu sửa xe: payload ký HMAC để xác nhận người/đơn đúng; **không chuyển tiền**. Vẫn là mốc sau Prompt C.
- QR thanh toán: backend lấy khoản phải thu đã chốt cho đơn để tạo QR ngân hàng với tài khoản nhận, số tiền VND và mã đối soát của đơn. Khách dùng app ngân hàng quét QR trên thiết bị/màn hình khác, hoặc mở deeplink/lưu QR nếu luồng ngân hàng hỗ trợ. MotoCare APK không tự chuyển tiền chỉ bằng cách quét ảnh QR.
- Giá tạm tính lúc đặt có thể khác giá cuối do chi phí phát sinh. Phải định nghĩa khoản thu thêm hoặc hoàn phần chênh trước khi tích hợp tiền thật.

## Quyết định thanh toán — đã chốt chính sách, chỉ code sandbox

Người dùng đã duyệt thu giá tạm tính trước matching: không tìm được thợ hoặc hủy trước khi bắt đầu sửa thì hoàn 100%; sau khi bắt đầu sửa thì Admin xét từng trường hợp. `PROJECT_CONTEXT.md` mục 7 đã cập nhật. SePay Test mode QR/webhook đã có adapter mặc định tắt; ngân hàng Live và hoàn tiền thật vẫn chưa triển khai.

Đề xuất cho bản demo/sandbox:

1. Tạo đơn với giá tạm tính snapshot, mã thanh toán riêng và trạng thái `AWAITING_PREPAYMENT`; chưa gửi offer cho thợ. API trả thông tin QR đúng **giá tạm tính** và hạn thanh toán.
2. Chỉ khi webhook/test-event hợp lệ xác nhận **tiền thật sự đã vào tài khoản nhận** (đúng mã, số tiền, tài khoản, giao dịch chưa xử lý) mới chuyển đơn sang `PENDING_MATCH` và chạy matching. Không tin ảnh chuyển khoản hay client tự báo đã trả.
3. Tiền đã vào tài khoản ngân hàng nhận, **không phải escrow/ủy nhiệm giữ tiền của ngân hàng**. Hệ thống chỉ ghi nhận khoản đã thu nhưng chưa quyết toán/ghi có ví thợ. Không cộng ví thợ tại thời điểm webhook nhận tiền.
4. Nếu hủy trước khi bắt đầu dịch vụ hoặc không tìm được thợ theo chính sách đã chốt: tạo yêu cầu hoàn, giữ trạng thái `REFUND_PENDING`; Admin chuyển khoản hoàn và ghi mã giao dịch chứng minh. Chỉ đánh dấu `REFUNDED` sau khi xác nhận tiền ra. Tự động hoàn tiền chỉ triển khai sau khi xác nhận ngân hàng/tài khoản của nhóm thực sự hỗ trợ API đó; sandbox không chứng minh tài khoản thật được hỗ trợ.
5. Khi giá cuối cao hơn tạm tính: khách xác nhận và trả thêm bằng QR khác; thấp hơn: tạo hoàn phần chênh. Chỉ quyết toán ví thợ sau khi hoàn tất dịch vụ và xử lý tranh chấp theo chính sách. Mọi bước ghi sổ dùng `numeric`, transaction, khóa/idempotency, nhật ký đối soát; webhook gửi lại không được cộng tiền hai lần.
6. Tách rõ thử nghiệm giả lập/SePay sandbox và thanh toán production. Không chạy seed dev, không dùng mật khẩu mẫu hoặc giao dịch tiền thật trong bài test. Cần test hủy trước/sau thanh toán, thanh toán sai/thiếu/thừa, webhook trùng/đến muộn, hoàn một phần và lỗi lúc hoàn.

SePay xác nhận mô hình QR + webhook là báo **tiền đã vào tài khoản**: https://developer.sepay.vn/vi/sepay-webhooks/tao-qr-va-form-thanh-toan. API hoàn tự động của SePay có điều kiện ngân hàng/tài khoản, không thể giả định dùng được cho mọi ngân hàng: https://developer.sepay.vn/vi/sepay-api/v2/hoan-tien/hoan-tien-giao-dich.

Thu trước matching và hoàn 100% trước khi bắt đầu sửa đã được chốt. Trước khi code **tiền thật** còn phải chốt chính sách quyết toán ví thợ, phí nền tảng, xử lý giá chênh lệch/tranh chấp, tài khoản ngân hàng/SePay và cách hoàn tiền ngân hàng thực sự hỗ trợ. Cần backend HTTPS public đáng tin cậy cho webhook thật. Không lưu số tài khoản, token hay secret trong repo.

## Thứ tự triển khai đề xuất

1. Hoàn thiện test HTTP/CI và bàn giao API Flutter; migration/test trên DB riêng. Bản không phí chạy trên laptop với Tailscale Funnel theo `DEMO_RUNBOOK.md`, không có uptime khi laptop tắt. Không dùng môi trường này cho tiền thật.
2. Cam Thu/Vy merge UI và nối API contract; trải nghiệm đầu tiên dùng REST polling, sau đó realtime Socket.IO, GPS/marker Flutter. Bản đồ ưu tiên nguồn không cần billing nhưng vẫn tuân thủ chính sách tile.
3. Test APK release ở 4G và ba vai trò đồng thời; kiểm tra mất mạng/kết nối lại, từ chối GPS, offer hết hạn, laptop ngủ/tắt, backup và phục hồi.
4. Sau demo: thay ledger sandbox bằng QR/webhook/thu bù/hoàn/rút ngân hàng **thật** là milestone riêng, không được xem là đã xong chỉ vì giá cuối, tranh chấp và withdrawal sandbox chạy.
