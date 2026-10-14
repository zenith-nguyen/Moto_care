import {
  Body, Controller, Get, Param, ParseIntPipe, Post, Res, StreamableFile, UploadedFile, UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RateLimit } from '../common/decorators/rate-limit.decorator';
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
  @ApiOkResponse({ description: 'Latest 100 messages for an order participant, including closed orders' })
  list(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload) {
    return this.messages.list(orderId, user.sub);
  }

  @Post()
  @RateLimit(20, 60_000)
  @UseInterceptors(FileInterceptor('image'))
  @ApiConsumes('application/json', 'multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: {
    content: { type: 'string', maxLength: 2000, example: 'I am at the gate.' },
    image: { type: 'string', format: 'binary', description: 'JPEG, PNG or WebP; maximum 5 MiB' },
  } } })
  @ApiCreatedResponse({ description: 'Text/image message saved and broadcast to order room' })
  create(
    @Param('orderId', ParseIntPipe) orderId: number,
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateMessageDto,
    @UploadedFile() image?: Express.Multer.File,
  ) {
    return this.messages.create(orderId, user.sub, dto.content, image);
  }

  @Get(':messageId/image')
  @ApiOkResponse({ description: 'Protected message image for an order participant' })
  async image(
    @Param('orderId', ParseIntPipe) orderId: number,
    @Param('messageId', ParseIntPipe) messageId: number,
    @CurrentUser() user: JwtPayload,
    @Res({ passthrough: true }) response: Response,
  ): Promise<StreamableFile> {
    const image = await this.messages.image(orderId, messageId, user.sub);
    response.set({
      'Content-Type': image.mimeType,
      'Content-Length': image.sizeBytes.toString(),
      'Cache-Control': 'private, max-age=3600',
      'X-Content-Type-Options': 'nosniff',
    });
    return new StreamableFile(image.data);
  }
}
