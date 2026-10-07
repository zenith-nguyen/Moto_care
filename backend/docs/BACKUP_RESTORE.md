# MotoCare Backend — backup và phục hồi demo

Cập nhật: 2026-10-06

Quy trình này sao lưu đồng thời PostgreSQL/PostGIS và thư mục ảnh chat. Mỗi snapshot gồm `database.dump`, `chat-images.zip` và `manifest.json` chứa số migration, kích thước và SHA-256 để phát hiện file hỏng.

## Nguyên tắc an toàn

- Snapshot có dữ liệu người dùng và nội dung chat, **không được commit, gửi qua chat hoặc để trong thư mục chia sẻ công khai**. SHA-256 kiểm tra toàn vẹn, không phải mã hóa.
- Trước khi backup, nên dừng API hoặc bảo đảm không có thao tác ghi để DB và ảnh cùng một thời điểm logic.
- Restore chỉ được phép vào DB thử mới có tên chứa `restore` hoặc `test`. Script từ chối ghi đè DB đang cấu hình, DB đã tồn tại và thư mục ảnh đã tồn tại.
- Không mở cổng PostgreSQL `5432` ra Internet. Backup không chứa `.env` hay mật khẩu DB.

## Kiểm tra dung lượng và tạo backup

Từ `mobilecare_1/backend`, khi Docker đang chạy:

```powershell
npm run backup:check
npm run backup:create
```

Snapshot được tạo dưới `backend/backups/`, là thư mục bị Git bỏ qua. `backup:check` yêu cầu dung lượng trống tối thiểu bằng mức lớn hơn giữa 1 GiB và hai lần tổng kích thước DB + ảnh chat.

Nếu dùng `.env.demo`, đặt biến trong đúng cửa sổ PowerShell trước khi chạy:

```powershell
$env:DOTENV_CONFIG_PATH = '.env.demo'
npm run backup:check
npm run backup:create
```

## Diễn tập phục hồi

Thay đường dẫn snapshot và tên DB thử, nhưng giữ ba giá trị tên DB trùng nhau:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/restore-demo.ps1 `
  -BackupDirectory 'D:\duong-dan\motocare-motocare-YYYYMMDDTHHMMSSZ' `
  -TargetDatabase 'motocare_restore_test' `
  -ConfirmTargetName 'motocare_restore_test'
```

Sau khi script xác nhận số migration, có thể kiểm tra thêm bằng DBeaver hoặc:

```powershell
docker exec motocare-postgres psql -U motocare -d motocare_restore_test -c 'SELECT count(*) FROM migrations;'
docker exec motocare-postgres psql -U motocare -d motocare_restore_test -c 'SELECT count(*) FROM users;'
docker exec motocare-postgres psql -U motocare -d motocare_restore_test -c 'SELECT count(*) FROM incident_types;'
```

Khi đã xác minh xong, chỉ xóa đúng DB thử đã đặt tên:

```powershell
docker exec motocare-postgres dropdb -U motocare motocare_restore_test
```

## Kết quả diễn tập 2026-10-06

- Phát hiện DB local mới có 6/8 migration và đã tạo snapshot trước khi thay đổi.
- Chạy thêm migration ảnh chat và khôi phục mật khẩu; DB local hiện có 8 migration, `/health/ready` trả `200`.
- Tạo snapshot mới sau migration, phục hồi vào DB thử độc lập và xác nhận 8 migration, 6 users, 5 incident types.
- Xóa DB phục hồi thử sau khi kiểm chứng; DB ứng dụng không bị ghi đè.

Backup chỉ có giá trị khi đã thử restore. Lặp lại diễn tập trước buổi demo quan trọng và sau thay đổi schema lớn.
