import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Payment } from './payment.entity';
import { WalletTransaction } from './wallet-transaction.entity';
import { Wallet } from './wallet.entity';
import { WithdrawalRequest } from './withdrawal-request.entity';
import { OrdersModule } from '../orders/orders.module';
import { DemoPaymentsController } from './demo-payments.controller';
import { DemoPaymentsService } from './demo-payments.service';
import { RealtimeModule } from '../realtime/realtime.module';
import { WalletsController } from './wallets.controller';
import { PaymentAdjustment } from './payment-adjustment.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Payment, PaymentAdjustment, Wallet, WalletTransaction, WithdrawalRequest]), OrdersModule, RealtimeModule],
  controllers: [DemoPaymentsController, WalletsController],
  providers: [DemoPaymentsService],
})
export class PaymentsModule {}
