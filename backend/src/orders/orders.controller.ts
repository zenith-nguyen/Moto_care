import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseIntPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { CreateOrderDto } from './dto/create-order.dto';
import { CancelOrderDto } from './dto/cancel-order.dto';
import { StartOrderDto } from './dto/start-order.dto';
import {
  AcceptOfferResponseDto,
  OrderDetailsResponseDto,
  OrderMatchResponseDto,
  RejectOfferResponseDto,
} from './dto/order-response.dto';
import { OrdersService } from './orders.service';
import { CreatePriceProposalDto, PriceDecisionReasonDto } from './dto/price-proposal.dto';
import { PriceAdjustmentsService } from './price-adjustments.service';

@ApiTags('orders')
@ApiBearerAuth()
@Controller('orders')
export class OrdersController {
  constructor(
    private readonly orders: OrdersService,
    private readonly priceAdjustments: PriceAdjustmentsService,
  ) {}

  @Get()
  @Roles(UserRole.CUSTOMER, UserRole.PROVIDER)
  @ApiOkResponse({ description: 'Latest 30 own orders; providers have a separate pending-offers endpoint' })
  listMine(@CurrentUser() user: JwtPayload) {
    return this.orders.listMine(user.sub, user.role);
  }

  @Post()
  @Roles(UserRole.CUSTOMER)
  @ApiCreatedResponse({ description: 'Order created; matching starts only after demo prepayment confirmation', type: OrderMatchResponseDto })
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

  @Post(':orderId/cancel')
  @Roles(UserRole.CUSTOMER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Cancel before service starts; paid orders require full refund' })
  cancel(
    @Param('orderId', ParseIntPipe) orderId: number,
    @CurrentUser() user: JwtPayload,
    @Body() dto: CancelOrderDto,
  ) {
    return this.orders.cancel(orderId, user.sub, dto.reason);
  }

  @Post(':orderId/arrive')
  @Roles(UserRole.PROVIDER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Assigned provider marks arrival at the customer' })
  arrive(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload) {
    return this.orders.arrive(orderId, user.sub);
  }

  @Get(':orderId/start-token')
  @Roles(UserRole.CUSTOMER)
  @ApiOkResponse({ description: 'Five-minute service-start token for customer to show as QR/text; not a payment QR' })
  startToken(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload) {
    return this.orders.startToken(orderId, user.sub);
  }

  @Post(':orderId/start')
  @Roles(UserRole.PROVIDER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Assigned provider starts service with the customer-presented token' })
  start(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload, @Body() dto: StartOrderDto) {
    return this.orders.start(orderId, user.sub, dto.token);
  }

  @Post(':orderId/complete')
  @Roles(UserRole.PROVIDER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Complete after the approved final price is fully settled; credits the provider demo wallet exactly once' })
  complete(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload) {
    return this.orders.complete(orderId, user.sub);
  }

  @Post(':orderId/price-proposals')
  @Roles(UserRole.PROVIDER)
  @ApiCreatedResponse({ description: 'Assigned provider proposes the final service price for customer approval' })
  proposeFinalPrice(
    @Param('orderId', ParseIntPipe) orderId: number,
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreatePriceProposalDto,
  ) {
    return this.priceAdjustments.propose(orderId, user.sub, dto);
  }

  @Post(':orderId/price-proposals/:proposalId/approve')
  @Roles(UserRole.CUSTOMER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Customer approves the final price and creates a charge/refund adjustment when needed' })
  approveFinalPrice(
    @Param('orderId', ParseIntPipe) orderId: number,
    @Param('proposalId', ParseIntPipe) proposalId: number,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.priceAdjustments.approve(orderId, proposalId, user.sub);
  }

  @Post(':orderId/price-proposals/:proposalId/reject')
  @Roles(UserRole.CUSTOMER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Customer rejects the proposed final price and returns the order to in-progress' })
  rejectFinalPrice(
    @Param('orderId', ParseIntPipe) orderId: number,
    @Param('proposalId', ParseIntPipe) proposalId: number,
    @CurrentUser() user: JwtPayload,
    @Body() dto: PriceDecisionReasonDto,
  ) {
    return this.priceAdjustments.reject(orderId, proposalId, user.sub, dto.reason);
  }

  @Post(':orderId/price-proposals/:proposalId/dispute')
  @Roles(UserRole.PROVIDER)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Provider escalates a rejected final-price proposal for Admin review' })
  disputeFinalPrice(
    @Param('orderId', ParseIntPipe) orderId: number,
    @Param('proposalId', ParseIntPipe) proposalId: number,
    @CurrentUser() user: JwtPayload,
    @Body() dto: PriceDecisionReasonDto,
  ) {
    return this.priceAdjustments.dispute(orderId, proposalId, user.sub, dto.reason);
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
