# Kiến trúc backend MotoCare

Cập nhật: 2026-10-07

## Quyết định

Backend là **modular monolith NestJS**. Không tách microservice, Redis hay queue cho bản đồ án. Mục tiêu là giữ một tiến trình dễ chạy trên laptop nhưng có ranh giới đủ rõ để thay adapter thanh toán, realtime hoặc lưu file về sau.

Thứ tự ưu tiên:

1. Đúng nghiệp vụ và bảo toàn dữ liệu.
2. Ranh giới module rõ, dependency đi một chiều.
3. API ổn định cho Flutter.
4. Khả năng thay hạ tầng mà không viết lại use case.
5. Chỉ tối ưu hiệu năng khi có số liệu.

## Quyền sở hữu module

| Module | Sở hữu |
| --- | --- |
| `orders` | Vòng đời đơn, offer, matching, đề xuất giá và quy tắc chuyển trạng thái |
| `payments` | Payment, adjustment, wallet, ledger, refund và withdrawal |
| `providers` | Hồ sơ thợ, phê duyệt, trạng thái online và vị trí hiện tại |
| `messages` | Lịch sử chat, metadata ảnh và quyền tải ảnh |
| `realtime` | Xác thực socket, room và phát event; không quyết định nghiệp vụ |
| `admin` | Use case quản trị và read model dashboard/đối soát |
| `pricing` | Tạo báo giá từ giá cơ bản và snapshot thời tiết |

Một module không được sửa dữ liệu thuộc module khác tùy ý. Orders chỉ truy cập payment/wallet qua port do Payments sở hữu; TypeORM entity và quy tắc ledger không còn nằm trong command/query service của Orders.

## Cấu trúc feature phức tạp

Không bắt mọi module nhỏ phải có nhiều lớp. Feature lớn như Orders dùng cấu trúc sau khi có trách nhiệm thực tế:

```text
orders/
├── domain/          # policy thuần TypeScript, không phụ thuộc Nest/TypeORM
├── application/     # command/query use case và điều phối transaction
├── presentation/    # ánh xạ response ổn định cho REST/Socket
├── *.entity.ts      # persistence model TypeORM trong giai đoạn hiện tại
├── *.controller.ts
└── *.service.ts     # code cũ được tách dần, không big-bang rewrite
```

Hướng dependency mong muốn:

```text
controller -> application -> domain
                    |
                    v
             infrastructure adapter
```

`domain` không import NestJS, TypeORM, controller, gateway hoặc entity của module khác. Không tạo generic repository chỉ để đủ mẫu; chỉ tạo port/repository cho ranh giới hoặc query phức tạp thực sự.

## Quy tắc Orders

- `order-transition.policy.ts` là đồ thị chuyển trạng thái hợp lệ dùng chung. Use case vẫn phải kiểm tra điều kiện ngữ cảnh như đúng khách/thợ, proposal/offer còn hiệu lực và payment đã settle.
- Command giữ transaction và row lock tại application boundary.
- `OrdersQueryService` chỉ đọc và kiểm tra quyền xem; không đổi trạng thái.
- Presenter giữ shape response, không chứa truy vấn hay quyết định nghiệp vụ.
- Endpoint, DTO Swagger và response Flutter không được đổi trong refactor nếu chưa có PR contract riêng.

## Transaction và realtime

PostgreSQL constraint/transaction là nguồn bảo vệ cuối cùng cho tiền, offer và trạng thái. Event Socket.IO hiện được phát sau khi transaction hoàn tất. Gateway chỉ là adapter giao hàng nhanh; client luôn dùng REST fallback sau reconnect.

Application service phụ thuộc `RealtimePublisher`, không phụ thuộc `RealtimeGateway` hay Socket.IO. `RealtimeModule` ánh xạ port tới gateway bằng `useExisting`, vì vậy chỉ có một adapter runtime và không phát event trùng. Port sở hữu contract event; gateway chịu trách nhiệm room/transport. Việc thay transport không được làm đổi event/payload nếu chưa có PR contract riêng.

Hiện chưa có transactional outbox. Nếu chạy nhiều NestJS instance, cần thiết kế outbox/adapter phân tán, Socket.IO adapter dùng chung và khóa scheduler trước; không giả định room hoặc cron trong bộ nhớ có thể scale ngang.

## Ranh giới payment và settlement

- `PaymentSettlementPort` sở hữu các thao tác ghi: tạo prepayment, chuyển cancel/refund, tạo adjustment giá cuối và credit ví thợ.
- `PaymentQueryPort` trả snapshot chỉ đọc cho order detail và danh sách refund; không làm lộ TypeORM entity sang Orders.
- `TypeOrmPaymentAccountingAdapter` là adapter duy nhất cho cả hai port. Nest dùng `useExisting` để không tạo hai instance.
- `PaymentAccountingModule` không import `OrdersModule`, nhờ vậy dependency module không bị vòng dù `PaymentsModule` vẫn cần matching của Orders cho demo prepayment.
- Port ghi nhận `EntityManager` của transaction hiện tại. Đây là lựa chọn thực dụng cho modular monolith TypeORM: order lock, payment lock, adjustment và wallet ledger commit/rollback cùng nhau; không tạo transaction lồng nhau hoặc abstraction Unit of Work hình thức.
- Unique index mỗi order chỉ có một wallet credit vẫn là hàng rào cuối cùng; `wallet_transactions.amount` luôn dương và chiều số dư suy từ `type`.

## Những gì cố ý chưa làm

- Không microservice và không event bus phân tán.
- Không base repository dùng chung cho mọi entity.
- Không CQRS framework; command/query chỉ tách theo trách nhiệm.
- Không đổi ORM hoặc schema trong refactor kiến trúc.
- Không tích hợp tiền thật trước khi ranh giới payment, idempotency và webhook verification hoàn tất.

## Lộ trình refactor

1. Đã tập trung state transition; tách Orders query/presenter khỏi command service.
2. Đã đưa realtime qua `RealtimePublisher` port để use case không gọi gateway trực tiếp.
3. Đã chuyển settlement/payment/wallet ra khỏi Orders qua `PaymentSettlementPort` và `PaymentQueryPort` do Payments sở hữu.
4. Tiếp theo: chuẩn hóa strict typecheck và sửa typing debt trong test/mocks mà không làm yếu compiler.
5. Tách Admin dashboard và reconciliation query khi cần sửa nghiệp vụ báo cáo.
6. Thêm adapter SePay tắt mặc định, webhook idempotent và audit trước khi cấu hình tiền thật.

Mỗi bước phải giữ nguyên API hiện tại, chạy unit + PostgreSQL/PostGIS/HTTP tests và được merge riêng qua PR.
