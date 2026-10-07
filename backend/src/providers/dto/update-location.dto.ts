import { ApiProperty } from '@nestjs/swagger';
import { IsLatitude, IsLongitude, IsNumber } from 'class-validator';

export class UpdateLocationDto {
  @ApiProperty({ example: 10.7769 })
  @IsNumber()
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ example: 106.7009 })
  @IsNumber()
  @IsLongitude()
  longitude!: number;
}
