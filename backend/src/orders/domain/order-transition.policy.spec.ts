import { OrderStatus } from '../../common/enums/order-status.enum';
import { canTransitionOrder } from './order-transition.policy';

describe('order transition policy', () => {
  it.each([
    [OrderStatus.AWAITING_PREPAYMENT, OrderStatus.PENDING_MATCH],
    [OrderStatus.AWAITING_PREPAYMENT, OrderStatus.REFUND_PENDING],
    [OrderStatus.PENDING_MATCH, OrderStatus.OFFERED],
    [OrderStatus.OFFERED, OrderStatus.ACCEPTED],
    [OrderStatus.ACCEPTED, OrderStatus.ARRIVED],
    [OrderStatus.ARRIVED, OrderStatus.IN_PROGRESS],
    [OrderStatus.IN_PROGRESS, OrderStatus.AWAITING_PRICE_APPROVAL],
    [OrderStatus.AWAITING_PRICE_APPROVAL, OrderStatus.PAID],
    [OrderStatus.PAID, OrderStatus.COMPLETED],
    [OrderStatus.REFUND_PENDING, OrderStatus.REFUNDED],
  ])('allows %s -> %s', (from, to) => {
    expect(canTransitionOrder(from, to)).toBe(true);
  });

  it.each([
    [OrderStatus.AWAITING_PREPAYMENT, OrderStatus.COMPLETED],
    [OrderStatus.OFFERED, OrderStatus.IN_PROGRESS],
    [OrderStatus.COMPLETED, OrderStatus.IN_PROGRESS],
    [OrderStatus.REFUNDED, OrderStatus.PENDING_MATCH],
  ])('rejects %s -> %s', (from, to) => {
    expect(canTransitionOrder(from, to)).toBe(false);
  });

  it.each([
    OrderStatus.AWAITING_PREPAYMENT,
    OrderStatus.PENDING_MATCH,
    OrderStatus.OFFERED,
    OrderStatus.ACCEPTED,
    OrderStatus.ARRIVED,
  ])('allows a paid pre-service order in %s to enter refund review', (status) => {
    expect(canTransitionOrder(status, OrderStatus.REFUND_PENDING)).toBe(true);
  });
});
