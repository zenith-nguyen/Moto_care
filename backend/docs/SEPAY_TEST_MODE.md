# SePay Test mode — QR và webhook an toàn

Cập nhật: 2026-10-08. Tích hợp này chỉ dành cho môi trường thử nghiệm cách ly của SePay. Adapter mặc định tắt, chỉ chấp nhận `SEPAY_MODE=test` và không thực hiện hoàn tiền, chuyển ví hay rút tiền ngân hàng.

## Hàng rào không nhận tiền thật

Phiên bản đầu chỉ chấp nhận virtual account giả chính thức của SePay Test mode có định dạng `SBSEPAY` + 12 chữ/số in hoa. Validation lúc khởi động và adapter đều từ chối số tài khoản ngân hàng thông thường. QR tạo ra luôn có `simulationOnly: true`; ứng dụng ngân hàng thật không thể phân giải người nhận Test mode này.

Không đổi regex hoặc đưa số tài khoản thật vào adapter để “thử nhanh”. Muốn tích hợp Live phải thực hiện một đợt review riêng về merchant, đối soát, hoàn tiền, phân quyền và quản lý secret.

## Luồng

1. Customer tạo order; backend tạo payment `PENDING`, order `AWAITING_PREPAYMENT`.
2. Customer gọi `GET /payments/orders/:orderId/instructions`. Backend trả mã `MC<paymentId>`, đúng số tiền VND, VA giả và URL VietQR.
3. Flutter chỉ hiển thị thông tin/QR khi `simulationOnly=true`, rồi poll `GET /orders/:id`. Flutter không giữ webhook secret và không tự xác nhận đã trả tiền.
4. SePay Test mode gửi `POST /payments/webhooks/sepay` với raw JSON, timestamp và HMAC.
5. Backend xác minh chữ ký, replay window, account/VA, chiều tiền vào, payment code, amount và trạng thái trong transaction.
6. Giao dịch hợp lệ chuyển payment sang `PAID`, order sang matching và phát event sau commit. Retry cùng transaction/payload trả `{"success":true}` nhưng không áp dụng lần hai.

## Cấu hình local

Tại Dashboard SePay, bật **Test mode** và tạo virtual account giả có tiền tố `SBSEPAY`. Cấu hình nhận diện mã thanh toán với prefix `MC`, hậu tố là số. Tạo webhook JSON tiền vào, bật lọc mã thanh toán `MC`, chọn **HMAC-SHA256** và trỏ URL tới:

```text
https://<public-test-host>/payments/webhooks/sepay
```

Giữ secret chỉ trong `.env` backend:

```dotenv
SEPAY_ENABLED=true
SEPAY_MODE=test
SEPAY_BANK=<bank alias Test mode dùng cho VietQR>
SEPAY_ACCOUNT_NUMBER=SBSEPAY<12_CHU_SO_IN_HOA>
SEPAY_ACCOUNT_HOLDER=<tên hiển thị không dấu>
SEPAY_PAYMENT_CODE_PREFIX=MC
SEPAY_TRANSFER_MEMO_PREFIX=
SEPAY_WEBHOOK_SECRET=<secret HMAC riêng, tối thiểu 32 ký tự>
SEPAY_WEBHOOK_MAX_AGE_SECONDS=300
```

Khởi động lại API sau khi đổi `.env`. Không commit, chụp màn hình hoặc gửi `SEPAY_WEBHOOK_SECRET` qua chat. Khi nghi lộ, tạo secret mới ở SePay và backend cùng lúc.

## Chốt an toàn

- HMAC dùng đúng bytes raw body theo chuỗi `{timestamp}.{raw_body}`; không `JSON.stringify` body đã parse để verify.
- Timestamp mặc định chỉ hợp lệ trong ±300 giây.
- `sepay_webhook_events.external_transaction_id` unique; payload hash phát hiện transaction ID bị phát lại với nội dung khác.
- Audit không lưu raw payload, chữ ký, secret hay mô tả giao dịch.
- Sai amount không làm payment thành công; outcome audit là `AMOUNT_MISMATCH`.
- QR không phải bằng chứng thanh toán. Chỉ trạng thái payment do webhook hợp lệ cập nhật mới cho phép matching.
- `SEPAY_ENABLED=false` vẫn là cấu hình chuẩn của nhóm đến khi chủ repo chủ động test sandbox.

Tài liệu chính thức: [xác thực webhook](https://developer.sepay.vn/vi/sepay-webhooks/xac-thuc), [payload và idempotency](https://developer.sepay.vn/vi/sepay-webhooks/tich-hop-webhook), [SePay Test mode](https://developer.sepay.vn/vi/tien-ich-khac/test-mode), [mô phỏng VietQR Test mode](https://developer.sepay.vn/vi/tien-ich-khac/test-mode/mo-phong-tao-ma-vietqr).
