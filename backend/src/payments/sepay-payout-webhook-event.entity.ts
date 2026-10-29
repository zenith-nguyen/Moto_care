import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { WithdrawalPayout } from './withdrawal-payout.entity';

export type SepayPayoutWebhookOutcome =
  | 'MANUAL_REVIEW_REQUIRED'
  | 'IGNORED_ACCOUNT'
  | 'IGNORED_DIRECTION'
  | 'IGNORED_PAYOUT_CODE'
  | 'PAYOUT_NOT_FOUND'
  | 'AMOUNT_MISMATCH'
  | 'MULTIPLE_TRANSACTIONS'
  | 'ALREADY_RECONCILED';

@Entity({ name: 'sepay_payout_webhook_events' })
@Index('UQ_sepay_payout_webhook_events_transaction', ['externalTransactionId'], { unique: true })
@Index('IDX_sepay_payout_webhook_events_outcome_received', ['outcome', 'receivedAt'])
export class SepayPayoutWebhookEvent {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'external_transaction_id', type: 'varchar', length: 120, unique: true })
  externalTransactionId!: string;

  @Column({ name: 'payout_id', type: 'integer', nullable: true })
  payoutId!: number | null;

  @ManyToOne(() => WithdrawalPayout, { nullable: true, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'payout_id' })
  payout!: WithdrawalPayout | null;

  @Column({ name: 'payout_code', type: 'varchar', length: 40, nullable: true })
  payoutCode!: string | null;

  @Column({ name: 'reference_code', type: 'varchar', length: 120, nullable: true })
  referenceCode!: string | null;

  @Column({ type: 'numeric', precision: 14, scale: 2 })
  amount!: string;

  @Column({ name: 'payload_sha256', type: 'char', length: 64 })
  payloadSha256!: string;

  @Column({ type: 'varchar', length: 40 })
  outcome!: SepayPayoutWebhookOutcome;

  @CreateDateColumn({ name: 'received_at' })
  receivedAt!: Date;
}
