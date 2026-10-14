import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, QueryFailedError, Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Provider } from '../providers/provider.entity';
import { UpdateProfileDto } from './dto/update-profile.dto';
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

  async updateProfile(userId: number, dto: UpdateProfileDto) {
    const user = await this.usersRepository.findOneBy({ id: userId });
    if (!user) throw new NotFoundException('User not found');
    if (dto.name !== undefined) user.name = dto.name;
    if (dto.phone !== undefined) {
      if (dto.phone === null && !user.email) throw new ConflictException('An account must keep an email or phone number');
      user.phone = dto.phone;
    }
    try {
      return this.presentProfile(await this.usersRepository.save(user));
    } catch (error) {
      if (error instanceof QueryFailedError && (error as QueryFailedError & { code?: string }).code === '23505') {
        throw new ConflictException('Phone number is already registered');
      }
      throw error;
    }
  }

  presentProfile(user: User | null) {
    if (!user) throw new NotFoundException('User not found');
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      status: user.status,
    };
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
