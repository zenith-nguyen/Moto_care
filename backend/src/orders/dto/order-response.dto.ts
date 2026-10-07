import { ApiProperty } from '@nestjs/swagger';
import { OfferStatus } from '../../common/enums/offer-status.enum';
import { OrderStatus } from '../../common/enums/order-status.enum';
import { PaymentStatus } from '../../common/enums/payment-status.enum';
import { WeatherCategory } from '../../pricing/weather-category.enum';
import { PaymentAdjustmentStatus, PaymentAdjustmentType } from '../../common/enums/payment-adjustment.enum';
import { PriceProposalStatus } from '../../common/enums/price-proposal-status.enum';

export class WeatherPricingResponseDto {
  @ApiProperty({ example: '100000.00', description: 'Incident base price snapshot' })
  basePrice!: string;

  @ApiProperty({ example: '10000.00', description: 'Weather surcharge snapshot' })
  weatherSurcharge!: string;

  @ApiProperty({ example: '1.1000' })
  weatherMultiplier!: string;

  @ApiProperty({ enum: WeatherCategory })
  weatherCategory!: WeatherCategory;

  @ApiProperty({ enum: ['OPEN_METEO', 'FALLBACK'] })
  weatherSource!: 'OPEN_METEO' | 'FALLBACK';

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  weatherObservedAt!: Date | null;

  @ApiProperty({ type: Number, nullable: true })
  weatherCode!: number | null;

  @ApiProperty({ type: String, nullable: true, example: '1.20' })
  precipitationMm!: string | null;

  @ApiProperty({ type: String, nullable: true, example: '12.00' })
  windSpeedKmh!: string | null;

  @ApiProperty({ type: String, nullable: true, example: '20.00' })
  windGustKmh!: string | null;

  @ApiProperty({ type: String, nullable: true, example: 'Weather data by Open-Meteo.com' })
  attribution!: string | null;
}

export class OrderMatchResponseDto {
  @ApiProperty({ example: 1 })
  id!: number;

  @ApiProperty({ example: 'MC-a1b2c3d4e5f607182930' })
  code!: string;

  @ApiProperty({ enum: OrderStatus })
  status!: OrderStatus;

  @ApiProperty({ example: '100000.00', description: 'Decimal money value as a string' })
  estimatedPrice!: string;

  @ApiProperty({ type: WeatherPricingResponseDto })
  pricing!: WeatherPricingResponseDto;

  @ApiProperty()
  matched!: boolean;

  @ApiProperty({ type: String, nullable: true, format: 'date-time' })
  offerExpiresAt!: Date | null;

  @ApiProperty({ type: String, nullable: true })
  message!: string | null;
}

export class IncidentSummaryDto {
  @ApiProperty()
  id!: number;

  @ApiProperty()
  name!: string;
}

export class GeoPointResponseDto {
  @ApiProperty({ example: 'Point' })
  type!: 'Point';

  @ApiProperty({ example: [106.7009, 10.7769], description: '[longitude, latitude]' })
  coordinates!: [number, number];
}

export class OrderPaymentSummaryDto {
  @ApiProperty()
  id!: number;

  @ApiProperty({ example: '100000.00' })
  amount!: string;

  @ApiProperty({ enum: PaymentStatus })
  status!: PaymentStatus;

  @ApiProperty({ description: 'True means no bank transfer occurred' })
  isDemo!: boolean;
}

export class OrderDetailsResponseDto {
  @ApiProperty()
  id!: number;

  @ApiProperty()
  code!: string;

  @ApiProperty({ enum: OrderStatus })
  status!: OrderStatus;

  @ApiProperty()
  customerId!: number;

  @ApiProperty({ type: Number, nullable: true })
  providerId!: number | null;

  @ApiProperty({ type: IncidentSummaryDto })
  incidentType!: IncidentSummaryDto;

  @ApiProperty({ type: GeoPointResponseDto })
  customerLocation!: GeoPointResponseDto;

  @ApiProperty({ example: '100000.00' })
  estimatedPrice!: string;

  @ApiProperty({ type: WeatherPricingResponseDto })
  pricing!: WeatherPricingResponseDto;

  @ApiProperty({ example: '0.00' })
  extraCost!: string;

  @ApiProperty({ example: '0.00' })
  discountAmount!: string;

  @ApiProperty({ type: String, nullable: true })
  finalPrice!: string | null;

  @ApiProperty({ nullable: true, type: OrderPaymentSummaryDto })
  payment!: OrderPaymentSummaryDto | null;

  @ApiProperty({ nullable: true, type: GeoPointResponseDto, description: 'Current provider position only while driving or working' })
  providerLocation!: GeoPointResponseDto | null;

  @ApiProperty({ type: String, nullable: true })
  message!: string | null;

  @ApiProperty({ nullable: true, type: () => PriceProposalResponseDto })
  priceProposal!: PriceProposalResponseDto | null;

  @ApiProperty({ nullable: true, type: () => PaymentAdjustmentResponseDto })
  paymentAdjustment!: PaymentAdjustmentResponseDto | null;
}

export class PriceProposalResponseDto {
  @ApiProperty()
  id!: number;

  @ApiProperty({ example: '125000.00' })
  proposedFinalPrice!: string;

  @ApiProperty()
  reason!: string;

  @ApiProperty({ enum: PriceProposalStatus })
  status!: PriceProposalStatus;

  @ApiProperty({ nullable: true, type: String })
  customerReason!: string | null;

  @ApiProperty({ nullable: true, type: String })
  disputeReason!: string | null;

  @ApiProperty({ nullable: true, type: String })
  resolutionReason!: string | null;
}

export class PaymentAdjustmentResponseDto {
  @ApiProperty()
  id!: number;

  @ApiProperty({ enum: PaymentAdjustmentType })
  type!: PaymentAdjustmentType;

  @ApiProperty({ example: '25000.00' })
  amount!: string;

  @ApiProperty({ enum: PaymentAdjustmentStatus })
  status!: PaymentAdjustmentStatus;

  @ApiProperty()
  isDemo!: boolean;

  @ApiProperty({ nullable: true, type: String, format: 'date-time' })
  settledAt!: Date | null;
}

export class PendingOfferOrderDto {
  @ApiProperty()
  code!: string;

  @ApiProperty({ type: IncidentSummaryDto })
  incidentType!: IncidentSummaryDto;

  @ApiProperty({ example: '100000.00' })
  estimatedPrice!: string;

  @ApiProperty({ type: WeatherPricingResponseDto })
  pricing!: WeatherPricingResponseDto;

  @ApiProperty({ type: GeoPointResponseDto })
  customerLocation!: GeoPointResponseDto;
}

export class PendingOfferResponseDto {
  @ApiProperty()
  id!: number;

  @ApiProperty()
  orderId!: number;

  @ApiProperty({ format: 'date-time' })
  expiresAt!: Date;

  @ApiProperty({ type: PendingOfferOrderDto })
  order!: PendingOfferOrderDto;
}

export class AcceptOfferResponseDto {
  @ApiProperty()
  orderId!: number;

  @ApiProperty()
  providerId!: number;

  @ApiProperty({ enum: OrderStatus })
  status!: OrderStatus;

  @ApiProperty({ enum: OfferStatus })
  offerStatus!: OfferStatus;
}

export class RejectOfferResponseDto extends OrderMatchResponseDto {
  @ApiProperty()
  orderId!: number;

  @ApiProperty({ enum: OfferStatus })
  offerStatus!: OfferStatus;
}
