import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer, { Transporter } from 'nodemailer';
import { buildPasswordResetEmail } from './password-reset-email';

@Injectable()
export class MailService implements OnModuleInit {
  private readonly logger = new Logger(MailService.name);
  private readonly transporter: Transporter | null;
  private readonly from: string;

  constructor(private readonly config: ConfigService) {
    this.from = config.get<string>('SMTP_FROM') ?? 'Revo <no-reply@localhost>';
    this.transporter = config.get<boolean>('EMAIL_ENABLED')
      ? nodemailer.createTransport({
          host: config.getOrThrow<string>('SMTP_HOST'),
          port: config.getOrThrow<number>('SMTP_PORT'),
          secure: config.get<boolean>('SMTP_SECURE') ?? false,
          requireTLS: !(config.get<boolean>('SMTP_SECURE') ?? false),
          connectionTimeout: config.getOrThrow<number>('SMTP_CONNECTION_TIMEOUT_MS'),
          greetingTimeout: config.getOrThrow<number>('SMTP_CONNECTION_TIMEOUT_MS'),
          socketTimeout: config.getOrThrow<number>('SMTP_SOCKET_TIMEOUT_MS'),
          auth: {
            user: config.getOrThrow<string>('SMTP_USER'),
            pass: config.getOrThrow<string>('SMTP_PASSWORD'),
          },
        })
      : null;
  }

  async onModuleInit(): Promise<void> {
    if (!this.transporter) return;
    await this.verifyConnection();
    this.logger.log('SMTP connection verified');
  }

  get enabled(): boolean {
    return this.transporter !== null;
  }

  async verifyConnection(): Promise<void> {
    if (!this.transporter) throw new Error('Email delivery is disabled');
    await this.transporter.verify();
  }

  async sendPasswordResetCode(email: string, code: string): Promise<boolean> {
    if (!this.transporter) {
      this.logger.warn('Password reset email skipped because EMAIL_ENABLED=false');
      return false;
    }
    const message = buildPasswordResetEmail(code);
    await this.transporter.sendMail({
      from: this.from,
      to: email,
      ...message,
    });
    return true;
  }
}
