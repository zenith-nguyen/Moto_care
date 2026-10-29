import { UnauthorizedException } from '@nestjs/common';
import { createHash, createHmac, timingSafeEqual } from 'node:crypto';

export function verifySepayWebhook(command: {
  rawBody: Buffer | undefined;
  timestamp: string | undefined;
  signature: string | undefined;
  secret: string;
  maxAgeSeconds: number;
}): string {
  if (!command.rawBody || !command.timestamp || !command.signature) {
    throw new UnauthorizedException('Invalid webhook signature');
  }
  if (!/^\d{10}$/.test(command.timestamp) || !/^sha256=[a-f0-9]{64}$/i.test(command.signature)) {
    throw new UnauthorizedException('Invalid webhook signature');
  }

  const timestamp = Number(command.timestamp);
  if (!Number.isSafeInteger(timestamp) || Math.abs(Math.floor(Date.now() / 1000) - timestamp) > command.maxAgeSeconds) {
    throw new UnauthorizedException('Expired webhook timestamp');
  }

  const expected = createHmac('sha256', command.secret)
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
