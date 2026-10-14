import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches } from 'class-validator';

export class StartOrderDto {
  @ApiProperty({ description: 'Short-lived HMAC payload from GET /orders/:id/start-token; the customer presents it in person' })
  @IsString()
  @Matches(/^\d{13}\.[0-9a-f]{64}$/)
  token!: string;
}
