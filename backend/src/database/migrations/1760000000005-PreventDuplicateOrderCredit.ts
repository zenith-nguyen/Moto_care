import { MigrationInterface, QueryRunner } from 'typeorm';

export class PreventDuplicateOrderCredit1760000000005 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_wallet_transactions_one_credit_per_order"
      ON "wallet_transactions" ("order_id")
      WHERE "type" = 'CREDIT' AND "order_id" IS NOT NULL
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX "UQ_wallet_transactions_one_credit_per_order"');
  }
}
