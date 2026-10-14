import { ConfigService } from '@nestjs/config';
import { createHmac } from 'node:crypto';
import { SepayBankTransferAdapter } from './sepay-bank-transfer.adapter';

describe('SepayBankTransferAdapter', () => {
  const secret = 'test-only-sepay-webhook-secret-32-characters';
  const adapter = new SepayBankTransferAdapter(
    new ConfigService({
      SEPAY_BANK: 'MBBank',
      SEPAY_ACCOUNT_NUMBER: 'SBSEPAYX9KA2B7MN4QR',
      SEPAY_ACCOUNT_HOLDER: 'MOTOCARE DEMO',
      SEPAY_PAYMENT_CODE_PREFIX: 'MC',
      SEPAY_TRANSFER_MEMO_PREFIX: '',
      SEPAY_WEBHOOK_SECRET: secret,
      SEPAY_WEBHOOK_MAX_AGE_SECONDS: 300,
    }),
  );

  it('builds exact-amount VietQR instructions without exposing a secret', () => {
    const result = adapter.createInstructions({ paymentId: 42, amount: '100000.00' });

    expect(result).toMatchObject({
      provider: 'SEPAY',
      mode: 'test',
      simulationOnly: true,
      paymentCode: 'MC42',
      amount: '100000.00',
      transferContent: 'MC42',
    });
    const qr = new URL(result.qrImageUrl);
    expect(qr.origin).toBe('https://vietqr.app');
    expect(qr.searchParams.get('amount')).toBe('100000');
    expect(qr.searchParams.get('des')).toBe('MC42');
    expect(result.qrImageUrl).not.toContain(secret);
  });

  it('refuses to build a QR for a real-looking bank account', () => {
    const unsafeAdapter = new SepayBankTransferAdapter(
      new ConfigService({
        SEPAY_BANK: 'MBBank',
        SEPAY_ACCOUNT_NUMBER: '0123456789',
        SEPAY_ACCOUNT_HOLDER: 'MOTOCARE DEMO',
        SEPAY_PAYMENT_CODE_PREFIX: 'MC',
        SEPAY_TRANSFER_MEMO_PREFIX: '',
      }),
    );

    expect(() => unsafeAdapter.createInstructions({ paymentId: 42, amount: '100000.00' })).toThrow(
      'official SBSEPAY virtual account',
    );
  });

  it('verifies the official timestamp dot raw-body HMAC and returns only a payload hash', () => {
    const rawBody = Buffer.from('{"id":12345,"content":"MC42"}');
    const timestamp = String(Math.floor(Date.now() / 1000));
    const signature = `sha256=${createHmac('sha256', secret)
      .update(timestamp)
      .update('.')
      .update(rawBody)
      .digest('hex')}`;

    expect(adapter.verifyWebhook({ rawBody, timestamp, signature })).toMatch(/^[a-f0-9]{64}$/);
    expect(() =>
      adapter.verifyWebhook({
        rawBody: Buffer.from('{"id":12345,"content":"changed"}'),
        timestamp,
        signature,
      }),
    ).toThrow('Invalid webhook signature');
  });

  it('rejects a correctly signed request outside the replay window', () => {
    const rawBody = Buffer.from('{"id":12345}');
    const timestamp = String(Math.floor(Date.now() / 1000) - 301);
    const signature = `sha256=${createHmac('sha256', secret)
      .update(timestamp)
      .update('.')
      .update(rawBody)
      .digest('hex')}`;

    expect(() => adapter.verifyWebhook({ rawBody, timestamp, signature })).toThrow('Expired webhook timestamp');
  });
});
