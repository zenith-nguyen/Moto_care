import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiAcceptedResponse, ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Public } from '../common/decorators/public.decorator';
import { RateLimit } from '../common/decorators/rate-limit.decorator';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { PasswordRecoveryService } from './password-recovery.service';

@ApiTags('auth')
@Public()
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly passwordRecovery: PasswordRecoveryService,
  ) {}

  @Post('register')
  @RateLimit(5, 60_000)
  @ApiCreatedResponse({ description: 'Account registered successfully' })
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @RateLimit(10, 60_000)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Authenticated successfully' })
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('password/forgot')
  @RateLimit(3, 60_000)
  @HttpCode(HttpStatus.ACCEPTED)
  @ApiAcceptedResponse({ description: 'Generic response; sends a six-digit code when the email is registered' })
  forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.passwordRecovery.forgot(dto.email);
  }

  @Post('password/reset')
  @RateLimit(10, 60_000)
  @HttpCode(HttpStatus.OK)
  @ApiOkResponse({ description: 'Password changed and all previous JWTs invalidated' })
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.passwordRecovery.reset(dto.email, dto.code, dto.newPassword);
  }
}
