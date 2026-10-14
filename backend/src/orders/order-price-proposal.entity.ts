import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { PriceProposalStatus } from '../common/enums/price-proposal-status.enum';
import { Provider } from '../providers/provider.entity';
import { User } from '../users/user.entity';
import { Order } from './order.entity';

@Entity({ name: 'order_price_proposals' })
@Index('IDX_order_price_proposals_order_status', ['orderId', 'status'])
export class OrderPriceProposal {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'order_id' })
  orderId!: number;

  @ManyToOne(() => Order, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order!: Order;

  @Column({ name: 'provider_id' })
  providerId!: number;

  @ManyToOne(() => Provider, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'provider_id' })
  provider!: Provider;

  @Column({ name: 'proposed_final_price', type: 'numeric', precision: 12, scale: 2 })
  proposedFinalPrice!: string;

  @Column({ type: 'text' })
  reason!: string;

  @Column({ type: 'enum', enum: PriceProposalStatus, default: PriceProposalStatus.PENDING })
  status!: PriceProposalStatus;

  @Column({ name: 'customer_reason', type: 'text', nullable: true })
  customerReason!: string | null;

  @Column({ name: 'dispute_reason', type: 'text', nullable: true })
  disputeReason!: string | null;

  @Column({ name: 'resolution_reason', type: 'text', nullable: true })
  resolutionReason!: string | null;

  @Column({ name: 'decided_by', type: 'integer', nullable: true })
  decidedById!: number | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'decided_by' })
  decidedBy!: User | null;

  @Column({ name: 'decided_at', type: 'timestamptz', nullable: true })
  decidedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
