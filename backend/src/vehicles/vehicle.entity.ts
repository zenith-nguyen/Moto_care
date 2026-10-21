import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { VehicleType } from './vehicle-type.enum';

@Entity({ name: 'vehicles' })
@Index('UQ_vehicles_license_plate', ['licensePlate'], { unique: true })
@Index('IDX_vehicles_customer', ['customerId'])
@Index('UQ_vehicles_one_default_per_customer', ['customerId'], { unique: true, where: '"is_default" = true' })
export class Vehicle {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'customer_id' })
  customerId!: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'customer_id' })
  customer!: User;

  @Column({ type: 'enum', enum: VehicleType })
  type!: VehicleType;

  @Column({ length: 80 })
  brand!: string;

  @Column({ length: 100 })
  model!: string;

  @Column({ name: 'license_plate', length: 20 })
  licensePlate!: string;

  @Column({ type: 'varchar', length: 40, nullable: true })
  color!: string | null;

  @Column({ name: 'tire_type', type: 'varchar', length: 12, default: 'tubed' })
  tireType!: string;

  @Column({ name: 'engine_type', type: 'varchar', length: 12, default: 'gas' })
  engineType!: string;

  @Column({ name: 'is_default', default: false })
  isDefault!: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
