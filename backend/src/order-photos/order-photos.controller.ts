import {
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Res,
  StreamableFile,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiTags,
} from '@nestjs/swagger';
import type { Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RateLimit } from '../common/decorators/rate-limit.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { OrderPhotosService } from './order-photos.service';

@ApiTags('orders')
@ApiBearerAuth()
@Roles(UserRole.CUSTOMER, UserRole.PROVIDER)
@Controller('orders/:orderId/photos')
export class OrderPhotosController {
  constructor(private readonly photos: OrderPhotosService) {}

  @Get()
  @ApiOkResponse({
    description: 'Incident photo metadata for an order participant',
  })
  list(
    @Param('orderId', ParseIntPipe) orderId: number,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.photos.list(orderId, user.sub);
  }

  @Post()
  @RateLimit(10, 60_000)
  @UseInterceptors(FileInterceptor('image'))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['image'],
      properties: {
        image: {
          type: 'string',
          format: 'binary',
          description: 'JPEG, PNG or WebP; maximum 5 MiB',
        },
      },
    },
  })
  @ApiCreatedResponse({ description: 'Incident photo stored for the order' })
  add(
    @Param('orderId', ParseIntPipe) orderId: number,
    @CurrentUser() user: JwtPayload,
    @UploadedFile() image: Express.Multer.File,
  ) {
    return this.photos.add(orderId, user.sub, image);
  }

  @Get(':photoId/image')
  @ApiOkResponse({ description: 'Protected incident photo for a participant' })
  async image(
    @Param('orderId', ParseIntPipe) orderId: number,
    @Param('photoId', ParseIntPipe) photoId: number,
    @CurrentUser() user: JwtPayload,
    @Res({ passthrough: true }) response: Response,
  ): Promise<StreamableFile> {
    const photo = await this.photos.image(orderId, photoId, user.sub);
    response.set({
      'Content-Type': photo.mimeType,
      'Content-Length': photo.sizeBytes.toString(),
      'Cache-Control': 'private, max-age=3600',
      'X-Content-Type-Options': 'nosniff',
    });
    return new StreamableFile(photo.data);
  }
}
