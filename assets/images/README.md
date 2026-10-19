# REVO sedan

`revo_sedan.png` được tạo bằng công cụ imagegen tích hợp (skill imagegen), sau đó sao chép vào project. PNG có nền trong suốt. Asset được tạo ở phiên trước, hiện giữ cho ảnh mẫu Chat; Welcome và banner dùng vùng ảnh xe từ tham chiếu A1 như mô tả bên dưới. Không cần tải ảnh qua mạng khi chạy.

Prompt cuối:

> Use case: product-mockup. Asset type: transparent PNG hero asset for a premium Vietnamese automotive roadside assistance mobile application named REVO. Primary request: a single photorealistic pearl white modern compact sedan, front three-quarter view, nose pointing to the left, full vehicle entirely visible with generous 8 percent margin on all sides. Clean neutral studio lighting, subtle realistic contact shadow underneath, glossy white paint, dark windows, silver alloy wheels. Center the vehicle in a wide landscape composition; camera at headlight height. Background must be genuinely transparent, not white. No branding, no legible license plate, no text, no people, no extra objects. Intended as a reusable cutout at 360 pixels wide in a blue-white-navy mobile interface.

## Artwork lấy từ bộ 20 ảnh của người dùng

Các file `reference_welcome.png`, `reference_profile.png`, `reference_customer.png`,
`reference_vehicles.png` là bản sao nguyên vẹn A1_Welcome, F1_Profile,
C9_Customer_Chat và D1_Orders trong `/Users/vythui/Downloads/20 ANH REVO`.
Widget `ReferenceImage` chỉ vẽ các vùng ảnh xe/chân dung/thumbnail; không dùng
screenshot làm màn hình UI, không hiển thị frame, nút hay chữ bên ngoài artwork.
Đây là artwork thật từ tham chiếu (độ phân giải thấp), không phải ảnh nhân vật mới tạo.
Ảnh sedan tạo trước đây vẫn được giữ và dùng cho ảnh mẫu trong chat.


## Home theo thiết kế mới — 16/10/2026

Ba ảnh mới được tạo bằng built-in imagegen và chép nguyên vẹn vào project:
`home_mechanic_hero.png` (1774×887), `home_battery_car.png` và
`home_tire_suv.png` (1536×1024). Đây là artwork minh họa mới theo mô tả ảnh
tham chiếu, không phải ảnh gốc khôi phục hoặc ảnh khách hàng thực.
Không chèn screenshot làm giao diện; text, CTA, badge, grid và navigation
đều là Flutter widgets. Không sửa/xóa các asset trước đó.
Prompt đầy đủ, đường dẫn nguồn và SHA256: [ASSETS.json](../../docs/home-redesign/ASSETS.json).


## Trang chủ 2×3 card ảnh — 16/10/2026

Banner dùng nguyên vẹn ảnh gốc `revo_hero_engine.jpg` do người dùng cung cấp
trong task này (SHA256 trùng tệp `.png` trong Downloads, nội dung thực là JPEG).
Flutter dùng BoxFit.cover và overlay navy; không xử lý lại bitmap.
Hai ảnh Kích bình/Thay lốp giữ nguyên từ bộ Home trước. Ba ảnh
`home_service_flood.png`, `home_service_tow.png`, `home_service_repair.png`
là artwork minh họa mới bằng built-in imagegen, không phải ảnh khách hàng thực.
Prompt, nguồn, hash và đường dẫn: [ASSETS.json](../../docs/home-reconstruction/ASSETS.json).
Logo được vẽ trong `lib/widgets/revo_brand.dart`; Home dùng E xanh ba thanh rời,
các màn còn lại giữ giá trị mặc định của wordmark.
