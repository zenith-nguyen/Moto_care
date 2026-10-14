import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { jest } from '@jest/globals';
import { Roles } from '../src/common/decorators/roles.decorator';
import { UserRole } from '../src/common/enums/user-role.enum';
import { RolesGuard } from '../src/common/guards/roles.guard';

describe('RolesGuard', () => {
  it('blocks an authenticated user with the wrong role', () => {
    const reflector = {
      getAllAndOverride: jest.fn().mockReturnValue([UserRole.ADMIN]),
    } as unknown as Reflector;
    const context = {
      getHandler: () => Roles,
      getClass: () => RolesGuard,
      switchToHttp: () => ({ getRequest: () => ({ user: { sub: 1, role: UserRole.CUSTOMER } }) }),
    } as unknown as ExecutionContext;

    expect(new RolesGuard(reflector).canActivate(context)).toBe(false);
  });
});
