import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { Payment } from './payment.entity';

export type SepayWebhookOutcome =
  | 'APPLIED'
  | 'IGNORED_ACCOUNT'
  | 'IGNORED_DIRECTION'
  | 'IGNORED_PAYMENT_CODE'
  | 'PAYMENT_NOT_FOUND'
  | 'AMOUNT_MISMATCH'
  | 'PAYMENT_NOT_PENDING';

@Entity({ name: 'sepay_webhook_events' })
@Index('UQ_sepay_webhook_events_transaction', ['externalTransactionId'], {
  unique: true,
})
@Index('IDX_sepay_webhook_events_outcome_received', ['outcome', 'receivedAt'])
export class SepayWebhookEvent {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({
    name: 'external_transaction_id',
    type: 'varchar',
    length: 120,
    unique: true,
  })
  externalTransactionId!: string;

  @Column({ name: 'payment_id', type: 'integer', nullable: true })
  paymentId!: number | null;

  @ManyToOne(() => Payment, { nullable: true, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'payment_id' })
  payment!: Payment | null;

  @Column({ name: 'payment_code', type: 'varchar', length: 40, nullable: true })
  paymentCode!: string | null;

  @Column({
    name: 'reference_code',
    type: 'varchar',
    length: 120,
    nullable: true,
  })
  referenceCode!: string | null;

  @Column({ type: 'numeric', precision: 14, scale: 2 })
  amount!: string;

  @Column({ name: 'payload_sha256', type: 'char', length: 64 })
  payloadSha256!: string;

  @Column({ type: 'varchar', length: 40 })
  outcome!: SepayWebhookOutcome;

  @CreateDateColumn({ name: 'received_at' })
  receivedAt!: Date;
}
