import { Body, Controller, Get, Param, ParseIntPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { CreateMessageDto } from './dto/create-message.dto';
import { MessagesService } from './messages.service';

@ApiTags('messages')
@ApiBearerAuth()
@Roles(UserRole.CUSTOMER, UserRole.PROVIDER)
@Controller('orders/:orderId/messages')
export class MessagesController {
  constructor(private readonly messages: MessagesService) {}

  @Get()
  @ApiOkResponse({ description: 'Latest 100 messages for an active order participant' })
  list(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload) {
    return this.messages.list(orderId, user.sub);
  }

  @Post()
  @ApiCreatedResponse({ description: 'Message saved and broadcast to order room' })
  create(
    @Param('orderId', ParseIntPipe) orderId: number,
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateMessageDto,
  ) {
    return this.messages.create(orderId, user.sub, dto.content);
  }
}
