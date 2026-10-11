import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { ProviderTier } from '../provider-tier.enum';
import { SkillVerificationStatus } from '../skill-verification-status.enum';

const trim = ({ value }: { value: unknown }): unknown => typeof value === 'string' ? value.trim() : value;
const nullableTrim = ({ value }: { value: unknown }): unknown => {
  if (value === null) return null;
  if (typeof value !== 'string') return value;
  const trimmed = value.trim();
  return trimmed.length ? trimmed : null;
};
const normalizeCode = ({ value }: { value: unknown }): unknown => (
  typeof value === 'string' ? value.trim().toUpperCase() : value
);

export class UpdateProviderProfileDto {
  @ApiPropertyOptional({ nullable: true, maxLength: 1000 })
  @Transform(nullableTrim)
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  bio?: string | null;

  @ApiPropertyOptional({ minimum: 0, maximum: 70 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(70)
  yearsOfExperience?: number;

  @ApiPropertyOptional({ minimum: 1, maximum: 100, example: 10 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  @Max(100)
  serviceRadiusKm?: number;
}

export class ReplaceProviderSkillsDto {
  @ApiProperty({ type: [Number], maxItems: 20 })
  @IsArray()
  @ArrayUnique()
  @ArrayMaxSize(20)
  @IsInt({ each: true })
  @Min(1, { each: true })
  skillIds!: number[];
}

export class CreateSkillDto {
  @ApiProperty({ example: 'FLAT_TIRE' })
  @Transform(normalizeCode)
  @IsString()
  @Matches(/^[A-Z][A-Z0-9_]{1,49}$/)
  code!: string;

  @ApiProperty({ example: 'Vá lốp xe máy' })
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name!: string;
}

export class UpdateSkillDto extends PartialType(CreateSkillDto) {
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateProviderTierDto {
  @ApiProperty({ enum: ProviderTier })
  @IsEnum(ProviderTier)
  tier!: ProviderTier;
}

export class ReviewProviderSkillDto {
  @ApiProperty({ enum: SkillVerificationStatus })
  @IsEnum(SkillVerificationStatus)
  verificationStatus!: SkillVerificationStatus;
}

export class ProviderWeeklyStatsQueryDto {
  @ApiPropertyOptional({ name: 'week_start', example: '2026-10-05', description: 'Monday in Asia/Ho_Chi_Minh' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  week_start?: string;
}

export class ProviderSkillResponseDto {
  @ApiProperty()
  id!: number;

  @ApiProperty()
  code!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty({ enum: SkillVerificationStatus })
  verificationStatus!: SkillVerificationStatus;
}

export class ProviderProfileResponseDto {
  @ApiProperty()
  id!: number;

  @ApiProperty()
  name!: string;

  @ApiPropertyOptional({ nullable: true })
  bio!: string | null;

  @ApiProperty()
  yearsOfExperience!: number;

  @ApiProperty({ description: 'Decimal string in kilometres' })
  serviceRadiusKm!: string;

  @ApiProperty({ enum: ProviderTier })
  tier!: ProviderTier;

  @ApiProperty({ type: [ProviderSkillResponseDto] })
  skills!: ProviderSkillResponseDto[];
}
