import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({ description: 'Registered email address or phone number' })
  @IsString()
  @MinLength(3)
  @MaxLength(255)
  identity!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password!: string;
}
