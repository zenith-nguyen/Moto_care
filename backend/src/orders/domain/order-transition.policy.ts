import { OrderStatus } from '../../common/enums/order-status.enum';

const orderTransitions: Readonly<Record<OrderStatus, ReadonlySet<OrderStatus>>> = {
  [OrderStatus.AWAITING_PREPAYMENT]: new Set([
    OrderStatus.PENDING_MATCH,
    OrderStatus.CANCELLED,
    OrderStatus.REFUND_PENDING,
  ]),
  [OrderStatus.PENDING_MATCH]: new Set([OrderStatus.OFFERED, OrderStatus.CANCELLED, OrderStatus.REFUND_PENDING]),
  [OrderStatus.OFFERED]: new Set([
    OrderStatus.ACCEPTED,
    OrderStatus.PENDING_MATCH,
    OrderStatus.CANCELLED,
    OrderStatus.REFUND_PENDING,
  ]),
  [OrderStatus.ACCEPTED]: new Set([OrderStatus.ARRIVED, OrderStatus.CANCELLED, OrderStatus.REFUND_PENDING]),
  [OrderStatus.ARRIVED]: new Set([OrderStatus.IN_PROGRESS, OrderStatus.CANCELLED, OrderStatus.REFUND_PENDING]),
  [OrderStatus.IN_PROGRESS]: new Set([OrderStatus.AWAITING_PRICE_APPROVAL, OrderStatus.PRICE_DISPUTED]),
  [OrderStatus.AWAITING_PRICE_APPROVAL]: new Set([
    OrderStatus.IN_PROGRESS,
    OrderStatus.AWAITING_PAYMENT,
    OrderStatus.PAID,
  ]),
  [OrderStatus.PRICE_DISPUTED]: new Set([
    OrderStatus.IN_PROGRESS,
    OrderStatus.AWAITING_PAYMENT,
    OrderStatus.PAID,
  ]),
  [OrderStatus.AWAITING_PAYMENT]: new Set([OrderStatus.PAID]),
  [OrderStatus.PAID]: new Set([OrderStatus.COMPLETED]),
  [OrderStatus.REFUND_PENDING]: new Set([OrderStatus.REFUNDED]),
  [OrderStatus.CANCELLED]: new Set(),
  [OrderStatus.REFUNDED]: new Set(),
  [OrderStatus.COMPLETED]: new Set(),
};

export function canTransitionOrder(from: OrderStatus, to: OrderStatus): boolean {
  return orderTransitions[from].has(to);
}
