import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { ListNotificationsDto } from './dto/list-notifications.dto';
import { RegisterDeviceDto } from './dto/register-device.dto';
import { NotificationsService } from './notifications.service';

@ApiTags('notifications')
@ApiBearerAuth()
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Put('devices')
  @ApiOkResponse({ description: 'Registers or refreshes the current app installation without returning its FCM token' })
  registerDevice(@CurrentUser() user: JwtPayload, @Body() dto: RegisterDeviceDto) {
    return this.notifications.registerDevice(user.sub, dto);
  }

  @Delete('devices/:installationId')
  @ApiOkResponse({ description: 'Disables push delivery for this installation during logout or token revocation' })
  unregisterDevice(@CurrentUser() user: JwtPayload, @Param('installationId') installationId: string) {
    return this.notifications.unregisterDevice(user.sub, installationId);
  }

  @Get()
  @ApiOkResponse({ description: 'Cursor-paginated notification inbox for the signed-in user' })
  list(@CurrentUser() user: JwtPayload, @Query() query: ListNotificationsDto) {
    return this.notifications.list(user.sub, query);
  }

  @Patch('read-all')
  @ApiOkResponse({ description: 'Marks every current notification as read' })
  markAllRead(@CurrentUser() user: JwtPayload) {
    return this.notifications.markAllRead(user.sub);
  }

  @Patch(':notificationId/read')
  @ApiOkResponse({ description: 'Marks one owned notification as read' })
  markRead(@CurrentUser() user: JwtPayload, @Param('notificationId', ParseIntPipe) notificationId: number) {
    return this.notifications.markRead(user.sub, notificationId);
  }
}
