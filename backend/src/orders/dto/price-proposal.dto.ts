import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class CreatePriceProposalDto {
  @ApiProperty({ example: '125000.00', description: 'Final service price as a non-negative decimal string' })
  @Matches(/^(0|[1-9]\d{0,9})\.\d{2}$/)
  final_price!: string;

  @ApiProperty({ example: 'Replace damaged inner tube and valve' })
  @IsString()
  @Matches(/\S/)
  @MinLength(5)
  @MaxLength(500)
  reason!: string;
}

export class PriceDecisionReasonDto {
  @ApiProperty({ example: 'The additional part was not agreed at the scene' })
  @IsString()
  @Matches(/\S/)
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}

export enum AdminPriceResolution {
  APPROVE = 'APPROVE',
  REJECT = 'REJECT',
}

export class ResolvePriceDisputeDto {
  @ApiProperty({ enum: AdminPriceResolution })
  @IsEnum(AdminPriceResolution)
  decision!: AdminPriceResolution;

  @ApiProperty({ example: 'Evidence confirms the replacement part and agreed price' })
  @IsString()
  @Matches(/\S/)
  @MinLength(5)
  @MaxLength(500)
  reason!: string;
}
