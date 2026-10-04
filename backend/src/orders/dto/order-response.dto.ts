import { ApiProperty } from '@nestjs/swagger';
import { OfferStatus } from '../../common/enums/offer-status.enum';
import { OrderStatus } from '../../common/enums/order-status.enum';

export class OrderMatchResponseDto {
  @ApiProperty({ example: 1 })
  id!: number;

  @ApiProperty({ example: 'MC-a1b2c3d4e5f607182930' })
  code!: string;

  @ApiProperty({ enum: OrderStatus })
  status!: OrderStatus;

  @ApiProperty({ example: '100000.00', description: 'Decimal money value as a string' })
  estimatedPrice!: string;

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

  @ApiProperty({ example: '0.00' })
  extraCost!: string;

  @ApiProperty({ type: String, nullable: true })
  finalPrice!: string | null;

  @ApiProperty({ type: String, nullable: true })
  message!: string | null;
}

export class PendingOfferOrderDto {
  @ApiProperty()
  code!: string;

  @ApiProperty({ type: IncidentSummaryDto })
  incidentType!: IncidentSummaryDto;

  @ApiProperty({ example: '100000.00' })
  estimatedPrice!: string;

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
