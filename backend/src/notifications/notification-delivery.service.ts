import { Injectable, Logger } from '@nestjs/common';
import { Interval } from '@nestjs/schedule';
import { DataSource } from 'typeorm';
import { NotificationDeliveryStatus } from './notification-delivery-status.enum';
import { NotificationDelivery } from './notification-delivery.entity';
import { PushGateway } from './push-gateway.port';
import { UserDevice } from './user-device.entity';

@Injectable()
export class NotificationDeliveryService {
  private readonly logger = new Logger(NotificationDeliveryService.name);
  private running = false;

  constructor(
    private readonly database: DataSource,
    private readonly push: PushGateway,
  ) {}

  @Interval(5000)
  async deliverPending(): Promise<void> {
    if (!this.push.enabled || this.running) return;
    this.running = true;
    try {
      const deliveryIds = await this.claim(20);
      for (const id of deliveryIds) {
        try {
          await this.deliverOne(id);
        } catch {
          this.logger.error(`Push delivery ${id} failed unexpectedly and will be recovered`);
        }
      }
    } finally {
      this.running = false;
    }
  }

  private async claim(limit: number): Promise<number[]> {
    await this.database.query(`
      UPDATE notification_deliveries
      SET status = 'FAILED', next_attempt_at = now(), last_error_code = 'push/worker-interrupted', updated_at = now()
      WHERE status = 'PROCESSING' AND updated_at < now() - interval '2 minutes'
    `);
    const rawResult = (await this.database.query(`
      WITH picked AS (
        SELECT id
        FROM notification_deliveries
        WHERE status IN ('PENDING', 'FAILED')
          AND next_attempt_at <= clock_timestamp()
          AND attempt_count < 5
        ORDER BY id
        LIMIT $1
        FOR UPDATE SKIP LOCKED
      )
      UPDATE notification_deliveries delivery
      SET status = 'PROCESSING', attempt_count = delivery.attempt_count + 1, updated_at = now()
      FROM picked
      WHERE delivery.id = picked.id
      RETURNING delivery.id
    `, [limit])) as Array<{ id: number }> | [Array<{ id: number }>, number];
    // TypeORM's PostgreSQL runner returns [rows, affected] for UPDATE queries.
    const rows = Array.isArray(rawResult[0])
      ? rawResult[0]
      : rawResult as Array<{ id: number }>;
    return rows.map((row) => row.id);
  }

  private async deliverOne(id: number): Promise<void> {
    const delivery = await this.database.getRepository(NotificationDelivery)
      .createQueryBuilder('delivery')
      .leftJoinAndSelect('delivery.notification', 'notification')
      .leftJoinAndSelect('delivery.device', 'device')
      .addSelect('device.fcmToken')
      .where('delivery.id = :id', { id })
      .getOne();
    if (!delivery) return;
    if (!delivery.device?.isEnabled || !delivery.device.fcmToken) {
      await this.finish(delivery, NotificationDeliveryStatus.SKIPPED, 'push/device-unavailable');
      return;
    }
    const result = await this.push.send(delivery.device.fcmToken, {
      title: delivery.notification.title,
      body: delivery.notification.body,
      data: { ...delivery.notification.data, notificationId: String(delivery.notification.id) },
      expiresAt: delivery.notification.expiresAt,
    });
    if (result.success) {
      await this.database.getRepository(NotificationDelivery).update(delivery.id, {
        status: NotificationDeliveryStatus.SENT,
        sentAt: new Date(),
        lastErrorCode: null,
      });
      return;
    }
    const code = result.errorCode?.slice(0, 100) ?? 'push/unknown';
    if (result.permanent || delivery.attemptCount >= 5) {
      await this.finish(delivery, NotificationDeliveryStatus.SKIPPED, code);
      if (result.permanent) {
        await this.database.getRepository(UserDevice).update(delivery.device.id, { isEnabled: false });
      }
      return;
    }
    const retrySeconds = 2 ** delivery.attemptCount * 15;
    await this.database.getRepository(NotificationDelivery).update(delivery.id, {
      status: NotificationDeliveryStatus.FAILED,
      nextAttemptAt: new Date(Date.now() + retrySeconds * 1000),
      lastErrorCode: code,
    });
    this.logger.warn(`Push delivery ${delivery.id} will retry after ${code}`);
  }

  private async finish(delivery: NotificationDelivery, status: NotificationDeliveryStatus, errorCode: string) {
    await this.database.getRepository(NotificationDelivery).update(delivery.id, {
      status,
      lastErrorCode: errorCode,
    });
  }
}
