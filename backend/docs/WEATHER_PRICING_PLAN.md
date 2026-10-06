# MotoCare Backend — kế hoạch giá theo thời tiết

Cập nhật: 2026-10-06. Trạng thái: **mới chốt thiết kế, chưa áp dụng vào giá đơn hàng**.

Hiện `estimated_price` vẫn là snapshot `incident_types.base_price`. Không được mô tả bản hiện tại là đã tự động tăng giá khi mưa/gió.

## Nguồn dữ liệu cho bản demo không thu phí

Dự kiến backend gọi Open-Meteo theo vị trí khách. API có dữ liệu mưa, lượng mưa, mã thời tiết, tốc độ gió và gió giật. Gói miễn phí chỉ phù hợp mục đích phi thương mại/giáo dục, có giới hạn sử dụng, yêu cầu ghi nguồn và không cam kết uptime; nếu dự án chuyển sang thương mại phải đánh giá lại giấy phép/gói dịch vụ.

- Tài liệu biến thời tiết: <https://open-meteo.com/en/docs>
- Điều khoản và giới hạn miễn phí: <https://open-meteo.com/en/terms>
- Chính sách gói dịch vụ: <https://open-meteo.com/en/pricing>

## Thiết kế dự kiến

1. Chỉ backend gọi nhà cung cấp thời tiết; không nhúng khóa hay logic giá trong Flutter.
2. Lấy thời tiết tại vị trí khách khi tạo đơn, có timeout ngắn. Nếu dịch vụ lỗi/chậm, dùng hệ số `1.00` để việc cứu hộ không bị chặn.
3. Cache theo ô tọa độ làm tròn và khoảng thời gian ngắn để tránh gọi lặp; không gọi theo mỗi lần GPS di chuyển.
4. Snapshot giá đúng một lần lúc tạo đơn. Thời tiết đổi sau đó không tự đổi số tiền khách đã thấy.
5. Dự kiến ba mức dễ giải thích: bình thường `1.00`, mưa/gió vừa `1.10`, thời tiết nặng `1.20`; hệ số tối đa `1.20`. Ngưỡng kỹ thuật sẽ được chốt bằng test trước khi code.
6. Lưu riêng `base_price`, hệ số/phụ thu thời tiết, loại thời tiết, thời điểm quan sát và nguồn. `estimated_price` là tổng snapshot; mọi cột tiền tiếp tục dùng `numeric`, không dùng float.
7. API trả breakdown để UI hiển thị minh bạch trước khi khách thanh toán giả lập.
8. Thời tiết nguy hiểm phải có cảnh báo an toàn; tăng giá không thay thế quyết định tạm ngừng dịch vụ.

## Thay đổi dự kiến trước khi triển khai

- Migration thêm các cột snapshot thời tiết/giá vào `orders` hoặc bảng snapshot riêng; không sửa ngược dữ liệu đơn cũ.
- `WeatherService` có adapter để mock trong test và có thể đổi nhà cung cấp.
- `PricingService` thuần, nhận base price + snapshot thời tiết và trả breakdown decimal.
- Test bắt buộc: từng ngưỡng, mức trần, làm tròn VND, timeout/fallback, cache, snapshot không đổi và không gọi API ngoài trong test.
- Cập nhật Swagger, API catalog, Flutter handoff và màn hình xác nhận giá.

Phần này nên làm ở PR riêng sau backup/restore. Không kết nối thanh toán thật hoặc tự động thu thêm dựa trên thời tiết trong giai đoạn demo.
