import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsEnum, IsNotEmpty, IsOptional, IsString, Length, Matches, MaxLength } from 'class-validator';
import { VehicleType } from '../vehicle-type.enum';

const trim = ({ value }: { value: unknown }): unknown => typeof value === 'string' ? value.trim() : value;
const normalizePlate = ({ value }: { value: unknown }): unknown => (
  typeof value === 'string' ? value.trim().toUpperCase().replace(/\s+/g, '') : value
);

export class CreateVehicleDto {
  @ApiProperty({ enum: VehicleType, example: VehicleType.MOTORBIKE })
  @IsEnum(VehicleType)
  type!: VehicleType;

  @ApiProperty({ example: 'Honda' })
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  brand!: string;

  @ApiProperty({ example: 'Wave Alpha' })
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  model!: string;

  @ApiProperty({ example: '59A1-123.45' })
  @Transform(normalizePlate)
  @IsString()
  @Length(4, 20)
  @Matches(/^[A-Z0-9.-]+$/, { message: 'licensePlate contains unsupported characters' })
  licensePlate!: string;

  @ApiPropertyOptional({ example: 'Black', nullable: true })
  @Transform(trim)
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  color?: string | null;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class UpdateVehicleDto extends PartialType(CreateVehicleDto) {}

export class VehicleResponseDto {
  @ApiProperty()
  id!: number;

  @ApiProperty({ enum: VehicleType })
  type!: VehicleType;

  @ApiProperty()
  brand!: string;

  @ApiProperty()
  model!: string;

  @ApiProperty()
  licensePlate!: string;

  @ApiPropertyOptional({ nullable: true })
  color!: string | null;

  @ApiProperty()
  isDefault!: boolean;
}
