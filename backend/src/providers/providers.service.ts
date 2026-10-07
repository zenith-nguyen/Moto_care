import { ForbiddenException, Injectable, NotFoundException, Optional, UnprocessableEntityException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { MoreThan, Repository } from 'typeorm';
import { ApprovalStatus } from '../common/enums/approval-status.enum';
import { OfferStatus } from '../common/enums/offer-status.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { OrderOffer } from '../orders/order-offer.entity';
import { Order } from '../orders/order.entity';
import { OrderStatus } from '../common/enums/order-status.enum';
import { RealtimePublisher } from '../realtime/realtime-publisher.port';
import { User } from '../users/user.entity';
import { Provider } from './provider.entity';
import { UpdateLocationDto } from './dto/update-location.dto';

@Injectable()
export class ProvidersService {
  constructor(
    @InjectRepository(Provider) private readonly providers: Repository<Provider>,
    @InjectRepository(OrderOffer) private readonly offers: Repository<OrderOffer>,
    @InjectRepository(User) private readonly users: Repository<User>,
    private readonly config: ConfigService,
    @Optional() @InjectRepository(Order) private readonly orders?: Repository<Order>,
    @Optional() private readonly realtime?: RealtimePublisher,
  ) {}

  private async ownProvider(userId: number): Promise<Provider> {
    const provider = await this.providers.findOneBy({ userId });
    if (!provider) throw new NotFoundException('Provider profile not found');
    return provider;
  }

  async updateLocation(userId: number, location: UpdateLocationDto) {
    const provider = await this.ownProvider(userId);
    const lastSeenAt = new Date();
    await this.providers.update(provider.id, {
      currentLocation: { type: 'Point', coordinates: [location.longitude, location.latitude] },
      lastSeenAt,
    });
    return { id: provider.id, isOnline: provider.isOnline, lastSeenAt };
  }

  async updateOrderLocation(userId: number, orderId: number, location: UpdateLocationDto) {
    const provider = await this.ownProvider(userId);
    const order = await this.orders?.findOneBy({ id: orderId, providerId: provider.id });
    if (!order || ![
      OrderStatus.ACCEPTED,
      OrderStatus.ARRIVED,
      OrderStatus.IN_PROGRESS,
      OrderStatus.AWAITING_PRICE_APPROVAL,
      OrderStatus.PRICE_DISPUTED,
      OrderStatus.AWAITING_PAYMENT,
      OrderStatus.PAID,
    ].includes(order.status)) {
      throw new NotFoundException('Active order not found for provider');
    }
    const result = await this.updateLocation(userId, location);
    this.realtime?.providerLocation(orderId, provider.id, location.latitude, location.longitude, result.lastSeenAt);
    return { orderId, providerId: provider.id, ...result };
  }

  async updateStatus(userId: number, isOnline: boolean) {
    const provider = await this.ownProvider(userId);
    if (isOnline) {
      const user = await this.users.findOneByOrFail({ id: userId });
      if (provider.approvalStatus !== ApprovalStatus.APPROVED || user.status !== UserStatus.ACTIVE) {
        throw new ForbiddenException('Provider must be approved and active to go online');
      }
      const freshSince = Date.now() - this.config.getOrThrow<number>('PROVIDER_LOCATION_MAX_AGE_SECONDS') * 1000;
      if (!provider.currentLocation || !provider.lastSeenAt || provider.lastSeenAt.getTime() <= freshSince) {
        throw new UnprocessableEntityException('Update your location before going online');
      }
    }
    await this.providers.update(provider.id, { isOnline });
    return { id: provider.id, isOnline, lastSeenAt: provider.lastSeenAt };
  }

  async pendingOffers(userId: number) {
    const provider = await this.ownProvider(userId);
    const offers = await this.offers.find({
      where: { providerId: provider.id, status: OfferStatus.PENDING, expiresAt: MoreThan(new Date()) },
      relations: { order: { incidentType: true } },
      order: { expiresAt: 'ASC' },
    });
    return offers.map((offer) => ({
      id: offer.id,
      orderId: offer.orderId,
      expiresAt: offer.expiresAt,
      order: {
        code: offer.order.code,
        incidentType: { id: offer.order.incidentType.id, name: offer.order.incidentType.name },
        estimatedPrice: offer.order.estimatedPrice,
        pricing: {
          basePrice: offer.order.basePrice,
          weatherSurcharge: offer.order.weatherSurcharge,
          weatherMultiplier: offer.order.weatherMultiplier,
          weatherCategory: offer.order.weatherCategory,
          weatherSource: offer.order.weatherSource,
          weatherObservedAt: offer.order.weatherObservedAt,
          weatherCode: offer.order.weatherCode,
          precipitationMm: offer.order.weatherPrecipitationMm,
          windSpeedKmh: offer.order.weatherWindSpeedKmh,
          windGustKmh: offer.order.weatherWindGustKmh,
          attribution: offer.order.weatherSource === 'OPEN_METEO' ? 'Weather data by Open-Meteo.com' : null,
        },
        customerLocation: offer.order.customerLocation,
      },
    }));
  }
}
