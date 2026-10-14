import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPasswordRecovery1760000000007 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE "users" ADD "auth_version" integer NOT NULL DEFAULT 0');
    await queryRunner.query('ALTER TABLE "users" ADD "failed_login_attempts" integer NOT NULL DEFAULT 0');
    await queryRunner.query('ALTER TABLE "users" ADD "locked_until" timestamptz');
    await queryRunner.query(`
      CREATE TABLE "password_reset_codes" (
        "id" SERIAL NOT NULL,
        "user_id" integer NOT NULL,
        "code_hash" character(64) NOT NULL,
        "attempt_count" smallint NOT NULL DEFAULT 0,
        "expires_at" timestamptz NOT NULL,
        "used_at" timestamptz,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "PK_password_reset_codes_id" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_password_reset_attempt_count" CHECK ("attempt_count" BETWEEN 0 AND 5),
        CONSTRAINT "FK_password_reset_codes_user" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      'CREATE INDEX "IDX_password_reset_codes_user_created" ON "password_reset_codes" ("user_id", "created_at")',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE "password_reset_codes"');
    await queryRunner.query('ALTER TABLE "users" DROP COLUMN "locked_until"');
    await queryRunner.query('ALTER TABLE "users" DROP COLUMN "failed_login_attempts"');
    await queryRunner.query('ALTER TABLE "users" DROP COLUMN "auth_version"');
  }
}
