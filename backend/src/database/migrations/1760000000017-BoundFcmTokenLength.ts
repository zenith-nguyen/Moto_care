import { MigrationInterface, QueryRunner } from 'typeorm';

export class BoundFcmTokenLength1760000000017 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DO $$
      BEGIN
        IF EXISTS (SELECT 1 FROM user_devices WHERE length(fcm_token) > 512) THEN
          RAISE EXCEPTION 'Cannot reduce user_devices.fcm_token: an existing token exceeds 512 characters';
        END IF;
      END
      $$
    `);
    await queryRunner.query(`ALTER TABLE "user_devices" ALTER COLUMN "fcm_token" TYPE varchar(512)`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "user_devices" ALTER COLUMN "fcm_token" TYPE varchar(4096)`);
  }
}
