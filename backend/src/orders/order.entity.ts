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

  @Column({ name: 'extra_cost', type: 'numeric', precision: 12, scale: 2, default: 0 })
  extraCost!: string;

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
