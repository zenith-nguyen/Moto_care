import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { PaymentStatus } from '../common/enums/payment-status.enum';
import { Order } from '../orders/order.entity';

@Entity({ name: 'payments' })
@Index('UQ_payments_sepay_transaction_id', ['sepayTransactionId'], { unique: true })
@Index('IDX_payments_order_status', ['orderId', 'status'])
export class Payment {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'order_id' })
  orderId!: number;

  @ManyToOne(() => Order, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'order_id' })
  order!: Order;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  amount!: string;

  @Column({ name: 'sepay_transaction_id', type: 'varchar', length: 120, unique: true, nullable: true })
  sepayTransactionId!: string | null;

  @Column({ type: 'enum', enum: PaymentStatus, default: PaymentStatus.PENDING })
  status!: PaymentStatus;

  @Column({ name: 'paid_at', type: 'timestamptz', nullable: true })
  paidAt!: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
