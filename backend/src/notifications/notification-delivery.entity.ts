import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { Notification } from './notification.entity';
import { NotificationDeliveryStatus } from './notification-delivery-status.enum';
import { UserDevice } from './user-device.entity';

@Entity({ name: 'notification_deliveries' })
@Index('UQ_notification_deliveries_notification_device', ['notificationId', 'deviceId'], { unique: true })
@Index('IDX_notification_deliveries_status_next_attempt', ['status', 'nextAttemptAt'])
export class NotificationDelivery {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'notification_id' })
  notificationId!: number;

  @ManyToOne(() => Notification, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'notification_id' })
  notification!: Notification;

  @Column({ name: 'device_id', type: 'integer', nullable: true })
  deviceId!: number | null;

  @ManyToOne(() => UserDevice, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'device_id' })
  device!: UserDevice | null;

  @Column({ type: 'enum', enum: NotificationDeliveryStatus, enumName: 'notification_deliveries_status_enum' })
  status!: NotificationDeliveryStatus;

  @Column({ name: 'attempt_count', type: 'smallint', default: 0 })
  attemptCount!: number;

  @Column({ name: 'next_attempt_at', type: 'timestamptz', default: () => 'now()' })
  nextAttemptAt!: Date;

  @Column({ name: 'sent_at', type: 'timestamptz', nullable: true })
  sentAt!: Date | null;

  @Column({ name: 'last_error_code', type: 'varchar', length: 100, nullable: true })
  lastErrorCode!: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
