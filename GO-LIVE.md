# MotoCare / REVO — Runbook Go-Live

Tài liệu vận hành để chuyển hệ thống từ chế độ test sang **nhận tiền thật**.
Mọi lệnh chạy trong thư mục `backend/` trừ khi ghi khác.

## 0. Hiện trạng (đã kiểm 28/10/2026)

Hệ thống **đã public sẵn**, không cần thuê cloud:

- **Public URL (HTTPS):** `https://hyzeniths.tailb56b46.ts.net` qua **Tailscale Funnel**
  → trỏ về `http://127.0.0.1:3000` (backend chạy trên máy này).
  Kiểm: `tailscale funnel status` phải thấy `Funnel on` và proxy `/ → 127.0.0.1:3000`.
- **Database:** PostgreSQL + PostGIS trong Docker (`motocare-postgres`), dữ liệu lưu ở volume.
- **SePay / SMTP / secret production:** đã cấu hình đủ trong `backend/.env.go-live.backup`
  (đã kiểm độ dài: JWT 64, HMAC 64/64, DB pass 48, webhook secret 38 — hợp lệ).
- **Webhook SePay:** `POST https://hyzeniths.tailb56b46.ts.net/payments/webhooks/sepay`
  (payout: `.../payments/webhooks/sepay/payouts`).

> Vì backend chạy trên máy cá nhân + Tailscale, **máy phải bật và Funnel phải chạy 24/7**
> thì khách mới thanh toán được. Nếu cần ổn định hơn sau này, có thể đưa lên cloud bằng
> `backend/Dockerfile` + `render.yaml` đã chuẩn bị (xem mục 6).

## 1. Hai chế độ

| | Test (hiện tại) | Live (tiền thật) |
|---|---|---|
| `.env` dùng | `.env` (NODE_ENV=development, DEMO_MODE=true) | `.env.go-live.backup` |
| SePay | test VA `SBSEPAYX9KA2B7MN4QR` | TK thật `0367518550` |
| Xác nhận thanh toán | nút "thanh toán thử" (demo) | webhook SePay thật |
| Tiền | giả lập | **THẬT — vào TK ngân hàng** |

## 2. Trước khi go-live (bắt buộc)

1. **Đăng ký webhook trên SePay dashboard** cho tài khoản thật `0367518550`:
   - URL: `https://hyzeniths.tailb56b46.ts.net/payments/webhooks/sepay`
   - Secret: lấy đúng `SEPAY_WEBHOOK_SECRET` trong `.env.go-live.backup`.
   - (Nếu dùng đối soát payout: đăng ký thêm `.../payments/webhooks/sepay/payouts`.)
2. Đảm bảo Tailscale Funnel đang chạy (mục 0).
3. Đảm bảo Docker Postgres đang chạy: `docker ps` thấy `motocare-postgres ... (healthy)`.

## 3. Go-live (thao tác chuyển tiền thật — CHÍNH CHỦ XÁC NHẬN)

```bash
# Sao lưu .env hiện tại rồi áp cấu hình go-live
cp .env .env.pre-golive.backup
cp .env.go-live.backup .env

# Khởi động lại backend ở chế độ production
# (dừng tiến trình start:dev hiện tại, rồi:)
npm run build
npm run start:prod        # chạy migration tự động? KHÔNG — chạy thủ công bên dưới nếu cần
# hoặc dev-watch: npm run start:dev
```

Kiểm backend đã lên production:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://hyzeniths.tailb56b46.ts.net/weather/current?latitude=10.77&longitude=106.7
# 401 = backend sống (cần auth) — OK
```

Backend sẽ **từ chối khởi động** nếu thiếu/sai secret production (Joi validate), nên nếu nó
lên được nghĩa là cấu hình hợp lệ.

## 4. Build app trỏ về URL public (cho điện thoại thật)

APK debug mặc định trỏ `http://10.0.2.2:3000` (chỉ dùng cho emulator). Khách dùng điện thoại
thật thì phải build trỏ về URL public:

```bash
# Tại thư mục gốc dự án
flutter build apk --release --flavor customer -t lib/main.dart \
  --dart-define=API_BASE_URL=https://hyzeniths.tailb56b46.ts.net

flutter build apk --release --flavor provider -t lib/main_provider.dart \
  --dart-define=API_BASE_URL=https://hyzeniths.tailb56b46.ts.net
```

> Release build cần cấu hình ký (`android/key.properties` + keystore). Nếu chưa có keystore,
> tạm thời build `--debug` với cùng `--dart-define=API_BASE_URL=...` cũng chạy được trên
> điện thoại thật (chỉ là bản debug-signed, không đưa lên CH Play được).

## 5. Rollback về test

```bash
cp .env.pre-golive.backup .env   # hoặc dùng lại cấu hình dev
# khởi động lại backend
```

## 6. (Tuỳ chọn) Đưa backend lên cloud cho ổn định

Đã chuẩn bị sẵn:
- `backend/Dockerfile` (multi-stage, chạy migration rồi start).
- `backend/.dockerignore`.
- Script `start:prod`, `migration:run:prod`, `seed:prod` trong `backend/package.json`.

Khi muốn: đẩy repo lên GitHub, tạo một web service Docker trên Render/Railway trỏ
`backend/Dockerfile`, tạo Postgres (bật extension PostGIS), đặt các biến env như
`.env.go-live.backup` (đổi `DATABASE_*` sang DB cloud, `PUBLIC_BASE_URL`/`CORS_ORIGIN`
sang domain mới), rồi cập nhật `API_BASE_URL` khi build app.

## ⚠️ Ràng buộc an toàn tiền

- Không tự ý bật `SEPAY_MODE=live`. Bước này nhận tiền thật vào TK `0367518550` → **chính
  chủ (founder) xác nhận và thực hiện**.
- `SEPAY_LIVE_CONFIRMATION=I_UNDERSTAND_THIS_ACCEPTS_REAL_MONEY` trong `.env.go-live.backup`
  là chốt chặn chủ ý: chỉ có khi thực sự muốn nhận tiền thật.
- Payout (chuyển tiền cho thợ) giữ **thủ công** cho tới khi đối soát tin cậy.
