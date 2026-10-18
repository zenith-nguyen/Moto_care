import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, Matches, MaxLength, MinLength, ValidateIf } from 'class-validator';

export enum PayoutReconciliationDecision {
  CONFIRM = 'CONFIRM',
  FLAG = 'FLAG',
}

export class ReconcileWithdrawalPayoutDto {
  @ApiProperty({ enum: PayoutReconciliationDecision })
  @IsEnum(PayoutReconciliationDecision)
  decision!: PayoutReconciliationDecision;

  @ApiPropertyOptional({ example: 'MBVCB.123456789' })
  @ValidateIf((dto: ReconcileWithdrawalPayoutDto) => dto.decision === PayoutReconciliationDecision.CONFIRM)
  @IsString()
  @MinLength(3)
  @MaxLength(120)
  externalTransactionId?: string;

  @ApiPropertyOptional({ example: 'FT26010112345678' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  referenceCode?: string;

  @ApiPropertyOptional({ example: '50000.00' })
  @ValidateIf((dto: ReconcileWithdrawalPayoutDto) => dto.decision === PayoutReconciliationDecision.CONFIRM)
  @Matches(/^(?!(?:0+\.00)$)(?:0|[1-9]\d{0,11})\.\d{2}$/)
  observedAmount?: string;

  @ApiPropertyOptional({ example: 'Recipient and bank receipt verified by Admin' })
  @ValidateIf((dto: ReconcileWithdrawalPayoutDto) => dto.decision === PayoutReconciliationDecision.FLAG || dto.reason !== undefined)
  @IsString()
  @Matches(/\S/)
  @MinLength(3)
  @MaxLength(500)
  reason?: string;
}
