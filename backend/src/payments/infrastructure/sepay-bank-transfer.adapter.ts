import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, createHmac, timingSafeEqual } from 'node:crypto';
import { moneyToCents } from '../../common/utils/money';
import { BankTransferGateway, BankTransferInstructions } from '../application/bank-transfer.gateway';

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
    if (!/^SBSEPAY[A-Z0-9]{12}$/.test(accountNumber)) {
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
      mode: 'test',
      simulationOnly: true,
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
    if (!command.rawBody || !command.timestamp || !command.signature) {
      throw new UnauthorizedException('Invalid webhook signature');
    }
    if (!/^\d{10}$/.test(command.timestamp) || !/^sha256=[a-f0-9]{64}$/i.test(command.signature)) {
      throw new UnauthorizedException('Invalid webhook signature');
    }

    const timestamp = Number(command.timestamp);
    const maxAge = this.config.getOrThrow<number>('SEPAY_WEBHOOK_MAX_AGE_SECONDS');
    if (!Number.isSafeInteger(timestamp) || Math.abs(Math.floor(Date.now() / 1000) - timestamp) > maxAge) {
      throw new UnauthorizedException('Expired webhook timestamp');
    }

    const expected = createHmac('sha256', this.config.getOrThrow<string>('SEPAY_WEBHOOK_SECRET'))
      .update(command.timestamp)
      .update('.')
      .update(command.rawBody)
      .digest();
    const received = Buffer.from(command.signature.slice('sha256='.length), 'hex');
    if (received.length !== expected.length || !timingSafeEqual(received, expected)) {
      throw new UnauthorizedException('Invalid webhook signature');
    }
    return createHash('sha256').update(command.rawBody).digest('hex');
  }

  paymentCode(paymentId: number): string {
    return `${this.config.getOrThrow<string>('SEPAY_PAYMENT_CODE_PREFIX')}${paymentId}`;
  }
}
