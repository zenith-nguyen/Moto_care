import { ConflictException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PaymentAdjustmentStatus, PaymentAdjustmentType } from '../common/enums/payment-adjustment.enum';
import { PaymentStatus } from '../common/enums/payment-status.enum';
import { PriceProposalStatus } from '../common/enums/price-proposal-status.enum';
import { centsToMoney, moneyToCents } from '../common/utils/money';
import { PaymentAdjustment } from '../payments/payment-adjustment.entity';
import { Payment } from '../payments/payment.entity';
import { Provider } from '../providers/provider.entity';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { AdminPriceResolution, CreatePriceProposalDto } from './dto/price-proposal.dto';
import { OrderPriceProposal } from './order-price-proposal.entity';
import { Order } from './order.entity';

@Injectable()
export class PriceAdjustmentsService {
  constructor(
    private readonly database: DataSource,
    @Optional() private readonly realtime?: RealtimeGateway,
  ) {}

  async propose(orderId: number, providerUserId: number, dto: CreatePriceProposalDto) {
    const result = await this.database.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      const provider = await this.lockProvider(manager, providerUserId);
      if (order.providerId !== provider.id) throw new NotFoundException('Order not found');
      if (order.status !== OrderStatus.IN_PROGRESS) {
        throw new ConflictException('Final price can only be proposed while service is in progress');
      }
      moneyToCents(dto.final_price);
      const proposal = await manager.getRepository(OrderPriceProposal).save(
        manager.getRepository(OrderPriceProposal).create({
          orderId,
          providerId: provider.id,
          proposedFinalPrice: dto.final_price,
          reason: dto.reason.trim(),
          status: PriceProposalStatus.PENDING,
        }),
      );
      order.status = OrderStatus.AWAITING_PRICE_APPROVAL;
      await manager.getRepository(Order).save(order);
      return { response: await this.response(manager, order, proposal), changed: true };
    });
    if (result.changed) this.realtime?.orderStatusChanged(orderId, result.response.orderStatus);
    return result.response;
  }

  async approve(orderId: number, proposalId: number, customerId: number) {
    const result = await this.database.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      if (order.customerId !== customerId) throw new NotFoundException('Order not found');
      const proposal = await this.lockProposal(manager, orderId, proposalId);
      if (proposal.status === PriceProposalStatus.APPROVED) {
        return { response: await this.response(manager, order, proposal), changed: false };
      }
      if (order.status !== OrderStatus.AWAITING_PRICE_APPROVAL || proposal.status !== PriceProposalStatus.PENDING) {
        throw new ConflictException('Price proposal is no longer awaiting approval');
      }
      proposal.status = PriceProposalStatus.APPROVED;
      proposal.decidedById = customerId;
      proposal.decidedAt = new Date();
      await this.applyApprovedPrice(manager, order, proposal);
      return { response: await this.response(manager, order, proposal), changed: true };
    });
    if (result.changed) this.realtime?.orderStatusChanged(orderId, result.response.orderStatus);
    return result.response;
  }

  async reject(orderId: number, proposalId: number, customerId: number, reason: string) {
    const result = await this.database.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      if (order.customerId !== customerId) throw new NotFoundException('Order not found');
      const proposal = await this.lockProposal(manager, orderId, proposalId);
      if (order.status !== OrderStatus.AWAITING_PRICE_APPROVAL || proposal.status !== PriceProposalStatus.PENDING) {
        throw new ConflictException('Price proposal is no longer awaiting a decision');
      }
      proposal.status = PriceProposalStatus.REJECTED;
      proposal.customerReason = reason.trim();
      proposal.decidedById = customerId;
      proposal.decidedAt = new Date();
      order.status = OrderStatus.IN_PROGRESS;
      await manager.getRepository(OrderPriceProposal).save(proposal);
      await manager.getRepository(Order).save(order);
      return { response: await this.response(manager, order, proposal), changed: true };
    });
    if (result.changed) this.realtime?.orderStatusChanged(orderId, result.response.orderStatus);
    return result.response;
  }

  async dispute(orderId: number, proposalId: number, providerUserId: number, reason: string) {
    const result = await this.database.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      const provider = await this.lockProvider(manager, providerUserId);
      if (order.providerId !== provider.id) throw new NotFoundException('Order not found');
      const proposal = await this.lockProposal(manager, orderId, proposalId);
      if (proposal.providerId !== provider.id || proposal.status !== PriceProposalStatus.REJECTED || order.status !== OrderStatus.IN_PROGRESS) {
        throw new ConflictException('Rejected proposal cannot be disputed now');
      }
      proposal.status = PriceProposalStatus.DISPUTED;
      proposal.disputeReason = reason.trim();
      order.status = OrderStatus.PRICE_DISPUTED;
      await manager.getRepository(OrderPriceProposal).save(proposal);
      await manager.getRepository(Order).save(order);
      return { response: await this.response(manager, order, proposal), changed: true };
    });
    if (result.changed) this.realtime?.orderStatusChanged(orderId, result.response.orderStatus);
    return result.response;
  }

  async pendingDisputes() {
    const proposals = await this.database.getRepository(OrderPriceProposal).find({
      where: { status: PriceProposalStatus.DISPUTED },
      relations: { order: true },
      order: { updatedAt: 'ASC', id: 'ASC' },
      take: 50,
    });
    return proposals.map((proposal) => this.formatProposal(proposal, proposal.order.status));
  }

  async pendingRefundAdjustments() {
    const adjustments = await this.database.getRepository(PaymentAdjustment).find({
      where: { type: PaymentAdjustmentType.REFUND, status: PaymentAdjustmentStatus.PENDING },
      relations: { order: true },
      order: { createdAt: 'ASC', id: 'ASC' },
      take: 50,
    });
    return adjustments.map((adjustment) => ({
      ...this.formatAdjustment(adjustment),
      order: {
        id: adjustment.order.id,
        code: adjustment.order.code,
        customerId: adjustment.order.customerId,
        providerId: adjustment.order.providerId,
        estimatedPrice: adjustment.order.estimatedPrice,
        finalPrice: adjustment.order.finalPrice,
      },
    }));
  }

  async resolveDispute(proposalId: number, adminId: number, decision: AdminPriceResolution, reason: string) {
    const result = await this.database.transaction(async (manager) => {
      const initial = await manager.getRepository(OrderPriceProposal).findOneBy({ id: proposalId });
      if (!initial) throw new NotFoundException('Price dispute not found');
      const order = await this.lockOrder(manager, initial.orderId);
      const proposal = await this.lockProposal(manager, order.id, proposalId);
      if (proposal.status === PriceProposalStatus.RESOLVED_APPROVED || proposal.status === PriceProposalStatus.RESOLVED_REJECTED) {
        return { response: await this.response(manager, order, proposal), changed: false };
      }
      if (proposal.status !== PriceProposalStatus.DISPUTED || order.status !== OrderStatus.PRICE_DISPUTED) {
        throw new ConflictException('Price proposal is not awaiting admin resolution');
      }
      proposal.resolutionReason = reason.trim();
      proposal.decidedById = adminId;
      proposal.decidedAt = new Date();
      if (decision === AdminPriceResolution.APPROVE) {
        proposal.status = PriceProposalStatus.RESOLVED_APPROVED;
        await this.applyApprovedPrice(manager, order, proposal);
      } else {
        proposal.status = PriceProposalStatus.RESOLVED_REJECTED;
        order.status = OrderStatus.IN_PROGRESS;
        await manager.getRepository(OrderPriceProposal).save(proposal);
        await manager.getRepository(Order).save(order);
      }
      return { response: await this.response(manager, order, proposal), changed: true };
    });
    if (result.changed) this.realtime?.orderStatusChanged(result.response.orderId, result.response.orderStatus);
    return result.response;
  }

  private async applyApprovedPrice(manager: EntityManager, order: Order, proposal: OrderPriceProposal): Promise<void> {
    const payment = await manager.getRepository(Payment).findOne({
      where: { orderId: order.id },
      lock: { mode: 'pessimistic_write' },
      order: { id: 'ASC' },
    });
    if (!payment || payment.status !== PaymentStatus.PAID) {
      throw new ConflictException('Prepayment must be paid before final-price approval');
    }
    const prepaid = moneyToCents(payment.amount);
    const finalPrice = moneyToCents(proposal.proposedFinalPrice);
    order.finalPrice = centsToMoney(finalPrice);
    order.extraCost = centsToMoney(finalPrice > prepaid ? finalPrice - prepaid : 0n);
    order.discountAmount = centsToMoney(finalPrice < prepaid ? prepaid - finalPrice : 0n);
    if (finalPrice === prepaid) {
      order.status = OrderStatus.PAID;
    } else {
      await manager.getRepository(PaymentAdjustment).save(
        manager.getRepository(PaymentAdjustment).create({
          orderId: order.id,
          paymentId: payment.id,
          type: finalPrice > prepaid ? PaymentAdjustmentType.CHARGE : PaymentAdjustmentType.REFUND,
          amount: centsToMoney(finalPrice > prepaid ? finalPrice - prepaid : prepaid - finalPrice),
          status: PaymentAdjustmentStatus.PENDING,
          isDemo: false,
        }),
      );
      order.status = OrderStatus.AWAITING_PAYMENT;
    }
    await manager.getRepository(OrderPriceProposal).save(proposal);
    await manager.getRepository(Order).save(order);
  }

  private async response(manager: EntityManager, order: Order, proposal: OrderPriceProposal) {
    const adjustment = await manager.getRepository(PaymentAdjustment).findOneBy({ orderId: order.id });
    return {
      orderId: order.id,
      orderStatus: order.status,
      proposal: this.formatProposal(proposal, order.status),
      paymentAdjustment: adjustment ? this.formatAdjustment(adjustment) : null,
    };
  }

  private formatProposal(proposal: OrderPriceProposal, orderStatus: OrderStatus) {
    return {
      id: proposal.id,
      orderId: proposal.orderId,
      orderStatus,
      providerId: proposal.providerId,
      proposedFinalPrice: proposal.proposedFinalPrice,
      reason: proposal.reason,
      status: proposal.status,
      customerReason: proposal.customerReason,
      disputeReason: proposal.disputeReason,
      resolutionReason: proposal.resolutionReason,
      decidedById: proposal.decidedById,
      decidedAt: proposal.decidedAt,
      createdAt: proposal.createdAt,
      updatedAt: proposal.updatedAt,
    };
  }

  private formatAdjustment(adjustment: PaymentAdjustment) {
    return {
      id: adjustment.id,
      type: adjustment.type,
      amount: adjustment.amount,
      status: adjustment.status,
      isDemo: adjustment.isDemo,
      settledAt: adjustment.settledAt,
    };
  }

  private async lockOrder(manager: EntityManager, orderId: number): Promise<Order> {
    const order = await manager.getRepository(Order).findOne({ where: { id: orderId }, lock: { mode: 'pessimistic_write' } });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  private async lockProvider(manager: EntityManager, userId: number): Promise<Provider> {
    const provider = await manager.getRepository(Provider).findOne({ where: { userId }, lock: { mode: 'pessimistic_write' } });
    if (!provider) throw new NotFoundException('Provider profile not found');
    return provider;
  }

  private async lockProposal(manager: EntityManager, orderId: number, proposalId: number): Promise<OrderPriceProposal> {
    const proposal = await manager.getRepository(OrderPriceProposal).findOne({
      where: { id: proposalId, orderId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!proposal) throw new NotFoundException('Price proposal not found');
    return proposal;
  }
}
