import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { IncidentType } from './incident-type.entity';
import { IncidentTypesController } from './incident-types.controller';

@Module({ imports: [TypeOrmModule.forFeature([IncidentType])], controllers: [IncidentTypesController] })
export class IncidentTypesModule {}
