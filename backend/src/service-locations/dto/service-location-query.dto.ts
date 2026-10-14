import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsArray, IsEnum, IsInt, IsNumber, IsOptional, Max, Min } from 'class-validator';
import { ServiceLocationSource, ServiceLocationType } from '../service-location-type.enum';

const numberValue = ({ value }: { value: unknown }): unknown => typeof value === 'string' ? Number(value) : value;
const typeList = ({ value }: { value: unknown }): unknown => {
  if (Array.isArray(value)) return value;
  return typeof value === 'string' ? value.split(',').map((item) => item.trim()).filter(Boolean) : value;
};

class LocationTypesQueryDto {
  @ApiPropertyOptional({ enum: ServiceLocationType, isArray: true })
  @Transform(typeList)
  @IsOptional()
  @IsArray()
  @IsEnum(ServiceLocationType, { each: true })
  types?: ServiceLocationType[];
}

export class ViewportServiceLocationsQueryDto extends LocationTypesQueryDto {
  @ApiProperty({ example: 10.9 })
  @Transform(numberValue)
  @IsNumber()
  @Min(-90)
  @Max(90)
  north!: number;

  @ApiProperty({ example: 10.7 })
  @Transform(numberValue)
  @IsNumber()
  @Min(-90)
  @Max(90)
  south!: number;

  @ApiProperty({ example: 106.85 })
  @Transform(numberValue)
  @IsNumber()
  @Min(-180)
  @Max(180)
  east!: number;

  @ApiProperty({ example: 106.55 })
  @Transform(numberValue)
  @IsNumber()
  @Min(-180)
  @Max(180)
  west!: number;
}

export class NearbyServiceLocationsQueryDto extends LocationTypesQueryDto {
  @ApiProperty({ example: 10.7769 })
  @Transform(numberValue)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude!: number;

  @ApiProperty({ example: 106.7009 })
  @Transform(numberValue)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude!: number;

  @ApiPropertyOptional({ name: 'radius_km', default: 5, minimum: 0.1, maximum: 50 })
  @Transform(numberValue)
  @IsOptional()
  @IsNumber()
  @Min(0.1)
  @Max(50)
  radius_km = 5;

  @ApiPropertyOptional({ default: 50, minimum: 1, maximum: 100 })
  @Transform(numberValue)
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  limit = 50;
}

export class ServiceLocationResponseDto {
  @ApiProperty()
  id!: number;

  @ApiProperty({ enum: ServiceLocationSource })
  source!: ServiceLocationSource;

  @ApiProperty({ enum: ServiceLocationType })
  type!: ServiceLocationType;

  @ApiProperty()
  name!: string;

  @ApiPropertyOptional({ nullable: true })
  address!: string | null;

  @ApiPropertyOptional({ nullable: true })
  phone!: string | null;

  @ApiPropertyOptional({ nullable: true })
  website!: string | null;

  @ApiPropertyOptional({ nullable: true })
  openingHours!: string | null;

  @ApiProperty()
  latitude!: number;

  @ApiProperty()
  longitude!: number;

  @ApiProperty()
  isVerified!: boolean;

  @ApiProperty()
  isPartner!: boolean;

  @ApiPropertyOptional({ nullable: true })
  distanceMeters?: number | null;
}
