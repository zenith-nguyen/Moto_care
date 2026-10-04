import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { OfferStatus } from '../common/enums/offer-status.enum';
import { Provider } from '../providers/provider.entity';
import { Order } from './order.entity';

@Entity({ name: 'order_offers' })
@Index('UQ_order_offers_order_provider', ['orderId', 'providerId'], { unique: true })
@Index('IDX_order_offers_order_status', ['orderId', 'status'])
@Index('IDX_order_offers_provider_status', ['providerId', 'status'])
export class OrderOffer {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'order_id' })
  orderId!: number;

  @ManyToOne(() => Order, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order!: Order;

  @Column({ name: 'provider_id' })
  providerId!: number;

  @ManyToOne(() => Provider, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'provider_id' })
  provider!: Provider;

  @Column({ type: 'enum', enum: OfferStatus, default: OfferStatus.PENDING })
  status!: OfferStatus;

  @Column({ name: 'offered_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  offeredAt!: Date;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt!: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
