import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import {
  NearbyServiceLocationsQueryDto,
  ServiceLocationResponseDto,
  ViewportServiceLocationsQueryDto,
} from './dto/service-location-query.dto';
import { ServiceLocationsService } from './service-locations.service';

@ApiTags('service-locations')
@ApiBearerAuth()
@Controller('service-locations')
export class ServiceLocationsController {
  constructor(private readonly locations: ServiceLocationsService) {}

  @Get('viewport')
  @ApiOkResponse({
    description: 'Up to 200 active informational map markers inside the visible bounds',
    type: [ServiceLocationResponseDto],
  })
  viewport(@Query() query: ViewportServiceLocationsQueryDto) {
    return this.locations.inViewport(query);
  }

  @Get('nearby')
  @ApiOkResponse({
    description: 'Active informational map markers ordered by straight-line PostGIS distance',
    type: [ServiceLocationResponseDto],
  })
  nearby(@Query() query: NearbyServiceLocationsQueryDto) {
    return this.locations.nearby(query);
  }
}
