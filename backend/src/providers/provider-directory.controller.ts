import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import {
  CreateSkillDto,
  ProviderProfileResponseDto,
  ReviewProviderSkillDto,
  UpdateProviderTierDto,
  UpdateSkillDto,
} from './dto/provider-profile.dto';
import { ProviderProfilesService } from './provider-profiles.service';

@ApiTags('provider-directory')
@ApiBearerAuth()
@Controller()
export class ProviderDirectoryController {
  constructor(private readonly profiles: ProviderProfilesService) {}

  @Get('provider-skills')
  @ApiOkResponse({ description: 'Active professional skills available for Provider profiles' })
  listSkills() {
    return this.profiles.listActiveSkills();
  }

  @Get('orders/:orderId/provider-profile')
  @Roles(UserRole.CUSTOMER, UserRole.PROVIDER)
  @ApiOkResponse({
    description: 'Public summary of the assigned Provider; phone remains behind participant-contact',
    type: ProviderProfileResponseDto,
  })
  assignedProfile(
    @Param('orderId', ParseIntPipe) orderId: number,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.profiles.assignedProviderProfile(orderId, user.sub, user.role);
  }
}

@ApiTags('admin-provider-directory')
@ApiBearerAuth()
@Roles(UserRole.ADMIN)
@Controller('admin')
export class AdminProviderDirectoryController {
  constructor(private readonly profiles: ProviderProfilesService) {}

  @Get('provider-skills')
  @ApiOkResponse({ description: 'Complete Provider skill catalog, including inactive skills' })
  listSkills() {
    return this.profiles.listAllSkills();
  }

  @Post('provider-skills')
  @ApiCreatedResponse({ description: 'Creates one Provider skill catalog item' })
  createSkill(@Body() dto: CreateSkillDto) {
    return this.profiles.createSkill(dto);
  }

  @Patch('provider-skills/:skillId')
  @ApiOkResponse({ description: 'Updates or deactivates one Provider skill catalog item' })
  updateSkill(@Param('skillId', ParseIntPipe) skillId: number, @Body() dto: UpdateSkillDto) {
    return this.profiles.updateSkill(skillId, dto);
  }

  @Patch('providers/:providerId/tier')
  @ApiOkResponse({ description: 'Changes Provider tier; Providers cannot change their own tier' })
  updateTier(@Param('providerId', ParseIntPipe) providerId: number, @Body() dto: UpdateProviderTierDto) {
    return this.profiles.updateTier(providerId, dto);
  }

  @Patch('providers/:providerId/skills/:skillId/verification')
  @ApiOkResponse({ description: 'Verifies, rejects or resets one Provider skill claim' })
  reviewSkill(
    @Param('providerId', ParseIntPipe) providerId: number,
    @Param('skillId', ParseIntPipe) skillId: number,
    @Body() dto: ReviewProviderSkillDto,
  ) {
    return this.profiles.reviewSkill(providerId, skillId, dto);
  }
}
