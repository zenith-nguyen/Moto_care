import { JwtService } from '@nestjs/jwt';
import { jest } from '@jest/globals';
import { Socket } from 'socket.io';
import { DataSource, EntityTarget } from 'typeorm';
import { ApprovalStatus } from '../src/common/enums/approval-status.enum';
import { UserRole } from '../src/common/enums/user-role.enum';
import { UserStatus } from '../src/common/enums/user-status.enum';
import { Order } from '../src/orders/order.entity';
import { Provider } from '../src/providers/provider.entity';
import { RealtimeGateway } from '../src/realtime/realtime.gateway';
import { User } from '../src/users/user.entity';

type SocketDouble = Socket & {
  join: jest.Mock;
  disconnect: jest.Mock;
};

describe('RealtimeGateway', () => {
  const jwt = { verifyAsync: jest.fn() };
  const userRepository = { findOneBy: jest.fn() };
  const providerRepository = { findOneBy: jest.fn() };
  const orderRepository = { findOneBy: jest.fn() };
  const database = {
    getRepository: jest.fn((entity: EntityTarget<unknown>) => {
      if (entity === User) return userRepository;
      if (entity === Provider) return providerRepository;
      if (entity === Order) return orderRepository;
      throw new Error('Unexpected repository');
    }),
  };
  let gateway: RealtimeGateway;

  beforeEach(() => {
    jest.clearAllMocks();
    gateway = new RealtimeGateway(jwt as unknown as JwtService, database as unknown as DataSource);
  });

  function socket(auth: Record<string, unknown>): SocketDouble {
    return {
      handshake: { auth },
      data: {},
      join: jest.fn(),
      disconnect: jest.fn(),
    } as unknown as SocketDouble;
  }

  it('disconnects when the JWT account version no longer matches', async () => {
    jwt.verifyAsync.mockResolvedValue({ sub: 7, role: UserRole.CUSTOMER, ver: 1 });
    userRepository.findOneBy.mockResolvedValue({
      id: 7, role: UserRole.CUSTOMER, status: UserStatus.ACTIVE, authVersion: 2,
    });
    const client = socket({ token: 'stale-token' });

    await gateway.handleConnection(client);

    expect(client.join).not.toHaveBeenCalled();
    expect(client.disconnect).toHaveBeenCalledWith(true);
  });

  it('joins only approved online providers to their private offer room', async () => {
    jwt.verifyAsync.mockResolvedValue({ sub: 8, role: UserRole.PROVIDER, ver: 0 });
    userRepository.findOneBy.mockResolvedValue({
      id: 8, role: UserRole.PROVIDER, status: UserStatus.ACTIVE, authVersion: 0,
    });
    providerRepository.findOneBy.mockResolvedValue({
      id: 12, userId: 8, isOnline: true, approvalStatus: ApprovalStatus.APPROVED,
    });
    const online = socket({ token: 'provider-token' });

    await gateway.handleConnection(online);

    expect(online.join).toHaveBeenCalledWith('provider:12');
    expect(online.disconnect).not.toHaveBeenCalled();

    providerRepository.findOneBy.mockResolvedValue({
      id: 12, userId: 8, isOnline: false, approvalStatus: ApprovalStatus.APPROVED,
    });
    const offline = socket({ token: 'provider-token' });
    await gateway.handleConnection(offline);
    expect(offline.join).not.toHaveBeenCalled();
    expect(offline.disconnect).not.toHaveBeenCalled();
  });

  it('rejects a user who is not an order participant', async () => {
    jwt.verifyAsync.mockResolvedValue({ sub: 9, role: UserRole.CUSTOMER, ver: 0 });
    userRepository.findOneBy.mockResolvedValue({
      id: 9, role: UserRole.CUSTOMER, status: UserStatus.ACTIVE, authVersion: 0,
    });
    orderRepository.findOneBy.mockResolvedValue({ id: 55, customerId: 10, providerId: null });
    const client = socket({ token: 'outsider-token', orderId: 55 });

    await gateway.handleConnection(client);

    expect(client.join).not.toHaveBeenCalled();
    expect(client.disconnect).toHaveBeenCalledWith(true);
  });

  it('routes each realtime event to the documented private room', () => {
    const emit = jest.fn();
    const to = jest.fn(() => ({ emit }));
    Object.defineProperty(gateway, 'server', { value: { to } });
    const timestamp = new Date('2026-10-07T01:02:03.000Z');
    const message = {
      id: 4,
      senderId: 9,
      content: 'On my way',
      image: null,
      createdAt: timestamp,
    };

    gateway.offerCreated(12, 55, 91, timestamp);
    expect(to).toHaveBeenLastCalledWith('provider:12');
    expect(emit).toHaveBeenLastCalledWith('offer.created', { orderId: 55, offerId: 91, expiresAt: timestamp });

    gateway.offerExpired(12, 55, 91);
    expect(to).toHaveBeenLastCalledWith('provider:12');
    expect(emit).toHaveBeenLastCalledWith('offer.expired', { orderId: 55, offerId: 91 });

    gateway.orderStatusChanged(55, 'ACCEPTED');
    expect(to).toHaveBeenLastCalledWith('order:55');
    expect(emit).toHaveBeenLastCalledWith('order.status_changed', { orderId: 55, status: 'ACCEPTED' });

    gateway.providerLocation(55, 12, 10.77, 106.7, timestamp);
    expect(to).toHaveBeenLastCalledWith('order:55');
    expect(emit).toHaveBeenLastCalledWith('provider.location_updated', {
      orderId: 55, providerId: 12, latitude: 10.77, longitude: 106.7, updatedAt: timestamp,
    });

    gateway.messageCreated(55, message);
    expect(to).toHaveBeenLastCalledWith('order:55');
    expect(emit).toHaveBeenLastCalledWith('message.created', { orderId: 55, ...message });
  });
});
