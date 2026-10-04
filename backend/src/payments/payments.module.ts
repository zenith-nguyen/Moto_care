import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Payment } from './payment.entity';
import { WalletTransaction } from './wallet-transaction.entity';
import { Wallet } from './wallet.entity';
import { WithdrawalRequest } from './withdrawal-request.entity';

@Module({ imports: [TypeOrmModule.forFeature([Payment, Wallet, WalletTransaction, WithdrawalRequest])] })
export class PaymentsModule {}
