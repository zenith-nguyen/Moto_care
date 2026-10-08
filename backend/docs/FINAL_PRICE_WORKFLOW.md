# MotoCare Backend — giá cuối và điều chỉnh thanh toán

Cập nhật: 2026-10-07. Phạm vi hiện tại là **sandbox local**, không chuyển hoặc hoàn tiền ngân hàng.

## Luồng chuẩn

1. Đơn phải ở `IN_PROGRESS`. Provider gửi `POST /orders/:orderId/price-proposals` với `final_price` và lý do.
2. Đơn chuyển `AWAITING_PRICE_APPROVAL`. Customer chọn approve hoặc reject.
3. Nếu approve:
   - bằng khoản trả trước: đơn chuyển thẳng `PAID`;
   - cao hơn: tạo `payment_adjustments` loại `CHARGE`, đơn chuyển `AWAITING_PAYMENT`;
   - thấp hơn: tạo `payment_adjustments` loại `REFUND`, đơn chuyển `AWAITING_PAYMENT`.
4. Customer xác nhận charge sandbox; Admin xác nhận refund sandbox. Sau khi settle, đơn chuyển `PAID`.
5. Provider gọi `/complete`; backend đối chiếu payment + adjustment = `final_price`, rồi cộng ví đúng một lần.

`payments.amount` luôn giữ khoản trả trước gốc. Không sửa đè lịch sử đã thu. `payment_adjustments.amount` luôn dương; chiều tiền suy từ `CHARGE`/`REFUND`. `orders.extra_cost` và `orders.discount_amount` cũng luôn không âm.

## Từ chối và tranh chấp

- Customer reject đưa đơn về `IN_PROGRESS` để Provider sửa đề xuất.
- Provider có thể escalate đúng proposal bị reject; đơn chuyển `PRICE_DISPUTED`.
- Admin xem `/admin/price-disputes/pending` rồi approve/reject một lần.
- Admin xem `/admin/payment-adjustments/pending-refunds` để xử lý các khoản hoàn chênh đã được duyệt.

## An toàn và nhất quán

- Mọi chuyển trạng thái dùng transaction và `pessimistic_write` theo thứ tự order → proposal/adjustment/payment.
- Một order chỉ có một proposal `PENDING` và một payment adjustment cuối cùng.
- Provider vẫn bị unique partial index chặn nhận đơn thứ hai trong lúc chờ giá, tranh chấp hoặc settlement.
- Tiền tính bằng cents `BigInt`, lưu PostgreSQL `numeric`; không dùng float.
- `/complete` từ chối nếu giá cuối chưa duyệt, adjustment chưa settle hoặc ledger không khớp.
- Unique index wallet giữ tối đa một credit cho mỗi order.
- Dashboard/reconciliation cộng charge, refund và wallet credit riêng; không xem sandbox là giao dịch ngân hàng thật.

## Realtime và Flutter

Mọi thay đổi phát `order.status_changed` vào `order:{orderId}`. Sau event hoặc reconnect, client gọi lại `GET /orders/:id`; response có `priceProposal`, `paymentAdjustment`, `extraCost`, `discountAmount` và `finalPrice`. REST là nguồn sự thật, Socket.IO chỉ giúp cập nhật nhanh.
