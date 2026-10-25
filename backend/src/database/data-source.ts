import 'dotenv/config';
import { DataSource } from 'typeorm';
import { IncidentType } from '../incident-types/incident-type.entity';
import { Message } from '../messages/message.entity';
import { OrderOffer } from '../orders/order-offer.entity';
import { Order } from '../orders/order.entity';
import { OrderPhoto } from '../order-photos/order-photo.entity';
import { Payment } from '../payments/payment.entity';
import { WalletTransaction } from '../payments/wallet-transaction.entity';
import { Wallet } from '../payments/wallet.entity';
import { WithdrawalRequest } from '../payments/withdrawal-request.entity';
import { Provider } from '../providers/provider.entity';
import { Review } from '../reviews/review.entity';
import { User } from '../users/user.entity';
import { PasswordResetCode } from '../auth/password-reset-code.entity';
import { OrderPriceProposal } from '../orders/order-price-proposal.entity';
import { PaymentAdjustment } from '../payments/payment-adjustment.entity';
import { SepayWebhookEvent } from '../payments/sepay-webhook-event.entity';
import { Vehicle } from '../vehicles/vehicle.entity';
import { ProviderSkill } from '../providers/provider-skill.entity';
import { Skill } from '../providers/skill.entity';
import { ServiceLocation } from '../service-locations/service-location.entity';
import { Notification } from '../notifications/notification.entity';
import { NotificationDelivery } from '../notifications/notification-delivery.entity';
import { UserDevice } from '../notifications/user-device.entity';
import { WithdrawalPayout } from '../payments/withdrawal-payout.entity';
import { SepayPayoutWebhookEvent } from '../payments/sepay-payout-webhook-event.entity';

export default new DataSource({
  type: 'postgres',
  host: process.env.DATABASE_HOST,
  port: Number(process.env.DATABASE_PORT ?? 5432),
  username: process.env.DATABASE_USER,
  password: process.env.DATABASE_PASSWORD,
  database: process.env.DATABASE_NAME,
  entities: [
    User,
    Provider,
    IncidentType,
    Order,
    OrderPhoto,
    OrderOffer,
    Message,
    Review,
    Payment,
    Wallet,
    WalletTransaction,
    WithdrawalRequest,
    WithdrawalPayout,
    PasswordResetCode,
    OrderPriceProposal,
    PaymentAdjustment,
    SepayWebhookEvent,
    SepayPayoutWebhookEvent,
    Vehicle,
    Skill,
    ProviderSkill,
    ServiceLocation,
    Notification,
    NotificationDelivery,
    UserDevice,
  ],
  migrations: [__dirname + '/migrations/*{.ts,.js}'],
  migrationsTransactionMode: 'each',
  synchronize: false,
});
