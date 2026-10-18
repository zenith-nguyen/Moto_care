import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddCustomerProfileDetails1760000000018 implements MigrationInterface {
  name = 'AddCustomerProfileDetails1760000000018';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        ADD COLUMN "emergency_contact_name" varchar(80),
        ADD COLUMN "emergency_contact_phone" varchar(20),
        ADD COLUMN "medical_note" varchar(240),
        ADD COLUMN "home_address" varchar(240),
        ADD COLUMN "work_address" varchar(240)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
        DROP COLUMN "work_address",
        DROP COLUMN "home_address",
        DROP COLUMN "medical_note",
        DROP COLUMN "emergency_contact_phone",
        DROP COLUMN "emergency_contact_name"
    `);
  }
}
