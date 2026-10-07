import { Controller, Get, NotFoundException } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { DataSource } from 'typeorm';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { Provider } from '../providers/provider.entity';
import { Wallet } from './wallet.entity';
import { WalletTransaction } from './wallet-transaction.entity';
import { centsToMoney, moneyToCents } from '../common/utils/money';

@ApiTags('wallets')
@ApiBearerAuth()
@Roles(UserRole.PROVIDER)
@Controller('wallets')
export class WalletsController {
  constructor(private readonly database: DataSource) {}

  @Get('me')
  @ApiOkResponse({ description: 'Demo ledger balance and latest transactions; not withdrawable real funds' })
  async mine(@CurrentUser() user: JwtPayload) {
    const provider = await this.database.getRepository(Provider).findOneBy({ userId: user.sub });
    if (!provider) throw new NotFoundException('Provider profile not found');
    const wallet = await this.database.getRepository(Wallet).findOneBy({ providerId: provider.id });
    const transactions = wallet ? await this.database.getRepository(WalletTransaction).find({
      where: { walletId: wallet.id }, order: { createdAt: 'DESC', id: 'DESC' }, take: 20,
    }) : [];
    const balance = moneyToCents(wallet?.balance ?? '0.00');
    const lockedBalance = moneyToCents(wallet?.lockedBalance ?? '0.00');
    return {
      providerId: provider.id,
      balance: centsToMoney(balance),
      lockedBalance: centsToMoney(lockedBalance),
      availableBalance: centsToMoney(balance - lockedBalance),
      currency: 'VND',
      demoOnly: true,
      transactions: transactions.map((tx) => ({
        id: tx.id,
        type: tx.type,
        amount: tx.amount,
        orderId: tx.orderId,
        withdrawalId: tx.withdrawalId,
        createdAt: tx.createdAt,
      })),
    };
  }
}
