import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddSepayWebhookAudit1760000000012 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "sepay_webhook_events" (
        "id" SERIAL NOT NULL,
        "external_transaction_id" character varying(120) NOT NULL,
        "payment_id" integer,
        "payment_code" character varying(40),
        "reference_code" character varying(120),
        "amount" numeric(14,2) NOT NULL,
        "payload_sha256" character(64) NOT NULL,
        "outcome" character varying(40) NOT NULL,
        "received_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_sepay_webhook_events_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_sepay_webhook_events_transaction" UNIQUE ("external_transaction_id"),
        CONSTRAINT "CHK_sepay_webhook_events_amount_positive" CHECK ("amount" > 0),
        CONSTRAINT "FK_sepay_webhook_events_payment" FOREIGN KEY ("payment_id") REFERENCES "payments"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_sepay_webhook_events_outcome_received" ON "sepay_webhook_events" ("outcome", "received_at")`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "sepay_webhook_events"`);
  }
}
