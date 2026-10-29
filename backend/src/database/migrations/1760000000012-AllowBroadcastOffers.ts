import { MigrationInterface, QueryRunner } from 'typeorm';

/** Allow one order to be offered to several eligible providers at once. */
export class AllowBroadcastOffers1760000000012 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX IF EXISTS "UQ_order_offers_one_pending_per_order"');
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_order_offers_one_pending_per_order"
      ON "order_offers" ("order_id") WHERE "status" = 'PENDING'
    `);
  }
}
