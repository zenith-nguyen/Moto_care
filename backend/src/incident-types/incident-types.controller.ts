import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiProperty, ApiTags } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IncidentType } from './incident-type.entity';

class IncidentTypeOptionDto {
  @ApiProperty()
  id!: number;

  @ApiProperty({ example: 'FLAT_TIRE' })
  code!: string;

  @ApiProperty({ example: 'Xẹp lốp' })
  name!: string;

  @ApiProperty({ example: '100000.00', description: 'Decimal money value as a string' })
  basePrice!: string;
}

@ApiTags('incident-types')
@ApiBearerAuth()
@Controller('incident-types')
export class IncidentTypesController {
  constructor(@InjectRepository(IncidentType) private readonly incidents: Repository<IncidentType>) {}

  @Get()
  @ApiOkResponse({ description: 'Active incident types and current base prices', type: [IncidentTypeOptionDto] })
  async list() {
    const incidents = await this.incidents.find({ where: { isActive: true }, order: { id: 'ASC' } });
    return incidents.map(({ id, code, name, basePrice }) => ({ id, code, name, basePrice }));
  }
}
