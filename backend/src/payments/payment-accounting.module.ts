import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PaymentQueryPort } from './application/payment-query.port';
import { PaymentSettlementPort } from './application/payment-settlement.port';
import { TypeOrmPaymentAccountingAdapter } from './infrastructure/typeorm-payment-accounting.adapter';
import { PaymentAdjustment } from './payment-adjustment.entity';
import { Payment } from './payment.entity';
import { WalletTransaction } from './wallet-transaction.entity';
import { Wallet } from './wallet.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Payment, PaymentAdjustment, Wallet, WalletTransaction])],
  providers: [
    TypeOrmPaymentAccountingAdapter,
    { provide: PaymentSettlementPort, useExisting: TypeOrmPaymentAccountingAdapter },
    { provide: PaymentQueryPort, useExisting: TypeOrmPaymentAccountingAdapter },
  ],
  exports: [PaymentSettlementPort, PaymentQueryPort],
})
export class PaymentAccountingModule {}
