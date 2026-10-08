import { Body, Controller, Get, Param, ParseIntPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { JwtPayload } from '../common/interfaces/jwt-payload.interface';
import { CreateReviewDto } from './dto/create-review.dto';
import { ReviewsService } from './reviews.service';

@ApiTags('reviews')
@ApiBearerAuth()
@Roles(UserRole.CUSTOMER, UserRole.PROVIDER)
@Controller('orders/:orderId/reviews')
export class ReviewsController {
  constructor(private readonly reviews: ReviewsService) {}

  @Get()
  @ApiOkResponse({ description: 'Reviews by the two participants after completion' })
  list(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload) {
    return this.reviews.list(orderId, user.sub);
  }

  @Post()
  @ApiCreatedResponse({ description: 'One review per participant for a completed order' })
  create(@Param('orderId', ParseIntPipe) orderId: number, @CurrentUser() user: JwtPayload, @Body() dto: CreateReviewDto) {
    return this.reviews.create(orderId, user.sub, dto);
  }
}
