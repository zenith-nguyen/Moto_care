import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { DataSource } from 'typeorm';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('health')
@Public()
@Controller('health')
export class HealthController {
  constructor(private readonly database: DataSource) {}

  @Get()
  @ApiOkResponse({ description: 'Service health status' })
  check() {
    return { status: 'ok' };
  }

  @Get('ready')
  @ApiOkResponse({ description: 'API and database are reachable' })
  async ready() {
    try {
      await this.database.query('SELECT 1');
      return { status: 'ok', database: 'ok' };
    } catch {
      throw new ServiceUnavailableException('Database unavailable');
    }
  }
}
