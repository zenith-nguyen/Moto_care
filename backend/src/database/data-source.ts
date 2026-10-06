import 'dotenv/config';
import { DataSource } from 'typeorm';
import { IncidentType } from '../incident-types/incident-type.entity';
import { Message } from '../messages/message.entity';
import { OrderOffer } from '../orders/order-offer.entity';
import { Order } from '../orders/order.entity';
import { Payment } from '../payments/payment.entity';
import { WalletTransaction } from '../payments/wallet-transaction.entity';
import { Wallet } from '../payments/wallet.entity';
import { WithdrawalRequest } from '../payments/withdrawal-request.entity';
import { Provider } from '../providers/provider.entity';
import { Review } from '../reviews/review.entity';
import { User } from '../users/user.entity';
import { PasswordResetCode } from '../auth/password-reset-code.entity';

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
    OrderOffer,
    Message,
    Review,
    Payment,
    Wallet,
    WalletTransaction,
    WithdrawalRequest,
    PasswordResetCode,
  ],
  migrations: [__dirname + '/migrations/*{.ts,.js}'],
  synchronize: false,
});
