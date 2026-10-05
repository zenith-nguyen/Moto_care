import { JwtService } from '@nestjs/jwt';
import { Injectable } from '@nestjs/common';
import { WebSocketGateway, WebSocketServer, OnGatewayConnection } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { DataSource } from 'typeorm';
import { ApprovalStatus } from '../common/enums/approval-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { Order } from '../orders/order.entity';
import { Provider } from '../providers/provider.entity';
import { User } from '../users/user.entity';

function allowedOrigin(origin: string | undefined, callback: (error: Error | null, allow?: boolean) => void) {
  const origins = (process.env.CORS_ORIGIN ?? 'http://localhost:3000').split(',').map((value) => value.trim());
  callback(null, !origin || origins.includes(origin));
}

@Injectable()
@WebSocketGateway({ cors: { origin: allowedOrigin } })
export class RealtimeGateway implements OnGatewayConnection {
  @WebSocketServer()
  private server!: Server;

  constructor(private readonly jwt: JwtService, private readonly database: DataSource) {}

  async handleConnection(client: Socket): Promise<void> {
    try {
      const token = client.handshake.auth?.token as unknown;
      if (typeof token !== 'string' || !token) throw new Error('Missing token');
      const payload = await this.jwt.verifyAsync<JwtPayload>(token);
      if (!Number.isInteger(payload.sub) || !Object.values(UserRole).includes(payload.role)) {
        throw new Error('Invalid token payload');
      }
      const user = await this.database.getRepository(User).findOneBy({ id: payload.sub });
      if (!user || user.status !== UserStatus.ACTIVE || user.role !== payload.role) throw new Error('Inactive account');
      client.data.userId = user.id;
      client.data.role = user.role;

      if (user.role === UserRole.PROVIDER) {
        const provider = await this.database.getRepository(Provider).findOneBy({ userId: user.id });
        if (provider?.isOnline && provider.approvalStatus === ApprovalStatus.APPROVED) {
          await client.join(`provider:${provider.id}`);
        }
      }
      const requestedOrderId = client.handshake.auth?.orderId as unknown;
      if (requestedOrderId !== undefined) {
        const orderId = Number(requestedOrderId);
        if (!Number.isSafeInteger(orderId) || orderId <= 0) throw new Error('Invalid order');
        const order = await this.database.getRepository(Order).findOneBy({ id: orderId });
        const provider = user.role === UserRole.PROVIDER
          ? await this.database.getRepository(Provider).findOneBy({ userId: user.id }) : null;
        if (!order || (order.customerId !== user.id && order.providerId !== provider?.id)) {
          throw new Error('Not a participant');
        }
        await client.join(`order:${order.id}`);
      }
    } catch {
      client.disconnect(true);
    }
  }

  providerLocation(orderId: number, providerId: number, latitude: number, longitude: number, updatedAt: Date): void {
    this.server.to(`order:${orderId}`).emit('provider.location_updated', {
      orderId, providerId, latitude, longitude, updatedAt,
    });
  }

  messageCreated(orderId: number, message: { id: number; senderId: number; content: string; createdAt: Date }): void {
    this.server.to(`order:${orderId}`).emit('message.created', { orderId, ...message });
  }

  offerCreated(providerId: number, orderId: number, offerId: number, expiresAt: Date): void {
    this.server.to(`provider:${providerId}`).emit('offer.created', { orderId, offerId, expiresAt });
  }

  offerExpired(providerId: number, orderId: number, offerId: number): void {
    this.server.to(`provider:${providerId}`).emit('offer.expired', { orderId, offerId });
  }

  orderStatusChanged(orderId: number, status: string): void {
    this.server.to(`order:${orderId}`).emit('order.status_changed', { orderId, status });
  }
}
