# MotoCare — quy trình rút tiền sandbox

Cập nhật: 2026-10-07. Đây là ledger demo để kiểm chứng nghiệp vụ ví/Admin; không kết nối ngân hàng và không chứng minh tiền đã được chuyển.

## Mô hình số dư

- `wallets.balance`: tổng số demo còn thuộc ví thợ.
- `wallets.locked_balance`: phần đã giữ cho yêu cầu `PENDING`.
- `availableBalance = balance - locked_balance`: backend trả sẵn cho UI.
- `wallet_transactions.amount` luôn dương; `CREDIT`/`DEBIT` quyết định chiều.

PostgreSQL bắt buộc `balance >= 0`, `locked_balance >= 0`, `locked_balance <= balance`, withdrawal `amount > 0`, tối đa một request `PENDING` cho mỗi provider và tối đa một `DEBIT` cho mỗi withdrawal.

## Luồng Provider

1. `GET /wallets/me`: xem tổng/khóa/khả dụng và 20 giao dịch gần nhất.
2. `POST /withdrawals` với `{ "amount": "50000.00" }`.
3. Backend khóa dòng provider + wallet, kiểm tra amount không vượt available, tăng `locked_balance` và tạo request `PENDING` trong cùng transaction.
4. `GET /withdrawals/me`: xem tối đa 50 request gần nhất và snapshot ví.

Hai request đồng thời không thể cùng tiêu phần available giống nhau vì wallet được `SELECT ... FOR UPDATE`; mỗi thợ chỉ có một request `PENDING`. Sau khi Admin xử lý mới tạo request kế tiếp.

## Luồng Admin

1. `GET /admin/withdrawals/pending`: tối đa 50 request cũ trước.
2. `PATCH /admin/withdrawals/:id/resolve`:
   - Duyệt: `{ "decision": "APPROVE", "reason": "Sandbox payout reviewed" }`.
   - Từ chối: `{ "decision": "REJECT", "reason": "Lý do bắt buộc" }`.
3. Duyệt: giảm `balance` và `locked_balance`, tạo một `DEBIT`, request thành `APPROVED`.
4. Từ chối: chỉ giảm `locked_balance`, request thành `REJECTED`.

Request được khóa dòng. Gửi lặp cùng quyết định trả lại kết quả hiện tại; cố đổi quyết định sau khi xử lý trả `409`. Unique partial index tiếp tục ngăn debit trùng nếu logic ứng dụng bị gọi cạnh tranh.

## Phạm vi UI

- Dùng “yêu cầu rút sandbox”, “đang duyệt”, “đã duyệt sandbox”, không dùng “đã chuyển khoản”.
- Không hỏi hoặc lưu số tài khoản, ngân hàng, OTP hay ảnh chứng từ.
- `409` nghĩa là cần tải lại ví/request; không retry vô hạn.
- Dashboard Admin phân biệt tiền cộng ví (`settledToProvidersInPeriod`) và debit rút (`providerWithdrawnInPeriod`).

## Nâng cấp thành tiền thật sau này

Cần một thiết kế riêng cho thông tin người nhận được mã hóa, trạng thái payout chi tiết, idempotency key của ngân hàng, webhook có chữ ký, retry/reconciliation và quy trình xử lý lỗi. Không tái sử dụng cờ `APPROVED` sandbox như bằng chứng ngân hàng đã chi tiền.
