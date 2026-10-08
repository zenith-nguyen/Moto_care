import { MigrationInterface, QueryRunner } from 'typeorm';

export class ExpandProviderActiveOrderGuard1760000000010 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "UQ_orders_one_active_per_provider"`);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_orders_one_active_per_provider"
      ON "orders" ("provider_id")
      WHERE "provider_id" IS NOT NULL
        AND "status" IN ('ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'AWAITING_PRICE_APPROVAL', 'PRICE_DISPUTED', 'AWAITING_PAYMENT', 'PAID')
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "UQ_orders_one_active_per_provider"`);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_orders_one_active_per_provider"
      ON "orders" ("provider_id")
      WHERE "provider_id" IS NOT NULL
        AND "status" IN ('ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'AWAITING_PAYMENT', 'PAID')
    `);
  }
}
