import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  ParseIntPipe,
  Post,
  RawBodyRequest,
  Req,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { BankTransferInstructionsDto, SepayWebhookDto } from './dto/sepay.dto';
import { SepayPaymentsService } from './sepay-payments.service';

@ApiTags('payments')
@Controller('payments')
export class SepayPaymentsController {
  constructor(private readonly payments: SepayPaymentsService) {}

  @Get('orders/:orderId/instructions')
  @ApiBearerAuth()
  @Roles(UserRole.CUSTOMER)
  @ApiOkResponse({ type: BankTransferInstructionsDto })
  @ApiOperation({
    summary: 'Get SePay Test mode bank-transfer and VietQR instructions for an unpaid order',
  })
  instructions(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload) {
    return this.payments.instructions(orderId, user.sub);
  }

  @Post('webhooks/sepay')
  @Public()
  @HttpCode(HttpStatus.OK)
  @ApiHeader({ name: 'X-SePay-Timestamp', required: true })
  @ApiHeader({
    name: 'X-SePay-Signature',
    required: true,
    example: 'sha256=<hex>',
  })
  @ApiOkResponse({ schema: { example: { success: true } } })
  @ApiOperation({
    summary: 'Receive an HMAC-authenticated SePay Test mode transaction webhook',
  })
  webhook(
    @Body() payload: SepayWebhookDto,
    @Req() request: RawBodyRequest<Request>,
    @Headers('x-sepay-timestamp') timestamp?: string,
    @Headers('x-sepay-signature') signature?: string,
  ) {
    return this.payments.receive(payload, request.rawBody, timestamp, signature);
  }
}
