import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as argon2 from 'argon2';
import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';
import { DataSource, IsNull } from 'typeorm';
import { User } from '../users/user.entity';
import { MailService } from './mail.service';
import { PasswordResetCode } from './password-reset-code.entity';

const genericForgotResponse = {
  message: 'If the email is registered, a password reset code will be sent.',
};

@Injectable()
export class PasswordRecoveryService {
  private readonly logger = new Logger(PasswordRecoveryService.name);
  private readonly hashSecret: string;

  constructor(
    private readonly database: DataSource,
    private readonly mail: MailService,
    config: ConfigService,
  ) {
    this.hashSecret = config.get<string>('PASSWORD_RESET_HMAC_SECRET')
      ?? config.getOrThrow<string>('JWT_SECRET');
  }

  async forgot(emailInput: string) {
    const email = emailInput.trim().toLowerCase();
    const prepared = await this.database.transaction(async (manager) => {
      const user = await manager.getRepository(User).createQueryBuilder('user')
        .setLock('pessimistic_write')
        .where('LOWER(user.email) = :email', { email })
        .getOne();
      if (!user) return null;
      const latest = await manager.getRepository(PasswordResetCode).findOne({
        where: { userId: user.id }, order: { createdAt: 'DESC' },
      });
      if (latest && latest.createdAt.getTime() > Date.now() - 60_000) return null;
      await manager.getRepository(PasswordResetCode).update(
        { userId: user.id, usedAt: IsNull() }, { usedAt: new Date() },
      );
      const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
      const record = await manager.getRepository(PasswordResetCode).save(
        manager.getRepository(PasswordResetCode).create({
          userId: user.id,
          codeHash: this.hash(code),
          expiresAt: new Date(Date.now() + 10 * 60_000),
          usedAt: null,
        }),
      );
      return { recordId: record.id, email: user.email!, code };
    });

    if (prepared) {
      try {
        const sent = await this.mail.sendPasswordResetCode(prepared.email, prepared.code);
        if (!sent) await this.invalidate(prepared.recordId);
      } catch {
        await this.invalidate(prepared.recordId);
        this.logger.error('Password reset email delivery failed');
      }
    }
    return genericForgotResponse;
  }

  async reset(emailInput: string, code: string, newPassword: string) {
    const email = emailInput.trim().toLowerCase();
    const passwordHash = await argon2.hash(newPassword);
    const valid = await this.database.transaction(async (manager) => {
      const user = await manager.getRepository(User).createQueryBuilder('user')
        .setLock('pessimistic_write')
        .where('LOWER(user.email) = :email', { email })
        .getOne();
      if (!user) return false;
      const record = await manager.getRepository(PasswordResetCode).createQueryBuilder('reset')
        .setLock('pessimistic_write')
        .where('reset.user_id = :userId AND reset.used_at IS NULL', { userId: user.id })
        .orderBy('reset.created_at', 'DESC')
        .getOne();
      if (!record || record.expiresAt <= new Date() || record.attemptCount >= 5) return false;
      if (!this.matches(code, record.codeHash)) {
        record.attemptCount += 1;
        if (record.attemptCount >= 5) record.usedAt = new Date();
        await manager.getRepository(PasswordResetCode).save(record);
        return false;
      }
      await manager.getRepository(User).update(user.id, {
        passwordHash,
        authVersion: user.authVersion + 1,
        failedLoginAttempts: 0,
        lockedUntil: null,
      });
      await manager.getRepository(PasswordResetCode).update(
        { userId: user.id, usedAt: IsNull() }, { usedAt: new Date() },
      );
      return true;
    });
    if (!valid) throw new BadRequestException('Invalid or expired password reset code');
    return { message: 'Password reset successfully. Sign in again.' };
  }

  private hash(code: string): string {
    return createHmac('sha256', this.hashSecret).update(`password-reset:${code}`).digest('hex');
  }

  private matches(code: string, expectedHash: string): boolean {
    const actual = Buffer.from(this.hash(code), 'hex');
    const expected = Buffer.from(expectedHash, 'hex');
    return actual.length === expected.length && timingSafeEqual(actual, expected);
  }

  private async invalidate(id: number): Promise<void> {
    await this.database.getRepository(PasswordResetCode).update(id, { usedAt: new Date() });
  }
}
