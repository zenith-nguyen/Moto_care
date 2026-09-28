import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

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
    if (!user || !(await argon2.verify(user.passwordHash, dto.password))) {
      throw new UnauthorizedException('Invalid credentials');
    }
    if (user.status === UserStatus.SUSPENDED) {
      throw new UnauthorizedException('Account is suspended');
    }
    return this.createAuthResponse(user);
  }

  private createAuthResponse(user: User) {
    return {
      accessToken: this.jwtService.sign({ sub: user.id, role: user.role }),
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
