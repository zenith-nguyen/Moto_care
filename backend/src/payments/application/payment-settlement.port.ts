import { EntityManager } from 'typeorm';

export type PreServiceCancellationResult = {
  requiresRefund: boolean;
  refundAmount: string | null;
};

export type FinalPricePaymentPlan = {
  finalPrice: string;
  extraCost: string;
  discountAmount: string;
  requiresAdjustment: boolean;
};

export abstract class PaymentSettlementPort {
  abstract createPrepayment(
    manager: EntityManager,
    command: { orderId: number; amount: string },
  ): Promise<void>;

  abstract cancelBeforeService(
    manager: EntityManager,
    orderId: number,
  ): Promise<PreServiceCancellationResult>;

  abstract prepareFinalPrice(
    manager: EntityManager,
    command: { orderId: number; finalPrice: string },
  ): Promise<FinalPricePaymentPlan>;

  abstract settleProviderEarnings(
    manager: EntityManager,
    command: {
      orderId: number;
      providerId: number;
      estimatedPrice: string;
      finalPrice: string;
    },
  ): Promise<void>;
}
