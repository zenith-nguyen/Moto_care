import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ApprovalStatus } from '../common/enums/approval-status.enum';
import { User } from '../users/user.entity';

export interface GeoPoint {
  type: 'Point';
  coordinates: [number, number];
}

@Entity({ name: 'providers' })
@Index('IDX_providers_approval_online', ['approvalStatus', 'isOnline'])
@Index('UQ_providers_user_id', ['userId'], { unique: true })
export class Provider {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'user_id' })
  userId!: number;

  @OneToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'is_online', default: false })
  isOnline!: boolean;

  @Column({ name: 'approval_status', type: 'enum', enum: ApprovalStatus, default: ApprovalStatus.PENDING })
  approvalStatus!: ApprovalStatus;

  @Column({
    name: 'current_location',
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
    nullable: true,
  })
  currentLocation!: GeoPoint | null;

  @Column({ name: 'last_seen_at', type: 'timestamptz', nullable: true })
  lastSeenAt!: Date | null;

  @Column({ name: 'document_url', type: 'varchar', length: 500, nullable: true })
  documentUrl!: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
