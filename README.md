# MotoCare — Giao diện Thợ (Flutter)

Đồ án môn Phát triển ứng dụng Mobile. 6 màn hình cho phía **Thợ sửa xe**, dữ liệu mock trong RAM, không backend.

## Cách chạy

This repository is the MotoCare monorepo. The Flutter mobile application lives at the repository root, and the NestJS API lives in `backend/`.

The backend uses PostgreSQL + PostGIS locally through Docker Compose. See [`backend/README.md`](backend/README.md) for backend setup and database commands.

Thư mục này chỉ chứa `lib/`, `pubspec.yaml` và `assets/`. Tạo phần native (android/ios) rồi chạy:

```bash
flutter create motocare_mechanic --org vn.edu.hcmut --platforms=android,ios
# copy đè lib/, pubspec.yaml, assets/ vào thư mục vừa tạo
cd motocare_mechanic
rm test/widget_test.dart        # file test mặc định tham chiếu MyApp (đã bị thay)
flutter pub get
flutter run
```

Yêu cầu Flutter >= 3.22 (dùng `PopScope.onPopInvokedWithResult`).

### Build APK để nộp

```bash
flutter build apk --release
# kết quả: build/app/outputs/flutter-apk/app-release.apk
```

Lưu ý quan trọng cho APK **release**: thêm quyền Internet vào
`android/app/src/main/AndroidManifest.xml` (trong thẻ `<manifest>`, trước `<application>`),
nếu không `google_fonts` sẽ không tải được font khi cài APK:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Muốn demo **không cần mạng**: bỏ file `.ttf` của Be Vietnam Pro vào `assets/google_fonts/` (xem README.txt trong đó).

## Cấu trúc

```
lib/
  main.dart                      Khởi tạo app, AppScope, theme
  theme/app_theme.dart           Màu, bo góc, shadow, font Be Vietnam Pro
  models/models.dart             TierInfo (enum hạng), MechanicProfile, OrderRequest, WalletTransaction...
  data/mock_data.dart            Dữ liệu mẫu + isRainIncoming (set cứng = true)
  state/app_state.dart           Trạng thái dùng chung (ChangeNotifier + InheritedNotifier)
  utils/format.dart              350000 -> "350.000đ", định dạng thời gian
  screens/
    customer_home_screen.dart    (0) Khách: Trở thành đối tác -> chờ duyệt -> chuyển giao diện Thợ
    mechanic_shell.dart          Bottom nav 3 tab
    mechanic_home_screen.dart    (1) Trang chủ
    incoming_order_popup.dart    (2) Popup nổ đơn khẩn cấp 15s
    mechanic_active_order_screen.dart  (3) Thực hiện đơn & dẫn đường
    mechanic_wallet_screen.dart  (4) Ví & doanh thu
    mechanic_profile_screen.dart (5) Hồ sơ & cài đặt dịch vụ
    weekly_summary_screen.dart   (6) Tổng kết tuần kiểu Wrapped
  widgets/                       Widget con tách riêng (tier card, radar map, step progress...)
```

## Kịch bản demo gợi ý

0. **Luồng đối tác** (màn mở đầu, `customer_home_screen.dart`): "Đăng ký làm đối tác" -> điền form -> trạng thái "Chờ duyệt" -> bấm *Demo: giả lập Admin duyệt* -> hộp thoại "Bạn muốn sang Màn hình Thợ để nhận đơn ngay?" -> Sang giao diện Thợ. Có thêm công tắc "Lần đăng nhập sau tự vào giao diện Thợ" và nút giả lập đăng nhập lại. Muốn bỏ qua: bấm *Vào nhanh giao diện Thợ*. Từ tab Hồ sơ có thể quay về giao diện Khách.
1. **Trang chủ**: gạt switch ON/OFF (radar dừng khi OFF), bấm giữ card hạng để xem 4 hạng. Chọn chế độ **Tự chọn đơn** (hiện danh sách đơn gần đó) hoặc **Tự động nhận đơn** (đơn nổ thẳng lên màn hình).
2. Bấm **Giả lập nổ đơn** (hoặc bấm 1 chip đơn gần đó) -> popup đếm ngược 15s. Thử: bấm ảnh để phóng to, Từ chối, hoặc để hết giờ.
3. **Chấp nhận đơn** -> màn thực hiện đơn: bấm nút đỏ qua từng bước. "+ Thêm phụ tùng phát sinh" gửi báo giá cho khách; khoản đó ở trạng thái "Chờ khách xác nhận" (mock tự xác nhận sau 4 giây) và chỉ khi xác nhận mới được cộng vào thu nhập.
4. Hoàn thành đơn -> sang tab **Ví**: số dư tăng, có 2 dòng giao dịch mới; thử Nạp / Rút tiền.
5. Bấm **Tổng kết tuần** (ở Trang chủ hoặc Ví) -> màn Wrapped.
6. Tab **Hồ sơ**: bật/tắt dịch vụ, đổi khu vực, Chỉnh sửa tên tiệm (cập nhật cả header Trang chủ).

## Ghi chú

- Bản đồ là placeholder vẽ bằng `CustomPainter` (không cần API key). Muốn bản đồ thật, thay `RadarMap` / `RouteMap` bằng `google_maps_flutter` hoặc `flutter_map` và giữ nguyên các lớp UI nổi phía trên.
- Ảnh hiện trường là placeholder (`ScenePhoto`); thay bằng `Image.asset` khi có ảnh thật.
- Nút Gọi / Nhắn tin chỉ hiện SnackBar. Muốn gọi thật, thêm gói `url_launcher` và mở `tel:`.
