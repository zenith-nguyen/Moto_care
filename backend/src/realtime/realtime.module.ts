import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Message } from '../messages/message.entity';

@Module({ imports: [TypeOrmModule.forFeature([Message])] })
export class RealtimeModule {}
