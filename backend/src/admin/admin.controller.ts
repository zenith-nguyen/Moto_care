import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminAnalyticsService } from './admin-analytics.service';
import { AdminService } from './admin.service';
import {
  AdminPeriodQueryDto,
  AdminTimeseriesQueryDto,
} from './dto/admin-period-query.dto';
import { ApproveProviderDto } from './dto/approve-provider.dto';
import { ReconciliationQueryDto } from './dto/reconciliation-query.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { PriceAdjustmentsService } from '../orders/price-adjustments.service';
import { ResolvePriceDisputeDto } from '../orders/dto/price-proposal.dto';
import { ResolveWithdrawalDto } from '../payments/dto/withdrawal.dto';
import { WithdrawalsService } from '../payments/withdrawals.service';

@ApiTags('admin')
@ApiBearerAuth()
@Roles(UserRole.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(
    private readonly admin: AdminService,
    private readonly analytics: AdminAnalyticsService,
    private readonly priceAdjustments: PriceAdjustmentsService,
    private readonly withdrawals: WithdrawalsService,
  ) {}

  @Get('dashboard/summary')
  @ApiOkResponse({
    description:
      'Sandbox dashboard totals for accounts, providers, orders and money',
  })
  summary(@Query() query: AdminPeriodQueryDto) {
    return this.analytics.summary(query);
  }

  @Get('dashboard/timeseries')
  @ApiOkResponse({
    description: 'Daily sandbox order and money series in Asia/Ho_Chi_Minh',
  })
  timeseries(@Query() query: AdminTimeseriesQueryDto) {
    return this.analytics.timeseries(query);
  }

  @Get('reconciliation')
  @ApiOkResponse({
    description:
      'Paginated order/payment/wallet reconciliation with anomaly flags',
  })
  reconciliation(@Query() query: ReconciliationQueryDto) {
    return this.analytics.reconciliation(query);
  }

  @Get('price-disputes/pending')
  @ApiOkResponse({ description: 'Up to 50 final-price disputes awaiting Admin review' })
  pendingPriceDisputes() {
    return this.priceAdjustments.pendingDisputes();
  }

  @Get('payment-adjustments/pending-refunds')
  @ApiOkResponse({ description: 'Up to 50 approved price reductions awaiting a demo refund' })
  pendingRefundAdjustments() {
    return this.priceAdjustments.pendingRefundAdjustments();
  }

  @Patch('price-disputes/:proposalId/resolve')
  @ApiOkResponse({ description: 'Admin approves or rejects a disputed final-price proposal once' })
  resolvePriceDispute(
    @Param('proposalId', ParseIntPipe) proposalId: number,
    @CurrentUser() user: JwtPayload,
    @Body() dto: ResolvePriceDisputeDto,
  ) {
    return this.priceAdjustments.resolveDispute(proposalId, user.sub, dto.decision, dto.reason);
  }

  @Get('withdrawals/pending')
  @ApiOkResponse({ description: 'Up to 50 pending sandbox withdrawal requests in FIFO order' })
  pendingWithdrawals() {
    return this.withdrawals.pending();
  }

  @Patch('withdrawals/:requestId/resolve')
  @ApiOkResponse({ description: 'Approve or reject one sandbox withdrawal atomically and idempotently' })
  resolveWithdrawal(
    @Param('requestId', ParseIntPipe) requestId: number,
    @CurrentUser() user: JwtPayload,
    @Body() dto: ResolveWithdrawalDto,
  ) {
    return this.withdrawals.resolve(requestId, user.sub, dto.decision, dto.reason);
  }

  @Get('orders')
  @ApiOkResponse({
    description: 'Latest 50 orders for the admin demo dashboard',
  })
  recentOrders() {
    return this.admin.recentOrders();
  }

  @Get('refunds/pending')
  @ApiOkResponse({ description: 'Orders awaiting a full demo refund' })
  pendingRefunds() {
    return this.admin.pendingRefunds();
  }

  @Get('providers/pending')
  @ApiOkResponse({ description: 'Provider applications awaiting review' })
  pendingProviders() {
    return this.admin.pendingProviders();
  }

  @Patch('providers/:providerId/approval')
  @ApiOkResponse({
    description:
      'Approve or reject a pending provider; reviewed profiles cannot be changed here',
  })
  reviewProvider(
    @Param('providerId', ParseIntPipe) providerId: number,
    @Body() dto: ApproveProviderDto,
  ) {
    return this.admin.reviewProvider(providerId, dto.status);
  }
}
