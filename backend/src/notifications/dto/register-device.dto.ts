import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsString, Length, MaxLength } from 'class-validator';
import { DevicePlatform } from '../device-platform.enum';

export class RegisterDeviceDto {
  @ApiProperty({ description: 'Stable random ID generated once per app installation', example: '61c495b0-05c8-4d39-9249-5b3588ed03e2' })
  @IsString()
  @Length(16, 128)
  installationId!: string;

  @ApiProperty({ description: 'Firebase Cloud Messaging registration token; never log this value' })
  @IsString()
  @Length(20, 512)
  fcmToken!: string;

  @ApiProperty({ enum: DevicePlatform, example: DevicePlatform.ANDROID })
  @IsEnum(DevicePlatform)
  platform!: DevicePlatform;
}

export class UnregisterDeviceDto {
  @ApiProperty({ description: 'Installation ID previously registered by this signed-in user' })
  @IsString()
  @MaxLength(128)
  installationId!: string;
}
