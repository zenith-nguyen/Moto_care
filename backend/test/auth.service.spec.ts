import { BadRequestException, ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { jest } from '@jest/globals';
import * as argon2 from 'argon2';
import { AuthService } from '../src/auth/auth.service';
import { UserRole } from '../src/common/enums/user-role.enum';
import { UserStatus } from '../src/common/enums/user-status.enum';
import { CreateUserInput, UsersService } from '../src/users/users.service';

describe('AuthService', () => {
  const usersService = {
    create: jest.fn(),
    findByIdentityWithPassword: jest.fn(),
    recordFailedLogin: jest.fn(),
    clearLoginFailures: jest.fn(),
  };
  const jwtService = { sign: jest.fn().mockReturnValue('signed-access-token') };
  let authService: AuthService;

  beforeEach(async () => {
    jest.resetAllMocks();
    jwtService.sign.mockReturnValue('signed-access-token');
    const moduleRef = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: usersService },
        { provide: JwtService, useValue: jwtService },
      ],
    }).compile();
    authService = moduleRef.get(AuthService);
  });

  it('registers a provider in pending approval status', async () => {
    usersService.create.mockImplementation(async (input: CreateUserInput) => ({ id: 7, ...input }));

    const result = await authService.register({
      name: 'Provider One',
      email: 'provider@example.com',
      password: 'safe-password',
      role: UserRole.PROVIDER,
    });

    expect(usersService.create).toHaveBeenCalledWith(
      expect.objectContaining({
        email: 'provider@example.com',
        role: UserRole.PROVIDER,
        status: UserStatus.PENDING_APPROVAL,
      }),
    );
    expect(result.accessToken).toBe('signed-access-token');
    expect(result.user.status).toBe(UserStatus.PENDING_APPROVAL);
  });

  it('returns the duplicate-account error from UsersService', async () => {
    usersService.create.mockRejectedValue(new ConflictException('Email or phone number is already registered'));

    await expect(
      authService.register({ name: 'Customer', phone: '0901234567', password: 'safe-password' }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('rejects an invalid password', async () => {
    const passwordHash = await argon2.hash('correct-password');
    usersService.findByIdentityWithPassword.mockResolvedValue({
      id: 1,
      role: UserRole.CUSTOMER,
      status: UserStatus.ACTIVE,
      passwordHash,
    });

    await expect(authService.login({ identity: 'customer@example.com', password: 'wrong-password' })).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(usersService.recordFailedLogin).toHaveBeenCalledWith(1);
  });

  it('rejects login while the account is temporarily locked', async () => {
    usersService.findByIdentityWithPassword.mockResolvedValue({
      id: 1,
      role: UserRole.CUSTOMER,
      status: UserStatus.ACTIVE,
      lockedUntil: new Date(Date.now() + 60_000),
    });
    await expect(authService.login({ identity: 'customer@example.com', password: 'safe-password' }))
      .rejects.toBeInstanceOf(UnauthorizedException);
    expect(usersService.recordFailedLogin).not.toHaveBeenCalled();
  });

  it('rejects a registration without an email or phone number', async () => {
    await expect(authService.register({ name: 'Customer', password: 'safe-password' })).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });
});
