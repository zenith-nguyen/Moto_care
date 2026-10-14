import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { PaymentAdjustmentStatus, PaymentAdjustmentType } from '../common/enums/payment-adjustment.enum';
import { Order } from '../orders/order.entity';
import { Payment } from './payment.entity';

@Entity({ name: 'payment_adjustments' })
@Index('UQ_payment_adjustments_order', ['orderId'], { unique: true })
@Index('IDX_payment_adjustments_status_type', ['status', 'type'])
export class PaymentAdjustment {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'order_id' })
  orderId!: number;

  @ManyToOne(() => Order, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'order_id' })
  order!: Order;

  @Column({ name: 'payment_id' })
  paymentId!: number;

  @ManyToOne(() => Payment, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'payment_id' })
  payment!: Payment;

  @Column({ type: 'enum', enum: PaymentAdjustmentType })
  type!: PaymentAdjustmentType;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  amount!: string;

  @Column({ type: 'enum', enum: PaymentAdjustmentStatus, default: PaymentAdjustmentStatus.PENDING })
  status!: PaymentAdjustmentStatus;

  @Column({ name: 'is_demo', type: 'boolean', default: false })
  isDemo!: boolean;

  @Column({ name: 'settled_at', type: 'timestamptz', nullable: true })
  settledAt!: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
