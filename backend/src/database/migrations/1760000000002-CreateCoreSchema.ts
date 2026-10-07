import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateCoreSchema1760000000002 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TYPE "approval_status_enum" AS ENUM ('PENDING', 'APPROVED', 'REJECTED')
    `);
    await queryRunner.query(`
      CREATE TYPE "order_status_enum" AS ENUM (
        'PENDING_MATCH', 'OFFERED', 'ACCEPTED', 'ARRIVED', 'IN_PROGRESS',
        'AWAITING_PAYMENT', 'PAID', 'COMPLETED', 'CANCELLED'
      )
    `);
    await queryRunner.query(`
      CREATE TYPE "offer_status_enum" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'EXPIRED')
    `);
    await queryRunner.query(`
      CREATE TYPE "payment_status_enum" AS ENUM ('PENDING', 'PAID', 'FAILED', 'CANCELLED')
    `);
    await queryRunner.query(`
      CREATE TYPE "withdrawal_status_enum" AS ENUM ('PENDING', 'APPROVED', 'REJECTED')
    `);
    await queryRunner.query(`
      CREATE TYPE "wallet_transaction_type_enum" AS ENUM ('CREDIT', 'DEBIT')
    `);

    await queryRunner.query(`
      CREATE TABLE "incident_types" (
        "id" SERIAL NOT NULL,
        "code" character varying(60) NOT NULL,
        "name" character varying(120) NOT NULL,
        "base_price" numeric(12,2) NOT NULL,
        "is_active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_incident_types_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_incident_types_code" UNIQUE ("code"),
        CONSTRAINT "CHK_incident_types_base_price_non_negative" CHECK ("base_price" >= 0)
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "providers" (
        "id" SERIAL NOT NULL,
        "user_id" integer NOT NULL,
        "is_online" boolean NOT NULL DEFAULT false,
        "approval_status" "approval_status_enum" NOT NULL DEFAULT 'PENDING',
        "current_location" geography(Point,4326),
        "last_seen_at" TIMESTAMP WITH TIME ZONE,
        "document_url" character varying(500),
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_providers_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_providers_user_id" UNIQUE ("user_id"),
        CONSTRAINT "FK_providers_user" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "orders" (
        "id" SERIAL NOT NULL,
        "code" character varying(30) NOT NULL,
        "customer_id" integer NOT NULL,
        "provider_id" integer,
        "incident_type_id" integer NOT NULL,
        "status" "order_status_enum" NOT NULL DEFAULT 'PENDING_MATCH',
        "customer_location" geography(Point,4326) NOT NULL,
        "estimated_price" numeric(12,2) NOT NULL,
        "extra_cost" numeric(12,2) NOT NULL DEFAULT 0,
        "final_price" numeric(12,2),
        "cancel_reason" text,
        "cancelled_by" integer,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_orders_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_orders_code" UNIQUE ("code"),
        CONSTRAINT "CHK_orders_estimated_price_non_negative" CHECK ("estimated_price" >= 0),
        CONSTRAINT "CHK_orders_extra_cost_non_negative" CHECK ("extra_cost" >= 0),
        CONSTRAINT "CHK_orders_final_price_non_negative" CHECK ("final_price" IS NULL OR "final_price" >= 0),
        CONSTRAINT "FK_orders_customer" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT,
        CONSTRAINT "FK_orders_provider" FOREIGN KEY ("provider_id") REFERENCES "providers"("id") ON DELETE SET NULL,
        CONSTRAINT "FK_orders_incident_type" FOREIGN KEY ("incident_type_id") REFERENCES "incident_types"("id") ON DELETE RESTRICT,
        CONSTRAINT "FK_orders_cancelled_by" FOREIGN KEY ("cancelled_by") REFERENCES "users"("id") ON DELETE SET NULL
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "order_offers" (
        "id" SERIAL NOT NULL,
        "order_id" integer NOT NULL,
        "provider_id" integer NOT NULL,
        "status" "offer_status_enum" NOT NULL DEFAULT 'PENDING',
        "offered_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "expires_at" TIMESTAMP WITH TIME ZONE NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_order_offers_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_order_offers_order_provider" UNIQUE ("order_id", "provider_id"),
        CONSTRAINT "FK_order_offers_order" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_order_offers_provider" FOREIGN KEY ("provider_id") REFERENCES "providers"("id") ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "messages" (
        "id" SERIAL NOT NULL,
        "order_id" integer NOT NULL,
        "sender_id" integer NOT NULL,
        "content" text NOT NULL,
        "image_url" character varying(500),
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_messages_id" PRIMARY KEY ("id"),
        CONSTRAINT "FK_messages_order" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_messages_sender" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE RESTRICT
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "reviews" (
        "id" SERIAL NOT NULL,
        "order_id" integer NOT NULL,
        "reviewer_id" integer NOT NULL,
        "reviewee_id" integer NOT NULL,
        "rating" smallint NOT NULL,
        "comment" text,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_reviews_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_reviews_order_reviewer" UNIQUE ("order_id", "reviewer_id"),
        CONSTRAINT "CHK_reviews_rating" CHECK ("rating" BETWEEN 1 AND 5),
        CONSTRAINT "FK_reviews_order" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_reviews_reviewer" FOREIGN KEY ("reviewer_id") REFERENCES "users"("id") ON DELETE RESTRICT,
        CONSTRAINT "FK_reviews_reviewee" FOREIGN KEY ("reviewee_id") REFERENCES "users"("id") ON DELETE RESTRICT
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "payments" (
        "id" SERIAL NOT NULL,
        "order_id" integer NOT NULL,
        "amount" numeric(12,2) NOT NULL,
        "sepay_transaction_id" character varying(120),
        "status" "payment_status_enum" NOT NULL DEFAULT 'PENDING',
        "paid_at" TIMESTAMP WITH TIME ZONE,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_payments_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_payments_sepay_transaction_id" UNIQUE ("sepay_transaction_id"),
        CONSTRAINT "CHK_payments_amount_non_negative" CHECK ("amount" >= 0),
        CONSTRAINT "FK_payments_order" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "wallets" (
        "id" SERIAL NOT NULL,
        "provider_id" integer NOT NULL,
        "balance" numeric(14,2) NOT NULL DEFAULT 0,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_wallets_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_wallets_provider_id" UNIQUE ("provider_id"),
        CONSTRAINT "CHK_wallets_balance_non_negative" CHECK ("balance" >= 0),
        CONSTRAINT "FK_wallets_provider" FOREIGN KEY ("provider_id") REFERENCES "providers"("id") ON DELETE RESTRICT
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "withdrawal_requests" (
        "id" SERIAL NOT NULL,
        "provider_id" integer NOT NULL,
        "amount" numeric(14,2) NOT NULL,
        "status" "withdrawal_status_enum" NOT NULL DEFAULT 'PENDING',
        "processed_by" integer,
        "processed_at" TIMESTAMP WITH TIME ZONE,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_withdrawal_requests_id" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_withdrawal_requests_amount_non_negative" CHECK ("amount" >= 0),
        CONSTRAINT "FK_withdrawal_requests_provider" FOREIGN KEY ("provider_id") REFERENCES "providers"("id") ON DELETE RESTRICT,
        CONSTRAINT "FK_withdrawal_requests_processed_by" FOREIGN KEY ("processed_by") REFERENCES "users"("id") ON DELETE SET NULL
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "wallet_transactions" (
        "id" SERIAL NOT NULL,
        "wallet_id" integer NOT NULL,
        "type" "wallet_transaction_type_enum" NOT NULL,
        "amount" numeric(14,2) NOT NULL,
        "order_id" integer,
        "withdrawal_id" integer,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_wallet_transactions_id" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_wallet_transactions_amount_non_negative" CHECK ("amount" >= 0),
        CONSTRAINT "FK_wallet_transactions_wallet" FOREIGN KEY ("wallet_id") REFERENCES "wallets"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_wallet_transactions_order" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE SET NULL,
        CONSTRAINT "FK_wallet_transactions_withdrawal" FOREIGN KEY ("withdrawal_id") REFERENCES "withdrawal_requests"("id") ON DELETE SET NULL
      )
    `);

    await queryRunner.query(`CREATE INDEX "IDX_providers_approval_online" ON "providers" ("approval_status", "is_online")`);
    await queryRunner.query(`CREATE INDEX "IDX_orders_status" ON "orders" ("status")`);
    await queryRunner.query(`CREATE INDEX "IDX_orders_customer_status" ON "orders" ("customer_id", "status")`);
    await queryRunner.query(`CREATE INDEX "IDX_orders_provider_status" ON "orders" ("provider_id", "status")`);
    await queryRunner.query(`CREATE INDEX "IDX_order_offers_order_status" ON "order_offers" ("order_id", "status")`);
    await queryRunner.query(`CREATE INDEX "IDX_order_offers_provider_status" ON "order_offers" ("provider_id", "status")`);
    await queryRunner.query(`CREATE INDEX "IDX_messages_order_created" ON "messages" ("order_id", "created_at")`);
    await queryRunner.query(`CREATE INDEX "IDX_reviews_reviewee_created" ON "reviews" ("reviewee_id", "created_at")`);
    await queryRunner.query(`CREATE INDEX "IDX_payments_order_status" ON "payments" ("order_id", "status")`);
    await queryRunner.query(`CREATE INDEX "IDX_wallet_transactions_wallet_created" ON "wallet_transactions" ("wallet_id", "created_at")`);
    await queryRunner.query(`CREATE INDEX "IDX_wallet_transactions_order" ON "wallet_transactions" ("order_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_wallet_transactions_withdrawal" ON "wallet_transactions" ("withdrawal_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_withdrawal_requests_provider_status" ON "withdrawal_requests" ("provider_id", "status")`);
    await queryRunner.query(`CREATE INDEX "IDX_withdrawal_requests_status_created" ON "withdrawal_requests" ("status", "created_at")`);
    await queryRunner.query(`CREATE INDEX "IDX_providers_current_location_gist" ON "providers" USING GIST ("current_location")`);
    await queryRunner.query(`CREATE INDEX "IDX_orders_customer_location_gist" ON "orders" USING GIST ("customer_location")`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE "wallet_transactions"');
    await queryRunner.query('DROP TABLE "withdrawal_requests"');
    await queryRunner.query('DROP TABLE "wallets"');
    await queryRunner.query('DROP TABLE "payments"');
    await queryRunner.query('DROP TABLE "reviews"');
    await queryRunner.query('DROP TABLE "messages"');
    await queryRunner.query('DROP TABLE "order_offers"');
    await queryRunner.query('DROP TABLE "orders"');
    await queryRunner.query('DROP TABLE "providers"');
    await queryRunner.query('DROP TABLE "incident_types"');
    await queryRunner.query('DROP TYPE "wallet_transaction_type_enum"');
    await queryRunner.query('DROP TYPE "withdrawal_status_enum"');
    await queryRunner.query('DROP TYPE "payment_status_enum"');
    await queryRunner.query('DROP TYPE "offer_status_enum"');
    await queryRunner.query('DROP TYPE "order_status_enum"');
    await queryRunner.query('DROP TYPE "approval_status_enum"');
  }
}
