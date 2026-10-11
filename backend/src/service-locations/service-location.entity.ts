import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { GeoPoint } from '../providers/provider.entity';
import { ServiceLocationSource, ServiceLocationType } from './service-location-type.enum';

@Entity({ name: 'service_locations' })
@Index('UQ_service_locations_source_id', ['source', 'sourceId'], { unique: true })
@Index('IDX_service_locations_type_active', ['type', 'isActive'])
export class ServiceLocation {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ type: 'enum', enum: ServiceLocationSource })
  source!: ServiceLocationSource;

  @Column({ name: 'source_id', type: 'varchar', length: 80 })
  sourceId!: string;

  @Column({ type: 'enum', enum: ServiceLocationType })
  type!: ServiceLocationType;

  @Column({ type: 'varchar', length: 200 })
  name!: string;

  @Column({ type: 'text', nullable: true })
  address!: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true })
  phone!: string | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  website!: string | null;

  @Column({ name: 'opening_hours', type: 'varchar', length: 300, nullable: true })
  openingHours!: string | null;

  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
  })
  location!: GeoPoint;

  @Column({ name: 'is_verified', default: false })
  isVerified!: boolean;

  @Column({ name: 'is_partner', default: false })
  isPartner!: boolean;

  @Column({ name: 'is_active', default: true })
  isActive!: boolean;

  @Column({ name: 'source_updated_at', type: 'timestamptz', nullable: true })
  sourceUpdatedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
