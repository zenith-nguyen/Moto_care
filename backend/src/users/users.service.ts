import { ConflictException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, QueryFailedError, Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Provider } from '../providers/provider.entity';
import { User } from './user.entity';

export interface CreateUserInput {
  name: string;
  email: string | null;
  phone: string | null;
  passwordHash: string;
  role: UserRole;
  status: UserStatus;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private readonly usersRepository: Repository<User>,
    private readonly dataSource: DataSource,
  ) {}

  async create(input: CreateUserInput): Promise<User> {
    try {
      if (input.role === UserRole.PROVIDER) {
        return await this.dataSource.transaction(async (manager) => {
          const user = await manager.getRepository(User).save(manager.getRepository(User).create(input));
          await manager.getRepository(Provider).save(manager.getRepository(Provider).create({ userId: user.id }));
          return user;
        });
      }
      return await this.usersRepository.save(this.usersRepository.create(input));
    } catch (error) {
      if (error instanceof QueryFailedError && (error as QueryFailedError & { code?: string }).code === '23505') {
        throw new ConflictException('Email or phone number is already registered');
      }
      throw error;
    }
  }

  findById(id: number): Promise<User | null> {
    return this.usersRepository.findOneBy({ id });
  }

  findByIdentityWithPassword(identity: string): Promise<User | null> {
    return this.usersRepository
      .createQueryBuilder('user')
      .addSelect('user.passwordHash')
      .where('LOWER(user.email) = LOWER(:identity)', { identity })
      .orWhere('user.phone = :identity', { identity })
      .getOne();
  }

  async recordFailedLogin(userId: number): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      const user = await manager.getRepository(User).findOne({
        where: { id: userId }, lock: { mode: 'pessimistic_write' },
      });
      if (!user || (user.lockedUntil && user.lockedUntil > new Date())) return;
      const attempts = user.failedLoginAttempts + 1;
      await manager.getRepository(User).update(user.id, attempts >= 5
        ? { failedLoginAttempts: 0, lockedUntil: new Date(Date.now() + 15 * 60_000) }
        : { failedLoginAttempts: attempts });
    });
  }

  async clearLoginFailures(userId: number): Promise<void> {
    await this.usersRepository.update(userId, { failedLoginAttempts: 0, lockedUntil: null });
  }
}
