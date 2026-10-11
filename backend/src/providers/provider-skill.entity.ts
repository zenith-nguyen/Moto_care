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
import { Provider } from './provider.entity';
import { SkillVerificationStatus } from './skill-verification-status.enum';
import { Skill } from './skill.entity';

@Entity({ name: 'provider_skills' })
@Index('UQ_provider_skills_provider_skill', ['providerId', 'skillId'], { unique: true })
@Index('IDX_provider_skills_provider_status', ['providerId', 'verificationStatus'])
export class ProviderSkill {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'provider_id' })
  providerId!: number;

  @ManyToOne(() => Provider, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'provider_id' })
  provider!: Provider;

  @Column({ name: 'skill_id' })
  skillId!: number;

  @ManyToOne(() => Skill, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'skill_id' })
  skill!: Skill;

  @Column({
    name: 'verification_status',
    type: 'enum',
    enum: SkillVerificationStatus,
    default: SkillVerificationStatus.PENDING,
  })
  verificationStatus!: SkillVerificationStatus;

  @Column({ name: 'verified_at', type: 'timestamptz', nullable: true })
  verifiedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
