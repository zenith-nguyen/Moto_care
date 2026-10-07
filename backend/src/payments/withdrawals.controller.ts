import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { CreateWithdrawalDto } from './dto/withdrawal.dto';
import { WithdrawalsService } from './withdrawals.service';

@ApiTags('withdrawals')
@ApiBearerAuth()
@Roles(UserRole.PROVIDER)
@Controller('withdrawals')
export class WithdrawalsController {
  constructor(private readonly withdrawals: WithdrawalsService) {}

  @Post()
  @ApiCreatedResponse({ description: 'Reserve available demo wallet funds and create a pending withdrawal request' })
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateWithdrawalDto) {
    return this.withdrawals.create(user.sub, dto);
  }

  @Get('me')
  @ApiOkResponse({ description: 'Provider withdrawal history and current total/locked/available demo balances' })
  mine(@CurrentUser() user: JwtPayload) {
    return this.withdrawals.mine(user.sub);
  }
}
