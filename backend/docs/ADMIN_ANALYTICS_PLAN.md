# MotoCare — Admin dashboard và đối soát

Cập nhật: 2026-10-06. API đã được triển khai trên nhánh `feat/zenith/admin-analytics` và đang chờ review/merge. Bản đầu chỉ tổng hợp dữ liệu sandbox hiện có; không trình bày là tiền ngân hàng thật.

## Mục tiêu

Admin cần nhìn nhanh tình trạng người dùng, thợ, đơn cứu hộ và dòng tiền; đồng thời có bảng chi tiết để kiểm tra vì sao một con số được tính. Dashboard không tự cộng từ UI: backend trả số liệu đã định nghĩa nhất quán theo cùng khoảng thời gian.

## API

- `GET /admin/dashboard/summary?from=<ISO>&to=<ISO>`: thẻ tổng quan và snapshot hiện tại.
- `GET /admin/dashboard/timeseries?from=<ISO>&to=<ISO>&bucket=day`: số đơn và số tiền theo ngày để vẽ biểu đồ.
- `GET /admin/reconciliation?from=<ISO>&to=<ISO>&status=<...>&page=1&limit=50`: từng order/payment/wallet transaction để đối chiếu, có phân trang.

Mặc định ngày được hiểu theo `Asia/Ho_Chi_Minh`; response luôn trả lại `from`, `to` và timezone thực tế. Mặc định lấy 7 ngày, tối đa 366 ngày để tránh query quá nặng trên laptop demo. `from` là inclusive và `to` là exclusive.

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

- `collectedInPeriod`: tổng payment đã từng thu trong kỳ theo `paid_at`, kể cả khoản sau đó được hoàn.
- `heldCurrent`: payment hiện đã thu nhưng order chưa hoàn tất hoặc chưa hoàn; đây là tiền đang giữ, không phải doanh thu.
- `settledToProvidersInPeriod`: tổng wallet transaction `CREDIT` trong kỳ.
- `refundPendingCurrent`: tổng payment hiện đang `REFUND_PENDING`.
- `refundedInPeriod`: tổng payment đã hoàn trong kỳ theo `refunded_at`.
- `grossCompletedValueInPeriod`: tổng `final_price` gắn với wallet credit trong kỳ.
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
- Test database/HTTP kiểm tra quyền Admin, khoảng ngày, từng trạng thái payment/order, số tiền decimal, phân trang, dữ liệu sạch và cờ bất thường.
- Swagger và [API_CATALOG.md](API_CATALOG.md) là hợp đồng cho Flutter; CI phải xanh trước khi merge.
