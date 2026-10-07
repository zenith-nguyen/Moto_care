import { Controller, HttpCode, HttpStatus, Param, ParseIntPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { DemoPaymentsService } from './demo-payments.service';

@ApiTags('demo-payments')
@ApiBearerAuth()
@Controller('payments/demo/orders')
export class DemoPaymentsController {
  constructor(private readonly payments: DemoPaymentsService) {}

  @Post(':orderId/confirm')
  @Roles(UserRole.CUSTOMER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'DEMO ONLY: simulate exact prepayment and then start matching. No bank transfer occurs.' })
  confirm(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload) {
    return this.payments.confirm(orderId, user.sub);
  }

  @Post(':orderId/refund')
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'DEMO ONLY: simulate a full refund. No bank transfer occurs.' })
  refund(@Param('orderId', ParseIntPipe) orderId: number) {
    return this.payments.refund(orderId);
  }

  @Post(':orderId/adjustment/confirm')
  @Roles(UserRole.CUSTOMER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'DEMO ONLY: simulate payment of an approved additional charge.' })
  confirmAdjustment(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload) {
    return this.payments.confirmAdjustment(orderId, user.sub);
  }

  @Post(':orderId/adjustment/refund')
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'DEMO ONLY: simulate refund of an approved final-price reduction.' })
  refundAdjustment(@Param('orderId', ParseIntPipe) orderId: number) {
    return this.payments.refundAdjustment(orderId);
  }
}
