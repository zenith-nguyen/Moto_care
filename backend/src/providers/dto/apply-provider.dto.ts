import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class ApplyProviderDto {
  @ApiPropertyOptional({
    example: 'Thợ sửa xe máy 5 năm kinh nghiệm khu vực Quận 1.',
    maxLength: 1000,
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  bio?: string;

  @ApiPropertyOptional({ example: 'https://example.com/giay-phep.pdf', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  documentUrl?: string;

  @ApiPropertyOptional({ example: 5, minimum: 0, maximum: 80 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(80)
  yearsOfExperience?: number;

  @ApiPropertyOptional({ example: 10, minimum: 1, maximum: 100 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(100)
  serviceRadiusKm?: number;
}
