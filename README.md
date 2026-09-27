# Moto Care

Ứng dụng Flutter cho Moto Care.

## Cách làm việc

Mã nguồn được quản lý qua Pull Request (PR). Không push trực tiếp lên các nhánh tích hợp.

- [`main`](docs/WORKFLOW.md): bản ổn định và nguồn duy nhất để phát hành.
- [`cam-thu`](docs/branches/cam-thu.md): nhánh tích hợp công việc của Cẩm Thư.
- [`thanh-vy`](docs/branches/thanh-vy.md): nhánh tích hợp công việc của Thanh Vy.

Đọc [quy trình cộng tác](CONTRIBUTING.md) trước khi bắt đầu. Nếu dùng AI để hỗ trợ code, hãy đọc [hướng dẫn cho AI](AGENTS.md) và hướng dẫn theo nhánh đang làm.

## Kiểm tra tự động và phát hành

GitHub Actions sẽ chạy format check, phân tích tĩnh, unit test và build Android cho mỗi PR và mỗi lần cập nhật các nhánh tích hợp. Khi tạo tag theo mẫu `vMAJOR.MINOR.PATCH`, workflow phát hành sẽ tạo APK release và GitHub Release.

Chi tiết: [quy trình nhánh](docs/WORKFLOW.md) và [quy trình phát hành](docs/RELEASES.md).

## Chạy ở máy cá nhân

```bash
flutter pub get
flutter run
```
