import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsInt, IsNotEmpty, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class SepayWebhookDto {
  @ApiProperty({ example: 12345 })
  @IsInt()
  @Min(1)
  id!: number;

  @ApiProperty({ example: 'MBBank' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  gateway!: string;

  @ApiProperty({ example: '2026-01-15 10:30:00' })
  @IsString()
  @MaxLength(30)
  transactionDate!: string;

  @ApiProperty({ example: '0123456789' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  accountNumber!: string;

  @ApiProperty({ example: 'SBSEPAYX9KA2B7MN4QR', nullable: true })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  subAccount!: string | null;

  @ApiProperty({ example: 'MC42', nullable: true })
  @IsOptional()
  @IsString()
  @MaxLength(40)
  code!: string | null;

  @ApiProperty({ example: 'MC42 thanh toan don hang' })
  @IsString()
  @MaxLength(500)
  content!: string;

  @ApiProperty({ enum: ['in', 'out'] })
  @IsIn(['in', 'out'])
  transferType!: 'in' | 'out';

  @ApiProperty({ example: 'NGUYEN VAN A chuyen tien' })
  @IsString()
  @MaxLength(500)
  description!: string;

  @ApiProperty({ example: 100000 })
  @IsInt()
  @Min(1)
  @Max(9_000_000_000_000)
  transferAmount!: number;

  @ApiProperty({ example: 5000000 })
  @IsInt()
  @Min(0)
  @Max(9_000_000_000_000)
  accumulated!: number;

  @ApiProperty({ example: 'SB1A2B3C4D5E' })
  @IsString()
  @MaxLength(120)
  referenceCode!: string;
}

export class BankTransferInstructionsDto {
  @ApiProperty({ example: 'SEPAY' })
  provider!: 'SEPAY';

  @ApiProperty({
    example: 'test',
    description: 'This adapter currently supports SePay Test mode only',
  })
  mode!: 'test';

  @ApiProperty({
    example: true,
    description: 'Always true in this adapter; no real-money transfer is supported',
  })
  simulationOnly!: true;

  @ApiProperty({ example: 'MC42' })
  paymentCode!: string;

  @ApiProperty({ example: '100000.00' })
  amount!: string;

  @ApiProperty({ example: 'MBBank' })
  bank!: string;

  @ApiProperty({ example: 'SBSEPAYX9KA2B7MN4QR' })
  accountNumber!: string;

  @ApiProperty({ example: 'MOTOCARE DEMO' })
  accountHolder!: string;

  @ApiProperty({ example: 'MC42' })
  transferContent!: string;

  @ApiProperty({ example: 'https://vietqr.app/img?...' })
  qrImageUrl!: string;
}
