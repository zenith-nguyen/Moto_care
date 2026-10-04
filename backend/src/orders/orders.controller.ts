import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseIntPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { CreateOrderDto } from './dto/create-order.dto';
import {
  AcceptOfferResponseDto,
  OrderDetailsResponseDto,
  OrderMatchResponseDto,
  RejectOfferResponseDto,
} from './dto/order-response.dto';
import { OrdersService } from './orders.service';

@ApiTags('orders')
@ApiBearerAuth()
@Controller('orders')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Post()
  @Roles(UserRole.CUSTOMER)
  @ApiCreatedResponse({ description: 'Order created and matching attempted', type: OrderMatchResponseDto })
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateOrderDto) {
    return this.orders.create(user.sub, dto);
  }

  @Get(':orderId')
  @Roles(UserRole.CUSTOMER, UserRole.PROVIDER)
  @ApiOkResponse({ description: 'Order details for customer or related provider', type: OrderDetailsResponseDto })
  get(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload) {
    return this.orders.getById(orderId, user.sub);
  }

  @Post(':orderId/retry-match')
  @Roles(UserRole.CUSTOMER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Matching retried for an unmatched order', type: OrderMatchResponseDto })
  retry(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload) {
    return this.orders.retry(orderId, user.sub);
  }

  @Post(':orderId/offers/:offerId/accept')
  @Roles(UserRole.PROVIDER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Offer atomically accepted by its provider', type: AcceptOfferResponseDto })
  accept(
    @Param('orderId', ParseIntPipe) orderId: number,
    @Param('offerId', ParseIntPipe) offerId: number,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.orders.accept(orderId, offerId, user.sub);
  }

  @Post(':orderId/offers/:offerId/reject')
  @Roles(UserRole.PROVIDER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Offer rejected and next provider matched immediately', type: RejectOfferResponseDto })
  reject(
    @Param('orderId', ParseIntPipe) orderId: number,
    @Param('offerId', ParseIntPipe) offerId: number,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.orders.reject(orderId, offerId, user.sub);
  }
}
