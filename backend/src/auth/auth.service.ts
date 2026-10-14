import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

const dummyPasswordHash = argon2.hash('motocare-login-timing-placeholder');

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email?.trim().toLowerCase() || null;
    const phone = dto.phone?.trim() || null;
    if (!email && !phone) {
      throw new BadRequestException('Provide an email address or phone number');
    }

    const role = dto.role ?? UserRole.CUSTOMER;
    if (role === UserRole.ADMIN) {
      throw new BadRequestException('Administrator accounts cannot be self-registered');
    }

    const user = await this.usersService.create({
      name: dto.name.trim(),
      email,
      phone,
      passwordHash: await argon2.hash(dto.password),
      role,
      status: role === UserRole.PROVIDER ? UserStatus.PENDING_APPROVAL : UserStatus.ACTIVE,
    });
    return this.createAuthResponse(user);
  }

  async login(dto: LoginDto) {
    const identity = dto.identity.trim();
    const user = await this.usersService.findByIdentityWithPassword(identity);
    if (user?.lockedUntil && user.lockedUntil > new Date()) {
      throw new UnauthorizedException('Invalid credentials or account temporarily locked');
    }
    const passwordMatches = await argon2.verify(user?.passwordHash ?? await dummyPasswordHash, dto.password);
    if (!user || !passwordMatches) {
      if (user) await this.usersService.recordFailedLogin(user.id);
      throw new UnauthorizedException('Invalid credentials');
    }
    if (user.status === UserStatus.SUSPENDED) {
      throw new UnauthorizedException('Account is suspended');
    }
    await this.usersService.clearLoginFailures(user.id);
    return this.createAuthResponse(user);
  }

  private createAuthResponse(user: User) {
    return {
      accessToken: this.jwtService.sign({ sub: user.id, role: user.role, ver: user.authVersion }),
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        status: user.status,
      },
    };
  }
}
