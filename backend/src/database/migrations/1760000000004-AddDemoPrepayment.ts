import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddDemoPrepayment1760000000004 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Postgres enum values may not be used until this transaction commits.
    // Services explicitly set the new status; the existing SQL default stays unchanged.
    await queryRunner.query(`ALTER TYPE "order_status_enum" ADD VALUE IF NOT EXISTS 'AWAITING_PREPAYMENT'`);
    await queryRunner.query(`ALTER TYPE "order_status_enum" ADD VALUE IF NOT EXISTS 'REFUND_PENDING'`);
    await queryRunner.query(`ALTER TYPE "order_status_enum" ADD VALUE IF NOT EXISTS 'REFUNDED'`);
    await queryRunner.query(`ALTER TYPE "payment_status_enum" ADD VALUE IF NOT EXISTS 'REFUND_PENDING'`);
    await queryRunner.query(`ALTER TYPE "payment_status_enum" ADD VALUE IF NOT EXISTS 'REFUNDED'`);
    await queryRunner.query('ALTER TABLE "payments" ADD COLUMN "is_demo" boolean NOT NULL DEFAULT false');
    await queryRunner.query('ALTER TABLE "payments" ADD COLUMN "refunded_at" timestamptz');
  }

  public async down(): Promise<void> {
    throw new Error('Enum additions cannot be safely removed; restore a database backup to revert this migration');
  }
}
