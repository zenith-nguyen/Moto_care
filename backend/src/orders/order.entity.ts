import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { GeoPoint } from '../providers/provider.entity';
import { User } from '../users/user.entity';
import { IncidentType } from '../incident-types/incident-type.entity';
import { Provider } from '../providers/provider.entity';
import { WeatherCategory } from '../pricing/weather-category.enum';

@Entity({ name: 'orders' })
@Index('UQ_orders_code', ['code'], { unique: true })
@Index('IDX_orders_status', ['status'])
@Index('IDX_orders_customer_status', ['customerId', 'status'])
@Index('IDX_orders_provider_status', ['providerId', 'status'])
export class Order {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ length: 30 })
  code!: string;

  @Column({ name: 'customer_id' })
  customerId!: number;

  @ManyToOne(() => User, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'customer_id' })
  customer!: User;

  @Column({ name: 'provider_id', type: 'integer', nullable: true })
  providerId!: number | null;

  @ManyToOne(() => Provider, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'provider_id' })
  provider!: Provider | null;

  @Column({ name: 'incident_type_id' })
  incidentTypeId!: number;

  @ManyToOne(() => IncidentType, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'incident_type_id' })
  incidentType!: IncidentType;

  @Column({ type: 'enum', enum: OrderStatus, default: OrderStatus.PENDING_MATCH })
  status!: OrderStatus;

  @Column({
    name: 'customer_location',
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
  })
  customerLocation!: GeoPoint;

  @Column({ name: 'estimated_price', type: 'numeric', precision: 12, scale: 2 })
  estimatedPrice!: string;

  @Column({ name: 'base_price', type: 'numeric', precision: 12, scale: 2 })
  basePrice!: string;

  @Column({ name: 'weather_surcharge', type: 'numeric', precision: 12, scale: 2, default: 0 })
  weatherSurcharge!: string;

  @Column({ name: 'weather_multiplier', type: 'numeric', precision: 5, scale: 4, default: 1 })
  weatherMultiplier!: string;

  @Column({ name: 'weather_category', type: 'varchar', length: 20, default: WeatherCategory.DISABLED })
  weatherCategory!: WeatherCategory;

  @Column({ name: 'weather_source', type: 'varchar', length: 30, default: 'FALLBACK' })
  weatherSource!: 'OPEN_METEO' | 'FALLBACK';

  @Column({ name: 'weather_observed_at', type: 'timestamptz', nullable: true })
  weatherObservedAt!: Date | null;

  @Column({ name: 'weather_code', type: 'smallint', nullable: true })
  weatherCode!: number | null;

  @Column({ name: 'weather_precipitation_mm', type: 'numeric', precision: 7, scale: 2, nullable: true })
  weatherPrecipitationMm!: string | null;

  @Column({ name: 'weather_wind_speed_kmh', type: 'numeric', precision: 7, scale: 2, nullable: true })
  weatherWindSpeedKmh!: string | null;

  @Column({ name: 'weather_wind_gust_kmh', type: 'numeric', precision: 7, scale: 2, nullable: true })
  weatherWindGustKmh!: string | null;

  @Column({ name: 'extra_cost', type: 'numeric', precision: 12, scale: 2, default: 0 })
  extraCost!: string;

  @Column({ name: 'discount_amount', type: 'numeric', precision: 12, scale: 2, default: 0 })
  discountAmount!: string;

  @Column({ name: 'final_price', type: 'numeric', precision: 12, scale: 2, nullable: true })
  finalPrice!: string | null;

  @Column({ name: 'cancel_reason', type: 'text', nullable: true })
  cancelReason!: string | null;

  @Column({ name: 'cancelled_by', type: 'integer', nullable: true })
  cancelledById!: number | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'cancelled_by' })
  cancelledBy!: User | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
