import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsNotEmpty, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { UserRole } from '../../common/enums/user-role.enum';
import { UserStatus } from '../../common/enums/user-status.enum';

const trim = ({ value }: { value: unknown }): unknown => typeof value === 'string' ? value.trim() : value;
const normalizePhone = ({ value }: { value: unknown }): unknown => (
  typeof value === 'string' ? value.trim().replace(/[\s().-]/g, '') : value
);
const emptyToNull = ({ value }: { value: unknown }): unknown => (
  typeof value === 'string' && value.trim() === '' ? null : trim({ value })
);
const emptyPhoneToNull = ({ value }: { value: unknown }): unknown => {
  const normalized = normalizePhone({ value });
  return normalized === '' ? null : normalized;
};

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'Nguyen Van An' })
  @Transform(trim)
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(100)
  name?: string;

  @ApiPropertyOptional({ example: '0901234567', nullable: true, description: '9-15 digits, optional leading +; null removes it when email exists' })
  @Transform(normalizePhone)
  @IsOptional()
  @IsString()
  @Matches(/^\+?[0-9]{9,15}$/)
  phone?: string | null;

  @ApiPropertyOptional({ maxLength: 80, nullable: true })
  @Transform(emptyToNull)
  @IsOptional()
  @IsString()
  @MaxLength(80)
  emergencyContactName?: string | null;

  @ApiPropertyOptional({ example: '0901234567', nullable: true })
  @Transform(emptyPhoneToNull)
  @IsOptional()
  @IsString()
  @Matches(/^\+?[0-9]{9,15}$/)
  emergencyContactPhone?: string | null;

  @ApiPropertyOptional({ maxLength: 240, nullable: true })
  @Transform(emptyToNull)
  @IsOptional()
  @IsString()
  @MaxLength(240)
  medicalNote?: string | null;

  @ApiPropertyOptional({ maxLength: 240, nullable: true })
  @Transform(emptyToNull)
  @IsOptional()
  @IsString()
  @MaxLength(240)
  homeAddress?: string | null;

  @ApiPropertyOptional({ maxLength: 240, nullable: true })
  @Transform(emptyToNull)
  @IsOptional()
  @IsString()
  @MaxLength(240)
  workAddress?: string | null;
}

export class UserProfileResponseDto {
  @ApiProperty()
  id!: number;

  @ApiProperty()
  name!: string;

  @ApiProperty({ type: String, nullable: true })
  email!: string | null;

  @ApiProperty({ type: String, nullable: true })
  phone!: string | null;

  @ApiProperty({ type: String, nullable: true })
  emergencyContactName!: string | null;

  @ApiProperty({ type: String, nullable: true })
  emergencyContactPhone!: string | null;

  @ApiProperty({ type: String, nullable: true })
  medicalNote!: string | null;

  @ApiProperty({ type: String, nullable: true })
  homeAddress!: string | null;

  @ApiProperty({ type: String, nullable: true })
  workAddress!: string | null;

  @ApiProperty({ enum: UserRole })
  role!: UserRole;

  @ApiProperty({ enum: UserStatus })
  status!: UserStatus;
}
