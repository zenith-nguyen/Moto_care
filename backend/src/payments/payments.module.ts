import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WithdrawalRequest } from './withdrawal-request.entity';
import { OrdersModule } from '../orders/orders.module';
import { DemoPaymentsController } from './demo-payments.controller';
import { DemoPaymentsService } from './demo-payments.service';
import { RealtimeModule } from '../realtime/realtime.module';
import { WalletsController } from './wallets.controller';
import { WithdrawalsController } from './withdrawals.controller';
import { WithdrawalsService } from './withdrawals.service';
import { PaymentAccountingModule } from './payment-accounting.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([WithdrawalRequest]),
    PaymentAccountingModule,
    OrdersModule,
    RealtimeModule,
  ],
  controllers: [DemoPaymentsController, WalletsController, WithdrawalsController],
  providers: [DemoPaymentsService, WithdrawalsService],
  exports: [WithdrawalsService],
})
export class PaymentsModule {}
