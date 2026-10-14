import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { App, applicationDefault, getApp, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { PushGateway, PushMessage, PushResult } from './push-gateway.port';

const permanentTokenErrors = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
  'messaging/mismatched-credential',
]);

@Injectable()
export class FirebasePushGateway implements PushGateway, OnModuleInit {
  private readonly logger = new Logger(FirebasePushGateway.name);
  readonly enabled: boolean;
  private readonly app: App | null;

  constructor(config: ConfigService) {
    this.enabled = config.get<boolean>('PUSH_NOTIFICATIONS_ENABLED') ?? false;
    if (!this.enabled) {
      this.app = null;
      return;
    }
    const projectId = config.getOrThrow<string>('FIREBASE_PROJECT_ID');
    this.app = getApps().length > 0
      ? getApp()
      : initializeApp({ credential: applicationDefault(), projectId });
  }

  async onModuleInit(): Promise<void> {
    if (!this.app) return;
    const credential = this.app.options.credential;
    if (!credential) throw new Error('Firebase application has no server credential');
    await credential.getAccessToken();
    this.logger.log('Firebase server credentials verified');
  }

  async send(token: string, message: PushMessage): Promise<PushResult> {
    if (!this.app) return { success: false, errorCode: 'push/disabled', permanent: true };
    try {
      const ttl = message.expiresAt
        ? Math.max(0, message.expiresAt.getTime() - Date.now())
        : 60 * 60 * 1000;
      if (message.expiresAt && ttl === 0) {
        return { success: false, errorCode: 'push/expired', permanent: true };
      }
      await getMessaging(this.app).send({
        token,
        notification: { title: message.title, body: message.body },
        data: message.data,
        android: {
          priority: 'high',
          ttl,
        },
      });
      return { success: true };
    } catch (error) {
      const code = this.errorCode(error);
      return { success: false, errorCode: code, permanent: permanentTokenErrors.has(code) };
    }
  }

  private errorCode(error: unknown): string {
    if (typeof error === 'object' && error !== null && 'code' in error && typeof error.code === 'string') {
      return error.code.slice(0, 100);
    }
    return 'push/unknown';
  }
}
