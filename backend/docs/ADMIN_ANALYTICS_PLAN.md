# MotoCare — kế hoạch Admin dashboard và đối soát

Cập nhật: 2026-10-06. Đây là kế hoạch cho milestone kế tiếp, chưa phải API đã triển khai. Bản đầu chỉ tổng hợp dữ liệu sandbox hiện có; không trình bày là tiền ngân hàng thật.

## Mục tiêu

Admin cần nhìn nhanh tình trạng người dùng, thợ, đơn cứu hộ và dòng tiền; đồng thời có bảng chi tiết để kiểm tra vì sao một con số được tính. Dashboard không tự cộng từ UI: backend trả số liệu đã định nghĩa nhất quán theo cùng khoảng thời gian.

## API dự kiến

- `GET /admin/dashboard/summary?from=<ISO>&to=<ISO>`: thẻ tổng quan trong khoảng thời gian.
- `GET /admin/dashboard/timeseries?from=<ISO>&to=<ISO>&bucket=day`: số đơn và số tiền theo ngày để vẽ biểu đồ.
- `GET /admin/reconciliation?from=<ISO>&to=<ISO>&status=<...>&page=1&limit=50`: từng order/payment/wallet transaction để đối chiếu, có phân trang.

Mặc định ngày được hiểu theo `Asia/Ho_Chi_Minh`; response luôn trả lại `from`, `to` và timezone thực tế. Khoảng thời gian bị giới hạn để tránh query quá nặng trên laptop demo.

## Nhóm chỉ số

### Tài khoản và thợ

- Tổng `users`, số `CUSTOMER`, `PROVIDER`, `ADMIN`.
- Thợ theo `PENDING`, `APPROVED`, `REJECTED`; số đang online và số có vị trí còn mới.

### Đơn cứu hộ

- Tổng đơn trong kỳ và số lượng theo từng `OrderStatus`.
- Số hoàn tất, hủy, chờ hoàn; tỷ lệ hoàn tất tính từ tập đơn đã đóng.
- Thời gian từ tạo đơn tới thợ nhận và từ nhận tới hoàn tất chỉ thêm khi schema có timestamp đủ tin cậy; không suy diễn từ `updated_at`.

### Tiền

Mọi số tiền là chuỗi decimal VND, tính bằng PostgreSQL `numeric`, không chuyển sang JavaScript `number`:

- `collected`: tổng payment `PAID`/đã từng thu trong kỳ.
- `held`: payment đã thu nhưng order chưa hoàn tất hoặc chưa hoàn; đây là tiền đang giữ, không phải doanh thu.
- `settledToProviders`: tổng wallet transaction `CREDIT` gắn với order hoàn tất.
- `refundPending`: tổng payment đang `REFUND_PENDING`.
- `refunded`: tổng payment `REFUNDED` theo thời điểm hoàn.
- `grossCompletedValue`: tổng `final_price` của order hoàn tất.
- Chưa có `platformRevenue` cho đến khi nhóm chốt phí nền tảng; không lấy `collected` làm doanh thu MotoCare.

## Đối soát

Mỗi dòng đối soát gồm order code/status, customer/provider, payment id/status/amount, thời điểm thu-hoàn, wallet credit liên quan và cờ bất thường. Các cờ tối thiểu:

- Đơn hoàn tất nhưng thiếu payment đã thu.
- Payment đã thu nhưng số tiền khác giá cuối.
- Đơn hoàn tất nhưng thiếu hoặc trùng wallet credit.
- Payment chờ hoàn nhưng order không ở trạng thái chờ hoàn.
- Đã hoàn nhưng vẫn có wallet credit chưa đảo (khi nghiệp vụ đảo ví được triển khai).

## Kỹ thuật và kiểm thử

- Chỉ role `ADMIN`; DTO kiểm tra ISO date, `from < to`, limit và enum filter.
- Aggregate bằng SQL/query builder; dùng `COALESCE` và ép kết quả tiền về string.
- Thêm index theo thời gian/trạng thái chỉ khi `EXPLAIN` chứng minh cần; không tạo index trùng với index hiện có.
- Test database cho ranh giới ngày theo múi giờ, từng trạng thái payment/order, số tiền decimal, phân trang và quyền truy cập.
- Swagger và [API_CATALOG.md](API_CATALOG.md) chỉ được đánh dấu “đã có” sau khi test/CI qua.
