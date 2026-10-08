import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateUsers1760000000001 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE TYPE "user_role_enum" AS ENUM ('CUSTOMER', 'PROVIDER', 'ADMIN')`);
    await queryRunner.query(
      `CREATE TYPE "user_status_enum" AS ENUM ('ACTIVE', 'PENDING_APPROVAL', 'SUSPENDED')`,
    );
    await queryRunner.query(`
      CREATE TABLE "users" (
        "id" SERIAL NOT NULL,
        "name" character varying(100) NOT NULL,
        "email" character varying(255),
        "phone" character varying(20),
        "password_hash" character varying(255) NOT NULL,
        "role" "user_role_enum" NOT NULL DEFAULT 'CUSTOMER',
        "status" "user_status_enum" NOT NULL DEFAULT 'ACTIVE',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_users_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_users_email" UNIQUE ("email"),
        CONSTRAINT "UQ_users_phone" UNIQUE ("phone"),
        CONSTRAINT "CHK_users_identity" CHECK ("email" IS NOT NULL OR "phone" IS NOT NULL)
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE "users"');
    await queryRunner.query('DROP TYPE "user_status_enum"');
    await queryRunner.query('DROP TYPE "user_role_enum"');
  }
}
