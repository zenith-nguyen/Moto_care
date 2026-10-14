import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class CancelOrderDto {
  @ApiProperty({ example: 'I no longer need roadside assistance' })
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}
