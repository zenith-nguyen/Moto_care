import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';
import { ApprovalStatus } from '../../common/enums/approval-status.enum';

export class ApproveProviderDto {
  @ApiProperty({ enum: [ApprovalStatus.APPROVED, ApprovalStatus.REJECTED] })
  @IsIn([ApprovalStatus.APPROVED, ApprovalStatus.REJECTED])
  status!: ApprovalStatus;
}
