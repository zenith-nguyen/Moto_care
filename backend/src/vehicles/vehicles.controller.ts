import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, ParseIntPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { CreateVehicleDto, UpdateVehicleDto, VehicleResponseDto } from './dto/vehicle.dto';
import { VehiclesService } from './vehicles.service';

@ApiTags('vehicles')
@ApiBearerAuth()
@Roles(UserRole.CUSTOMER)
@Controller('users/me/vehicles')
export class VehiclesController {
  constructor(private readonly vehicles: VehiclesService) {}

  @Get()
  @ApiOkResponse({ type: [VehicleResponseDto] })
  list(@CurrentUser() user: JwtPayload) {
    return this.vehicles.list(user.sub);
  }

  @Post()
  @ApiCreatedResponse({ type: VehicleResponseDto })
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateVehicleDto) {
    return this.vehicles.create(user.sub, dto);
  }

  @Patch(':vehicleId')
  @ApiOkResponse({ type: VehicleResponseDto })
  update(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseIntPipe) vehicleId: number,
    @Body() dto: UpdateVehicleDto,
  ) {
    return this.vehicles.update(user.sub, vehicleId, dto);
  }

  @Delete(':vehicleId')
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Vehicle deleted; another vehicle becomes default when needed' })
  remove(@CurrentUser() user: JwtPayload, @Param('vehicleId', ParseIntPipe) vehicleId: number) {
    return this.vehicles.remove(user.sub, vehicleId);
  }
}
