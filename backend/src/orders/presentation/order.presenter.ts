import { OrderStatus } from '../../common/enums/order-status.enum';
import { PaymentAdjustmentStatus, PaymentAdjustmentType } from '../../common/enums/payment-adjustment.enum';
import { PriceProposalStatus } from '../../common/enums/price-proposal-status.enum';
import { OrderOffer } from '../order-offer.entity';
import { Order } from '../order.entity';

type PriceProposalView = {
  id: number;
  proposedFinalPrice: string;
  reason: string;
  status: PriceProposalStatus;
  customerReason: string | null;
  disputeReason: string | null;
  resolutionReason: string | null;
  decidedById: number | null;
  decidedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

type PaymentAdjustmentView = {
  id: number;
  type: PaymentAdjustmentType;
  amount: string;
  status: PaymentAdjustmentStatus;
  isDemo: boolean;
  settledAt: Date | null;
};

export function presentOrderPricing(order: Order) {
  return {
    basePrice: order.basePrice,
    weatherSurcharge: order.weatherSurcharge,
    weatherMultiplier: order.weatherMultiplier,
    weatherCategory: order.weatherCategory,
    weatherSource: order.weatherSource,
    weatherObservedAt: order.weatherObservedAt,
    weatherCode: order.weatherCode,
    precipitationMm: order.weatherPrecipitationMm,
    windSpeedKmh: order.weatherWindSpeedKmh,
    windGustKmh: order.weatherWindGustKmh,
    attribution: order.weatherSource === 'OPEN_METEO' ? 'Weather data by Open-Meteo.com' : null,
  };
}

export function presentOrderMatch(order: Order, offer: OrderOffer | null) {
  return {
    id: order.id,
    code: order.code,
    status: order.status,
    estimatedPrice: order.estimatedPrice,
    pricing: presentOrderPricing(order),
    matched: offer !== null,
    offerExpiresAt: offer?.expiresAt ?? null,
    message: order.status === OrderStatus.AWAITING_PREPAYMENT
      ? 'Awaiting prepayment; no provider has been offered this order'
      : offer ? null : 'No provider found yet; retry matching later',
  };
}

export function presentPriceProposal(proposal: PriceProposalView) {
  return {
    id: proposal.id,
    proposedFinalPrice: proposal.proposedFinalPrice,
    reason: proposal.reason,
    status: proposal.status,
    customerReason: proposal.customerReason,
    disputeReason: proposal.disputeReason,
    resolutionReason: proposal.resolutionReason,
    decidedById: proposal.decidedById,
    decidedAt: proposal.decidedAt,
    createdAt: proposal.createdAt,
    updatedAt: proposal.updatedAt,
  };
}

export function presentPaymentAdjustment(adjustment: PaymentAdjustmentView) {
  return {
    id: adjustment.id,
    type: adjustment.type,
    amount: adjustment.amount,
    status: adjustment.status,
    isDemo: adjustment.isDemo,
    settledAt: adjustment.settledAt,
  };
}
