import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentWeatherQueryDto } from './dto/current-weather-query.dto';
import { WeatherService } from './weather.service';

@ApiTags('weather')
@ApiBearerAuth()
@Controller('weather')
export class PricingController {
  constructor(private readonly weather: WeatherService) {}

  @Get('current')
  @ApiOkResponse({
    description: 'Current Open-Meteo snapshot. FALLBACK means live weather is disabled or temporarily unavailable.',
  })
  current(@Query() query: CurrentWeatherQueryDto) {
    return this.weather.current(query.latitude, query.longitude);
  }
}
