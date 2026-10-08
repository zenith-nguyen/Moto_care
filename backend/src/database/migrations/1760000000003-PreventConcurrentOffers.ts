import { MigrationInterface, QueryRunner } from 'typeorm';

export class PreventConcurrentOffers1760000000003 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_order_offers_one_pending_per_order"
      ON "order_offers" ("order_id") WHERE "status" = 'PENDING'
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_order_offers_one_pending_per_provider"
      ON "order_offers" ("provider_id") WHERE "status" = 'PENDING'
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_orders_one_active_per_provider"
      ON "orders" ("provider_id")
      WHERE "provider_id" IS NOT NULL
        AND "status" IN ('ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'AWAITING_PAYMENT', 'PAID')
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX "UQ_orders_one_active_per_provider"');
    await queryRunner.query('DROP INDEX "UQ_order_offers_one_pending_per_provider"');
    await queryRunner.query('DROP INDEX "UQ_order_offers_one_pending_per_order"');
  }
}
