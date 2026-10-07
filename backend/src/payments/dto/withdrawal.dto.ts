import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsString, Matches, MaxLength, MinLength, ValidateIf } from 'class-validator';

export class CreateWithdrawalDto {
  @ApiProperty({ example: '50000.00', description: 'Positive VND amount as a decimal string' })
  @Matches(/^(?!(?:0+\.00)$)(?:0|[1-9]\d{0,11})\.\d{2}$/)
  amount!: string;
}

export enum WithdrawalDecision {
  APPROVE = 'APPROVE',
  REJECT = 'REJECT',
}

export class ResolveWithdrawalDto {
  @ApiProperty({ enum: WithdrawalDecision })
  @IsEnum(WithdrawalDecision)
  decision!: WithdrawalDecision;

  @ApiPropertyOptional({ example: 'Sandbox review completed' })
  @ValidateIf((dto: ResolveWithdrawalDto) => dto.decision === WithdrawalDecision.REJECT || dto.reason !== undefined)
  @IsString()
  @Matches(/\S/)
  @MinLength(3)
  @MaxLength(500)
  reason?: string;
}
