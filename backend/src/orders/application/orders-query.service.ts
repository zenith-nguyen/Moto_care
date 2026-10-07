import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource, MoreThan } from 'typeorm';
import { OfferStatus } from '../../common/enums/offer-status.enum';
import { OrderStatus } from '../../common/enums/order-status.enum';
import { UserRole } from '../../common/enums/user-role.enum';
import { PaymentQueryPort } from '../../payments/application/payment-query.port';
import { Provider } from '../../providers/provider.entity';
import { OrderOffer } from '../order-offer.entity';
import { OrderPriceProposal } from '../order-price-proposal.entity';
import { Order } from '../order.entity';
import { presentOrderPricing, presentPaymentAdjustment, presentPriceProposal } from '../presentation/order.presenter';

const providerLocationStatuses = new Set([
  OrderStatus.ACCEPTED,
  OrderStatus.ARRIVED,
  OrderStatus.IN_PROGRESS,
  OrderStatus.AWAITING_PRICE_APPROVAL,
  OrderStatus.PRICE_DISPUTED,
  OrderStatus.AWAITING_PAYMENT,
  OrderStatus.PAID,
]);

@Injectable()
export class OrdersQueryService {
  constructor(
    private readonly database: DataSource,
    private readonly payments: PaymentQueryPort,
  ) {}

  async getById(orderId: number, userId: number) {
    const order = await this.database.getRepository(Order).findOne({
      where: { id: orderId },
      relations: { incidentType: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    await this.assertCanView(order, userId);

    const [financials, priceProposal, providerLocation] = await Promise.all([
      this.payments.getOrderFinancials(orderId),
      this.database.getRepository(OrderPriceProposal).findOne({ where: { orderId }, order: { id: 'DESC' } }),
      this.providerLocation(order),
    ]);

    return {
      id: order.id,
      code: order.code,
      status: order.status,
      customerId: order.customerId,
      providerId: order.providerId,
      incidentType: { id: order.incidentType.id, name: order.incidentType.name },
      customerLocation: order.customerLocation,
      estimatedPrice: order.estimatedPrice,
      pricing: presentOrderPricing(order),
      extraCost: order.extraCost,
      discountAmount: order.discountAmount,
      finalPrice: order.finalPrice,
      payment: financials.payment,
      providerLocation,
      priceProposal: priceProposal ? presentPriceProposal(priceProposal) : null,
      paymentAdjustment: financials.adjustment ? presentPaymentAdjustment(financials.adjustment) : null,
      message: order.status === OrderStatus.AWAITING_PREPAYMENT
        ? 'Awaiting prepayment; demo confirmation is not a real bank transfer'
        : order.status === OrderStatus.PENDING_MATCH ? 'No provider found yet; retry matching later' : null,
    };
  }

  async listMine(userId: number, role: UserRole) {
    let where: { customerId: number } | { providerId: number };
    if (role === UserRole.CUSTOMER) {
      where = { customerId: userId };
    } else {
      const provider = await this.database.getRepository(Provider).findOneBy({ userId });
      if (!provider) throw new NotFoundException('Provider profile not found');
      where = { providerId: provider.id };
    }
    const orders = await this.database.getRepository(Order).find({
      where,
      order: { createdAt: 'DESC', id: 'DESC' },
      take: 30,
    });
    return orders.map((order) => ({
      id: order.id,
      code: order.code,
      status: order.status,
      customerId: order.customerId,
      providerId: order.providerId,
      incidentTypeId: order.incidentTypeId,
      estimatedPrice: order.estimatedPrice,
      extraCost: order.extraCost,
      discountAmount: order.discountAmount,
      finalPrice: order.finalPrice,
      createdAt: order.createdAt,
      pricing: presentOrderPricing(order),
    }));
  }

  private async assertCanView(order: Order, userId: number): Promise<void> {
    if (order.customerId === userId) return;
    const provider = await this.database.getRepository(Provider).findOneBy({ userId });
    if (!provider) throw new NotFoundException('Order not found');
    const pendingOffer = await this.database.getRepository(OrderOffer).findOne({
      where: {
        orderId: order.id,
        providerId: provider.id,
        status: OfferStatus.PENDING,
        expiresAt: MoreThan(new Date()),
      },
    });
    if (order.providerId !== provider.id && !pendingOffer) throw new NotFoundException('Order not found');
  }

  private async providerLocation(order: Order) {
    if (!order.providerId || !providerLocationStatuses.has(order.status)) return null;
    return (await this.database.getRepository(Provider).findOneBy({ id: order.providerId }))?.currentLocation ?? null;
  }
}
