import { EntityManager } from 'typeorm';
import { PaymentAdjustmentStatus, PaymentAdjustmentType } from '../../common/enums/payment-adjustment.enum';
import { PaymentStatus } from '../../common/enums/payment-status.enum';

export type PaymentSnapshot = {
  id: number;
  amount: string;
  status: PaymentStatus;
  isDemo: boolean;
};

export type PaymentAdjustmentSnapshot = {
  id: number;
  type: PaymentAdjustmentType;
  amount: string;
  status: PaymentAdjustmentStatus;
  isDemo: boolean;
  settledAt: Date | null;
};

export type PendingRefundAdjustmentSnapshot = PaymentAdjustmentSnapshot & {
  order: {
    id: number;
    code: string;
    customerId: number;
    providerId: number | null;
    estimatedPrice: string;
    finalPrice: string | null;
  };
};

export abstract class PaymentQueryPort {
  abstract getOrderFinancials(orderId: number): Promise<{
    payment: PaymentSnapshot | null;
    adjustment: PaymentAdjustmentSnapshot | null;
  }>;

  abstract getAdjustment(
    manager: EntityManager,
    orderId: number,
  ): Promise<PaymentAdjustmentSnapshot | null>;

  abstract listPendingRefundAdjustments(limit: number): Promise<PendingRefundAdjustmentSnapshot[]>;
}
