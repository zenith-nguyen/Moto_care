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

@ApiTags('admin')
@ApiBearerAuth()
@Roles(UserRole.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(
    private readonly admin: AdminService,
    private readonly analytics: AdminAnalyticsService,
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
