import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddFinalPriceAdjustments1760000000009 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TYPE "order_status_enum" ADD VALUE IF NOT EXISTS 'AWAITING_PRICE_APPROVAL'`);
    await queryRunner.query(`ALTER TYPE "order_status_enum" ADD VALUE IF NOT EXISTS 'PRICE_DISPUTED'`);
    await queryRunner.query(`CREATE TYPE "price_proposal_status_enum" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'DISPUTED', 'RESOLVED_APPROVED', 'RESOLVED_REJECTED')`);
    await queryRunner.query(`CREATE TYPE "payment_adjustment_type_enum" AS ENUM ('CHARGE', 'REFUND')`);
    await queryRunner.query(`CREATE TYPE "payment_adjustment_status_enum" AS ENUM ('PENDING', 'SETTLED')`);
    await queryRunner.query(`ALTER TABLE "orders" ADD "discount_amount" numeric(12,2) NOT NULL DEFAULT 0`);
    await queryRunner.query(`ALTER TABLE "orders" ADD CONSTRAINT "CHK_orders_discount_amount_non_negative" CHECK ("discount_amount" >= 0)`);
    await queryRunner.query(`
      CREATE TABLE "order_price_proposals" (
        "id" SERIAL NOT NULL,
        "order_id" integer NOT NULL,
        "provider_id" integer NOT NULL,
        "proposed_final_price" numeric(12,2) NOT NULL,
        "reason" text NOT NULL,
        "status" "price_proposal_status_enum" NOT NULL DEFAULT 'PENDING',
        "customer_reason" text,
        "dispute_reason" text,
        "resolution_reason" text,
        "decided_by" integer,
        "decided_at" timestamptz,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "PK_order_price_proposals_id" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_order_price_proposals_price_non_negative" CHECK ("proposed_final_price" >= 0),
        CONSTRAINT "FK_order_price_proposals_order" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_order_price_proposals_provider" FOREIGN KEY ("provider_id") REFERENCES "providers"("id") ON DELETE RESTRICT,
        CONSTRAINT "FK_order_price_proposals_decided_by" FOREIGN KEY ("decided_by") REFERENCES "users"("id") ON DELETE SET NULL
      )
    `);
    await queryRunner.query(`CREATE INDEX "IDX_order_price_proposals_order_status" ON "order_price_proposals" ("order_id", "status")`);
    await queryRunner.query(`CREATE UNIQUE INDEX "UQ_order_price_proposals_one_pending" ON "order_price_proposals" ("order_id") WHERE "status" = 'PENDING'`);
    await queryRunner.query(`
      CREATE TABLE "payment_adjustments" (
        "id" SERIAL NOT NULL,
        "order_id" integer NOT NULL,
        "payment_id" integer NOT NULL,
        "type" "payment_adjustment_type_enum" NOT NULL,
        "amount" numeric(12,2) NOT NULL,
        "status" "payment_adjustment_status_enum" NOT NULL DEFAULT 'PENDING',
        "is_demo" boolean NOT NULL DEFAULT false,
        "settled_at" timestamptz,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "PK_payment_adjustments_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_payment_adjustments_order" UNIQUE ("order_id"),
        CONSTRAINT "CHK_payment_adjustments_amount_positive" CHECK ("amount" > 0),
        CONSTRAINT "FK_payment_adjustments_order" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT,
        CONSTRAINT "FK_payment_adjustments_payment" FOREIGN KEY ("payment_id") REFERENCES "payments"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(`CREATE INDEX "IDX_payment_adjustments_status_type" ON "payment_adjustments" ("status", "type")`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "payment_adjustments"`);
    await queryRunner.query(`DROP TABLE "order_price_proposals"`);
    await queryRunner.query(`ALTER TABLE "orders" DROP CONSTRAINT "CHK_orders_discount_amount_non_negative"`);
    await queryRunner.query(`ALTER TABLE "orders" DROP COLUMN "discount_amount"`);
    await queryRunner.query(`DROP TYPE "payment_adjustment_status_enum"`);
    await queryRunner.query(`DROP TYPE "payment_adjustment_type_enum"`);
    await queryRunner.query(`DROP TYPE "price_proposal_status_enum"`);
  }
}
