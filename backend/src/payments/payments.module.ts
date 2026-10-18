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
import { Payment } from './payment.entity';
import { SepayWebhookEvent } from './sepay-webhook-event.entity';
import { BankTransferGateway } from './application/bank-transfer.gateway';
import { SepayBankTransferAdapter } from './infrastructure/sepay-bank-transfer.adapter';
import { SepayPaymentsService } from './sepay-payments.service';
import { SepayPaymentsController } from './sepay-payments.controller';
import { WithdrawalPayout } from './withdrawal-payout.entity';
import { SepayPayoutWebhookEvent } from './sepay-payout-webhook-event.entity';
import { PayoutReconciliationService } from './payout-reconciliation.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      WithdrawalRequest,
      WithdrawalPayout,
      SepayPayoutWebhookEvent,
      Payment,
      SepayWebhookEvent,
    ]),
    PaymentAccountingModule,
    OrdersModule,
    RealtimeModule,
  ],
  controllers: [DemoPaymentsController, SepayPaymentsController, WalletsController, WithdrawalsController],
  providers: [
    DemoPaymentsService,
    WithdrawalsService,
    SepayBankTransferAdapter,
    { provide: BankTransferGateway, useExisting: SepayBankTransferAdapter },
    SepayPaymentsService,
    PayoutReconciliationService,
  ],
  exports: [WithdrawalsService, PayoutReconciliationService],
})
export class PaymentsModule {}
