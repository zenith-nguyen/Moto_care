import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

@Entity({ name: 'incident_types' })
@Index('UQ_incident_types_code', ['code'], { unique: true })
@Index('IDX_incident_types_active', ['isActive'])
export class IncidentType {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ length: 60 })
  code!: string;

  @Column({ length: 120 })
  name!: string;

  @Column({ name: 'base_price', type: 'numeric', precision: 12, scale: 2 })
  basePrice!: string;

  @Column({ name: 'is_active', default: true })
  isActive!: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
