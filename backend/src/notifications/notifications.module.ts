import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationDelivery } from './notification-delivery.entity';
import { Notification } from './notification.entity';
import { FirebasePushGateway } from './firebase-push.gateway';
import { NotificationDeliveryService } from './notification-delivery.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { PushGateway } from './push-gateway.port';
import { UserDevice } from './user-device.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Notification, NotificationDelivery, UserDevice])],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    NotificationDeliveryService,
    FirebasePushGateway,
    { provide: PushGateway, useExisting: FirebasePushGateway },
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
