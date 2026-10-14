import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { User } from '../users/user.entity';
import { DevicePlatform } from './device-platform.enum';

@Entity({ name: 'user_devices' })
@Index('UQ_user_devices_installation_id', ['installationId'], { unique: true })
@Index('UQ_user_devices_fcm_token', ['fcmToken'], { unique: true })
@Index('IDX_user_devices_user_enabled', ['userId', 'isEnabled'])
export class UserDevice {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'user_id' })
  userId!: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'installation_id', type: 'varchar', length: 128 })
  installationId!: string;

  @Column({ name: 'fcm_token', type: 'varchar', length: 512, select: false })
  fcmToken!: string;

  @Column({ type: 'enum', enum: DevicePlatform, enumName: 'user_devices_platform_enum' })
  platform!: DevicePlatform;

  @Column({ name: 'is_enabled', default: true })
  isEnabled!: boolean;

  @Column({ name: 'last_seen_at', type: 'timestamptz' })
  lastSeenAt!: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
