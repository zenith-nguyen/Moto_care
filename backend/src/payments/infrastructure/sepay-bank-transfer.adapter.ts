import { ConflictException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { moneyToCents } from '../../common/utils/money';
import { BankTransferGateway, BankTransferInstructions } from '../application/bank-transfer.gateway';
import { verifySepayWebhook } from './sepay-webhook-auth';

@Injectable()
export class SepayBankTransferAdapter implements BankTransferGateway {
  constructor(private readonly config: ConfigService) {}

  createInstructions(command: { paymentId: number; amount: string }): BankTransferInstructions {
    const cents = moneyToCents(command.amount);
    if (cents % 100n !== 0n) {
      throw new ConflictException('Bank transfer amount must be a whole VND value');
    }

    const bank = this.config.getOrThrow<string>('SEPAY_BANK');
    const accountNumber = this.config.getOrThrow<string>('SEPAY_ACCOUNT_NUMBER');
    const mode = this.config.getOrThrow<'test' | 'live'>('SEPAY_MODE');
    if (mode === 'test' && !/^SBSEPAY[A-Z0-9]{12}$/.test(accountNumber)) {
      throw new ConflictException('SePay Test mode QR requires an official SBSEPAY virtual account');
    }
    const accountHolder = this.config.getOrThrow<string>('SEPAY_ACCOUNT_HOLDER');
    const paymentCode = this.paymentCode(command.paymentId);
    const memoPrefix = this.config.get<string>('SEPAY_TRANSFER_MEMO_PREFIX', '').trim();
    const transferContent = [memoPrefix, paymentCode].filter(Boolean).join(' ');
    const parameters = new URLSearchParams({
      acc: accountNumber,
      bank,
      amount: (cents / 100n).toString(),
      des: transferContent,
      template: 'compact',
      showinfo: 'true',
      holder: accountHolder,
    });

    return {
      provider: 'SEPAY',
      mode,
      simulationOnly: mode === 'test',
      paymentCode,
      amount: command.amount,
      bank,
      accountNumber,
      accountHolder,
      transferContent,
      qrImageUrl: `https://vietqr.app/img?${parameters.toString()}`,
    };
  }

  verifyWebhook(command: {
    rawBody: Buffer | undefined;
    timestamp: string | undefined;
    signature: string | undefined;
  }): string {
    return verifySepayWebhook({
      ...command,
      secret: this.config.getOrThrow<string>('SEPAY_WEBHOOK_SECRET'),
      maxAgeSeconds: this.config.getOrThrow<number>('SEPAY_WEBHOOK_MAX_AGE_SECONDS'),
    });
  }

  paymentCode(paymentId: number): string {
    return `${this.config.getOrThrow<string>('SEPAY_PAYMENT_CODE_PREFIX')}${paymentId}`;
  }
}
