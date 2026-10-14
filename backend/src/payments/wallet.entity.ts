import { Column, CreateDateColumn, Entity, Index, JoinColumn, OneToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { Provider } from '../providers/provider.entity';

@Entity({ name: 'wallets' })
@Index('UQ_wallets_provider_id', ['providerId'], { unique: true })
export class Wallet {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'provider_id' })
  providerId!: number;

  @OneToOne(() => Provider, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'provider_id' })
  provider!: Provider;

  @Column({ type: 'numeric', precision: 14, scale: 2, default: 0 })
  balance!: string;

  @Column({ name: 'locked_balance', type: 'numeric', precision: 14, scale: 2, default: 0 })
  lockedBalance!: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
