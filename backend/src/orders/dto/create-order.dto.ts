import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsLatitude, IsLongitude, IsNumber, Min, ValidateNested } from 'class-validator';

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

  @ApiProperty({ type: CustomerLocationDto })
  @ValidateNested()
  @Type(() => CustomerLocationDto)
  customer_location!: CustomerLocationDto;
}
