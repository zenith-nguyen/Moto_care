import { Body, Controller, Get, Param, ParseIntPipe, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminService } from './admin.service';
import { ApproveProviderDto } from './dto/approve-provider.dto';

@ApiTags('admin')
@ApiBearerAuth()
@Roles(UserRole.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('orders')
  @ApiOkResponse({ description: 'Latest 50 orders for the admin demo dashboard' })
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
  @ApiOkResponse({ description: 'Approve or reject a pending provider; reviewed profiles cannot be changed here' })
  reviewProvider(@Param('providerId', ParseIntPipe) providerId: number, @Body() dto: ApproveProviderDto) {
    return this.admin.reviewProvider(providerId, dto.status);
  }
}
