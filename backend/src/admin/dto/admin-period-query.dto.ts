import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsIn, IsOptional } from 'class-validator';

export class AdminPeriodQueryDto {
  @ApiPropertyOptional({
    description: 'Inclusive ISO-8601 start; defaults to seven days before `to`',
  })
  @IsOptional()
  @IsDateString({ strict: true })
  from?: string;

  @ApiPropertyOptional({
    description: 'Exclusive ISO-8601 end; defaults to the current time',
  })
  @IsOptional()
  @IsDateString({ strict: true })
  to?: string;
}

export class AdminTimeseriesQueryDto extends AdminPeriodQueryDto {
  @ApiPropertyOptional({ enum: ['day'], default: 'day' })
  @IsOptional()
  @IsIn(['day'])
  bucket = 'day' as const;
}
