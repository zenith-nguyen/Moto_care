import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddWithdrawalReservations1760000000011 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "wallets" ADD "locked_balance" numeric(14,2) NOT NULL DEFAULT 0`);
    await queryRunner.query(`ALTER TABLE "wallets" ADD CONSTRAINT "CHK_wallets_locked_balance_non_negative" CHECK ("locked_balance" >= 0)`);
    await queryRunner.query(`ALTER TABLE "wallets" ADD CONSTRAINT "CHK_wallets_locked_not_above_balance" CHECK ("locked_balance" <= "balance")`);
    await queryRunner.query(`ALTER TABLE "withdrawal_requests" DROP CONSTRAINT "CHK_withdrawal_requests_amount_non_negative"`);
    await queryRunner.query(`ALTER TABLE "withdrawal_requests" ADD CONSTRAINT "CHK_withdrawal_requests_amount_positive" CHECK ("amount" > 0)`);
    await queryRunner.query(`ALTER TABLE "withdrawal_requests" ADD "decision_reason" text`);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_withdrawal_requests_one_pending_per_provider"
      ON "withdrawal_requests" ("provider_id") WHERE "status" = 'PENDING'
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_wallet_transactions_one_debit_per_withdrawal"
      ON "wallet_transactions" ("withdrawal_id")
      WHERE "withdrawal_id" IS NOT NULL AND "type" = 'DEBIT'
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "UQ_wallet_transactions_one_debit_per_withdrawal"`);
    await queryRunner.query(`DROP INDEX "UQ_withdrawal_requests_one_pending_per_provider"`);
    await queryRunner.query(`ALTER TABLE "withdrawal_requests" DROP COLUMN "decision_reason"`);
    await queryRunner.query(`ALTER TABLE "withdrawal_requests" DROP CONSTRAINT "CHK_withdrawal_requests_amount_positive"`);
    await queryRunner.query(`ALTER TABLE "withdrawal_requests" ADD CONSTRAINT "CHK_withdrawal_requests_amount_non_negative" CHECK ("amount" >= 0)`);
    await queryRunner.query(`ALTER TABLE "wallets" DROP CONSTRAINT "CHK_wallets_locked_not_above_balance"`);
    await queryRunner.query(`ALTER TABLE "wallets" DROP CONSTRAINT "CHK_wallets_locked_balance_non_negative"`);
    await queryRunner.query(`ALTER TABLE "wallets" DROP COLUMN "locked_balance"`);
  }
}
