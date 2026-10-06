# MotoCare Backend — giá theo thời tiết

Cập nhật: 2026-10-07. Trạng thái: **đã triển khai trên nhánh sửa `feat/zenith/weather-pricing-main`; mặc định tắt cho đến khi cấu hình demo bật rõ ràng**. PR #14 trước đó bị merge nhầm vào nhánh `feat/zenith/demo-backup`, nên cần PR sửa này để tính năng thực sự vào `main`.

## Nguồn dữ liệu và phạm vi

Backend gọi Open-Meteo khi tạo đơn, không đưa khóa hoặc logic giá xuống Flutter. API có dữ liệu mưa, mã thời tiết, tốc độ gió và gió giật. Gói miễn phí chỉ phù hợp mục đích phi thương mại/giáo dục, có giới hạn sử dụng, yêu cầu ghi nguồn và không cam kết uptime; nếu dự án chuyển sang thương mại phải đánh giá lại giấy phép/gói dịch vụ.

- Tài liệu biến thời tiết: <https://open-meteo.com/en/docs>
- Điều khoản và giới hạn miễn phí: <https://open-meteo.com/en/terms>
- Chính sách gói dịch vụ: <https://open-meteo.com/en/pricing>

## Quy tắc đang dùng

| Mức | Điều kiện chỉ cần thỏa một | Hệ số |
| --- | --- | --- |
| `SEVERE` | Mã mưa rất to/dông mạnh; lượng mưa `>= 7.5 mm/h`; gió `>= 40 km/h`; hoặc gió giật `>= 60 km/h` | `1.2000` |
| `MODERATE` | Có mã mưa/tuyết/dông; mưa `>= 0.1 mm/h`; gió `>= 25 km/h`; hoặc gió giật `>= 40 km/h` | `1.1000` |
| `NORMAL` | Không thuộc hai mức trên | `1.0000` |
| `DISABLED` / `UNAVAILABLE` | Tính năng tắt, timeout, lỗi mạng hoặc response không hợp lệ | `1.0000` |

Hệ số tối đa là `1.20`. Đây là quy tắc demo, không phải biểu giá thương mại đã được phê duyệt.

## Tính nhất quán và an toàn

1. Tọa độ được làm tròn hai chữ số trước khi gửi nhà cung cấp, vừa giảm độ chính xác dữ liệu chia sẻ vừa tạo cache theo khu vực.
2. Cache mặc định 300 giây, tối đa 500 ô; timeout mặc định 1.500 ms.
3. Nếu dịch vụ lỗi/chậm, tạo đơn vẫn tiếp tục với phụ thu `0.00`.
4. Snapshot đúng một lần khi tạo đơn. Thời tiết hoặc GPS đổi sau đó không làm đổi tiền.
5. `base_price`, `weather_surcharge` và `estimated_price` là `numeric(12,2)`. Phép tính dùng cents `BigInt` và basis points, không dùng floating point cho tiền.
6. Payment pending lấy đúng `estimated_price` snapshot; matching chỉ bắt đầu sau xác nhận sandbox như trước.
7. `pricing` được trả ở create/details/order list/pending offer để cả khách và thợ nhìn cùng breakdown.
8. Dữ liệu từ Open-Meteo trả `attribution`; UI phải hiển thị nguồn. Thời tiết nguy hiểm nên có cảnh báo an toàn, không chỉ tăng giá.

## Cấu hình

```dotenv
WEATHER_PRICING_ENABLED=false
WEATHER_REQUEST_TIMEOUT_MS=1500
WEATHER_CACHE_TTL_SECONDS=300
```

Chỉ đổi `WEATHER_PRICING_ENABLED=true` trong `.env` demo riêng. Không cần API key. Không bật mặc định để test/local không phụ thuộc Internet và để nhóm chủ động xác nhận UI đã hiển thị breakdown.

Migration `1760000000008-AddWeatherPricingSnapshot` backfill đơn cũ với `base_price = estimated_price`, category `DISABLED`, phụ thu `0`. Unit test kiểm tra phân loại, cache, fallback và số học tiền; database test kiểm tra snapshot severe và payment amount.
