import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsLatitude, IsLongitude, IsNumber, IsOptional, Min, ValidateNested } from 'class-validator';

export class CustomerLocationDto {
  @ApiProperty({ example: 10.7769 })
  @IsNumber()
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ example: 106.7009 })
  @IsNumber()
  @IsLongitude()
  longitude!: number;
}

export class CreateOrderDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  @Min(1)
  incident_type_id!: number;

  @ApiPropertyOptional({ example: 1, description: 'Own vehicle; when omitted the default vehicle is snapshotted if one exists' })
  @IsOptional()
  @IsInt()
  @Min(1)
  vehicle_id?: number;

  @ApiProperty({ type: CustomerLocationDto })
  @ValidateNested()
  @Type(() => CustomerLocationDto)
  customer_location!: CustomerLocationDto;
}
