import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from '../users/user.entity';
import { NotificationType } from './notification-type.enum';

export type NotificationData = Record<string, string>;

@Entity({ name: 'notifications' })
@Index('UQ_notifications_dedupe_key', ['dedupeKey'], { unique: true })
@Index('IDX_notifications_user_id_id', ['userId', 'id'])
@Index('IDX_notifications_user_unread', ['userId', 'readAt'])
export class Notification {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'user_id' })
  userId!: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ type: 'enum', enum: NotificationType, enumName: 'notifications_type_enum' })
  type!: NotificationType;

  @Column({ type: 'varchar', length: 120 })
  title!: string;

  @Column({ type: 'varchar', length: 500 })
  body!: string;

  @Column({ type: 'jsonb', default: () => "'{}'::jsonb" })
  data!: NotificationData;

  @Column({ name: 'dedupe_key', type: 'varchar', length: 180, nullable: true })
  dedupeKey!: string | null;

  @Column({ name: 'read_at', type: 'timestamptz', nullable: true })
  readAt!: Date | null;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt!: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
