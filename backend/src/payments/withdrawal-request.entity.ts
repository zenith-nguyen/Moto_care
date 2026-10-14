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
import { WithdrawalStatus } from '../common/enums/withdrawal-status.enum';
import { Provider } from '../providers/provider.entity';
import { User } from '../users/user.entity';

@Entity({ name: 'withdrawal_requests' })
@Index('IDX_withdrawal_requests_provider_status', ['providerId', 'status'])
@Index('IDX_withdrawal_requests_status_created', ['status', 'createdAt'])
export class WithdrawalRequest {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'provider_id' })
  providerId!: number;

  @ManyToOne(() => Provider, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'provider_id' })
  provider!: Provider;

  @Column({ type: 'numeric', precision: 14, scale: 2 })
  amount!: string;

  @Column({ type: 'enum', enum: WithdrawalStatus, default: WithdrawalStatus.PENDING })
  status!: WithdrawalStatus;

  @Column({ name: 'processed_by', type: 'integer', nullable: true })
  processedById!: number | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'processed_by' })
  processedBy!: User | null;

  @Column({ name: 'processed_at', type: 'timestamptz', nullable: true })
  processedAt!: Date | null;

  @Column({ name: 'decision_reason', type: 'text', nullable: true })
  decisionReason!: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
