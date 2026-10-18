import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddWithdrawalPayoutReconciliation1760000000019 implements MigrationInterface {
  name = 'AddWithdrawalPayoutReconciliation1760000000019';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TYPE "withdrawal_payouts_status_enum" AS ENUM (
        'AWAITING_TRANSFER', 'MANUAL_REVIEW', 'RECONCILED'
      )
    `);
    await queryRunner.query(`
      CREATE TABLE "withdrawal_payouts" (
        "id" SERIAL NOT NULL,
        "withdrawal_id" integer NOT NULL,
        "payout_code" character varying(40) NOT NULL,
        "expected_amount" numeric(14,2) NOT NULL,
        "status" "withdrawal_payouts_status_enum" NOT NULL DEFAULT 'AWAITING_TRANSFER',
        "external_transaction_id" character varying(120),
        "external_reference_code" character varying(120),
        "observed_amount" numeric(14,2),
        "review_reason" character varying(500),
        "reconciled_by" integer,
        "reconciled_at" TIMESTAMP WITH TIME ZONE,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_withdrawal_payouts_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_withdrawal_payouts_withdrawal" UNIQUE ("withdrawal_id"),
        CONSTRAINT "UQ_withdrawal_payouts_code" UNIQUE ("payout_code"),
        CONSTRAINT "UQ_withdrawal_payouts_transaction" UNIQUE ("external_transaction_id"),
        CONSTRAINT "CHK_withdrawal_payouts_expected_amount_positive" CHECK ("expected_amount" > 0),
        CONSTRAINT "CHK_withdrawal_payouts_observed_amount_positive" CHECK ("observed_amount" IS NULL OR "observed_amount" > 0),
        CONSTRAINT "FK_withdrawal_payouts_withdrawal" FOREIGN KEY ("withdrawal_id") REFERENCES "withdrawal_requests"("id") ON DELETE RESTRICT,
        CONSTRAINT "FK_withdrawal_payouts_reconciled_by" FOREIGN KEY ("reconciled_by") REFERENCES "users"("id") ON DELETE SET NULL
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_withdrawal_payouts_status_created" ON "withdrawal_payouts" ("status", "created_at")`,
    );
    await queryRunner.query(`
      CREATE TABLE "sepay_payout_webhook_events" (
        "id" SERIAL NOT NULL,
        "external_transaction_id" character varying(120) NOT NULL,
        "payout_id" integer,
        "payout_code" character varying(40),
        "reference_code" character varying(120),
        "amount" numeric(14,2) NOT NULL,
        "payload_sha256" character(64) NOT NULL,
        "outcome" character varying(40) NOT NULL,
        "received_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_sepay_payout_webhook_events_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_sepay_payout_webhook_events_transaction" UNIQUE ("external_transaction_id"),
        CONSTRAINT "CHK_sepay_payout_webhook_events_amount_positive" CHECK ("amount" > 0),
        CONSTRAINT "FK_sepay_payout_webhook_events_payout" FOREIGN KEY ("payout_id") REFERENCES "withdrawal_payouts"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_sepay_payout_webhook_events_outcome_received" ON "sepay_payout_webhook_events" ("outcome", "received_at")`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "sepay_payout_webhook_events"`);
    await queryRunner.query(`DROP TABLE "withdrawal_payouts"`);
    await queryRunner.query(`DROP TYPE "withdrawal_payouts_status_enum"`);
  }
}
