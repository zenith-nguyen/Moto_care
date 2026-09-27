# Phát hành Android

## Điều kiện phát hành

1. `main` sạch, đã qua review và tất cả GitHub Actions xanh.
2. Cập nhật `version:` trong `pubspec.yaml` theo `MAJOR.MINOR.PATCH+BUILD` và merge PR này vào `main`.
3. Tạo tag đúng ba phần đầu của version, chẳng hạn version `1.2.0+15` dùng tag `v1.2.0`.

```bash
git switch main
git pull --ff-only origin main
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

Push tag sẽ khởi chạy workflow **Release Android**. Workflow kiểm tra tag/version, build APK release, lưu artifact và tạo GitHub Release kèm file APK.

## Chữ ký để đưa lên Google Play

APK hiện được tạo từ cấu hình Android của repository. Trước khi đưa bản đầu tiên lên Google Play, tạo upload keystore và lưu các giá trị vào GitHub Secrets; tuyệt đối không commit keystore hoặc mật khẩu.

| Secret | Nội dung |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | File upload keystore đã mã hóa Base64 |
| `ANDROID_KEY_ALIAS` | Alias của key |
| `ANDROID_KEY_PASSWORD` | Mật khẩu key |
| `ANDROID_STORE_PASSWORD` | Mật khẩu keystore |

Sau đó cập nhật cấu hình Android để chỉ dùng secrets trong workflow phát hành. Việc xuất bản Play Store cần một bước riêng vì hiện repository chưa có Play Console service account hay cấu hình ký.
