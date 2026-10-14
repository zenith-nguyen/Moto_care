import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { WalletTransactionType } from '../common/enums/wallet-transaction-type.enum';
import { Order } from '../orders/order.entity';
import { WithdrawalRequest } from './withdrawal-request.entity';
import { Wallet } from './wallet.entity';

@Entity({ name: 'wallet_transactions' })
@Index('IDX_wallet_transactions_wallet_created', ['walletId', 'createdAt'])
@Index('IDX_wallet_transactions_order', ['orderId'])
@Index('IDX_wallet_transactions_withdrawal', ['withdrawalId'])
export class WalletTransaction {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'wallet_id' })
  walletId!: number;

  @ManyToOne(() => Wallet, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'wallet_id' })
  wallet!: Wallet;

  @Column({ type: 'enum', enum: WalletTransactionType })
  type!: WalletTransactionType;

  @Column({ type: 'numeric', precision: 14, scale: 2 })
  amount!: string;

  @Column({ name: 'order_id', type: 'integer', nullable: true })
  orderId!: number | null;

  @ManyToOne(() => Order, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'order_id' })
  order!: Order | null;

  @Column({ name: 'withdrawal_id', type: 'integer', nullable: true })
  withdrawalId!: number | null;

  @ManyToOne(() => WithdrawalRequest, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'withdrawal_id' })
  withdrawal!: WithdrawalRequest | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
