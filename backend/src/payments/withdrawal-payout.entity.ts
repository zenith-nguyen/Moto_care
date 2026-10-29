import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { WithdrawalPayoutStatus } from '../common/enums/withdrawal-payout-status.enum';
import { WithdrawalRequest } from './withdrawal-request.entity';

@Entity({ name: 'withdrawal_payouts' })
@Index('UQ_withdrawal_payouts_withdrawal', ['withdrawalId'], { unique: true })
@Index('UQ_withdrawal_payouts_code', ['payoutCode'], { unique: true })
@Index('IDX_withdrawal_payouts_status_created', ['status', 'createdAt'])
export class WithdrawalPayout {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'withdrawal_id', type: 'integer', unique: true })
  withdrawalId!: number;

  @OneToOne(() => WithdrawalRequest, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'withdrawal_id' })
  withdrawal!: WithdrawalRequest;

  @Column({ name: 'payout_code', type: 'varchar', length: 40, unique: true })
  payoutCode!: string;

  @Column({ name: 'expected_amount', type: 'numeric', precision: 14, scale: 2 })
  expectedAmount!: string;

  @Column({ type: 'enum', enum: WithdrawalPayoutStatus, default: WithdrawalPayoutStatus.AWAITING_TRANSFER })
  status!: WithdrawalPayoutStatus;

  @Column({ name: 'external_transaction_id', type: 'varchar', length: 120, nullable: true, unique: true })
  externalTransactionId!: string | null;

  @Column({ name: 'external_reference_code', type: 'varchar', length: 120, nullable: true })
  externalReferenceCode!: string | null;

  @Column({ name: 'observed_amount', type: 'numeric', precision: 14, scale: 2, nullable: true })
  observedAmount!: string | null;

  @Column({ name: 'review_reason', type: 'varchar', length: 500, nullable: true })
  reviewReason!: string | null;

  @Column({ name: 'reconciled_by', type: 'integer', nullable: true })
  reconciledById!: number | null;

  @Column({ name: 'reconciled_at', type: 'timestamptz', nullable: true })
  reconciledAt!: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
