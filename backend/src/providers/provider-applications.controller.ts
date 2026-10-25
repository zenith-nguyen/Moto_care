import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RateLimit } from '../common/decorators/rate-limit.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { ApplyProviderDto } from './dto/apply-provider.dto';
import { ProvidersService } from './providers.service';

@ApiTags('providers')
@ApiBearerAuth()
@Controller('provider-applications')
export class ProviderApplicationsController {
  constructor(private readonly providers: ProvidersService) {}

  @Post()
  @Roles(UserRole.CUSTOMER)
  @RateLimit(5, 60_000)
  @ApiCreatedResponse({
    description:
      'Customer submits a provider application; the account stays a customer until an admin approves it',
  })
  apply(@CurrentUser() user: JwtPayload, @Body() dto: ApplyProviderDto) {
    return this.providers.apply(user.sub, dto);
  }

  @Get('me')
  @Roles(UserRole.CUSTOMER, UserRole.PROVIDER)
  @ApiOkResponse({ description: "The caller's own provider application status" })
  mine(@CurrentUser() user: JwtPayload) {
    return this.providers.getApplication(user.sub);
  }
}
