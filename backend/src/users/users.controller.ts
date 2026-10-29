import { Body, Controller, Get, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { UpdateProfileDto, UserProfileResponseDto } from './dto/update-profile.dto';
import { UsersService } from './users.service';

@ApiTags('users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiOkResponse({ description: 'Authenticated user profile', type: UserProfileResponseDto })
  async me(@CurrentUser() currentUser: JwtPayload) {
    const user = await this.usersService.findById(currentUser.sub);
    return this.usersService.presentProfile(user);
  }

  @Patch('me')
  @ApiOkResponse({
    description: 'Updates the authenticated user profile; email and role cannot be changed here',
    type: UserProfileResponseDto,
  })
  updateMe(@CurrentUser() currentUser: JwtPayload, @Body() dto: UpdateProfileDto) {
    return this.usersService.updateProfile(currentUser.sub, dto);
  }
}
