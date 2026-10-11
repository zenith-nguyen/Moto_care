import { Body, Controller, Get, Param, ParseIntPipe, Patch, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { UpdateLocationDto } from './dto/update-location.dto';
import { UpdateStatusDto } from './dto/update-status.dto';
import { ProvidersService } from './providers.service';
import { PendingOfferResponseDto } from '../orders/dto/order-response.dto';
import {
  ProviderProfileResponseDto,
  ProviderWeeklyStatsQueryDto,
  ReplaceProviderSkillsDto,
  UpdateProviderProfileDto,
} from './dto/provider-profile.dto';
import { ProviderProfilesService } from './provider-profiles.service';

@ApiTags('providers')
@ApiBearerAuth()
@Roles(UserRole.PROVIDER)
@Controller('providers/me')
export class ProvidersController {
  constructor(
    private readonly providers: ProvidersService,
    private readonly profiles: ProviderProfilesService,
  ) {}

  @Get('profile')
  @ApiOkResponse({ type: ProviderProfileResponseDto })
  profile(@CurrentUser() user: JwtPayload) {
    return this.profiles.getOwnProfile(user.sub);
  }

  @Patch('profile')
  @ApiOkResponse({ type: ProviderProfileResponseDto })
  updateProfile(@CurrentUser() user: JwtPayload, @Body() dto: UpdateProviderProfileDto) {
    return this.profiles.updateOwnProfile(user.sub, dto);
  }

  @Put('skills')
  @ApiOkResponse({ description: 'Replaces own skill claims; new and rejected claims require Admin verification' })
  replaceSkills(@CurrentUser() user: JwtPayload, @Body() dto: ReplaceProviderSkillsDto) {
    return this.profiles.replaceOwnSkills(user.sub, dto);
  }

  @Get('statistics/weekly')
  @ApiOkResponse({ description: 'Derived weekly operations, rating and wallet statistics in Asia/Ho_Chi_Minh' })
  weeklyStatistics(@CurrentUser() user: JwtPayload, @Query() query: ProviderWeeklyStatsQueryDto) {
    return this.profiles.weeklyStatistics(user.sub, query);
  }

  @Patch('location')
  @ApiOkResponse({ description: 'Provider location updated' })
  updateLocation(@CurrentUser() user: JwtPayload, @Body() dto: UpdateLocationDto) {
    return this.providers.updateLocation(user.sub, dto);
  }

  @Patch('orders/:orderId/location')
  @ApiOkResponse({ description: 'Updates provider GPS and emits to authenticated order participants' })
  updateOrderLocation(
    @CurrentUser() user: JwtPayload,
    @Param('orderId', ParseIntPipe) orderId: number,
    @Body() dto: UpdateLocationDto,
  ) {
    return this.providers.updateOrderLocation(user.sub, orderId, dto);
  }

  @Patch('status')
  @ApiOkResponse({ description: 'Provider availability updated' })
  updateStatus(@CurrentUser() user: JwtPayload, @Body() dto: UpdateStatusDto) {
    return this.providers.updateStatus(user.sub, dto.isOnline);
  }

  @Get('offers/pending')
  @ApiOkResponse({ description: 'Unexpired pending offers for the authenticated provider', type: [PendingOfferResponseDto] })
  pendingOffers(@CurrentUser() user: JwtPayload) {
    return this.providers.pendingOffers(user.sub);
  }
}
