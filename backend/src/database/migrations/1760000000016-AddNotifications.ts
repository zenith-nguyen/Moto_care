import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddNotifications1760000000016 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE TYPE "user_devices_platform_enum" AS ENUM ('ANDROID', 'IOS')`);
    await queryRunner.query(`CREATE TYPE "notifications_type_enum" AS ENUM ('OFFER_CREATED', 'OFFER_EXPIRED', 'ORDER_STATUS_CHANGED', 'PROVIDER_NEARBY', 'MESSAGE_CREATED', 'SYSTEM')`);
    await queryRunner.query(`CREATE TYPE "notification_deliveries_status_enum" AS ENUM ('PENDING', 'PROCESSING', 'SENT', 'FAILED', 'SKIPPED')`);
    await queryRunner.query(`
      CREATE TABLE "user_devices" (
        "id" SERIAL NOT NULL,
        "user_id" integer NOT NULL,
        "installation_id" varchar(128) NOT NULL,
        "fcm_token" varchar(4096) NOT NULL,
        "platform" "user_devices_platform_enum" NOT NULL,
        "is_enabled" boolean NOT NULL DEFAULT true,
        "last_seen_at" timestamptz NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_user_devices" PRIMARY KEY ("id"),
        CONSTRAINT "FK_user_devices_user" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`CREATE UNIQUE INDEX "UQ_user_devices_installation_id" ON "user_devices" ("installation_id")`);
    await queryRunner.query(`CREATE UNIQUE INDEX "UQ_user_devices_fcm_token" ON "user_devices" ("fcm_token")`);
    await queryRunner.query(`CREATE INDEX "IDX_user_devices_user_enabled" ON "user_devices" ("user_id", "is_enabled")`);

    await queryRunner.query(`
      CREATE TABLE "notifications" (
        "id" SERIAL NOT NULL,
        "user_id" integer NOT NULL,
        "type" "notifications_type_enum" NOT NULL,
        "title" varchar(120) NOT NULL,
        "body" varchar(500) NOT NULL,
        "data" jsonb NOT NULL DEFAULT '{}'::jsonb,
        "dedupe_key" varchar(180),
        "read_at" timestamptz,
        "expires_at" timestamptz,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_notifications" PRIMARY KEY ("id"),
        CONSTRAINT "FK_notifications_user" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`CREATE UNIQUE INDEX "UQ_notifications_dedupe_key" ON "notifications" ("dedupe_key") WHERE "dedupe_key" IS NOT NULL`);
    await queryRunner.query(`CREATE INDEX "IDX_notifications_user_id_id" ON "notifications" ("user_id", "id" DESC)`);
    await queryRunner.query(`CREATE INDEX "IDX_notifications_user_unread" ON "notifications" ("user_id", "read_at")`);

    await queryRunner.query(`
      CREATE TABLE "notification_deliveries" (
        "id" SERIAL NOT NULL,
        "notification_id" integer NOT NULL,
        "device_id" integer,
        "status" "notification_deliveries_status_enum" NOT NULL DEFAULT 'PENDING',
        "attempt_count" smallint NOT NULL DEFAULT 0,
        "next_attempt_at" timestamptz NOT NULL DEFAULT now(),
        "sent_at" timestamptz,
        "last_error_code" varchar(100),
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_notification_deliveries" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_notification_deliveries_attempt_count" CHECK ("attempt_count" >= 0),
        CONSTRAINT "FK_notification_deliveries_notification" FOREIGN KEY ("notification_id") REFERENCES "notifications"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_notification_deliveries_device" FOREIGN KEY ("device_id") REFERENCES "user_devices"("id") ON DELETE SET NULL
      )
    `);
    await queryRunner.query(`CREATE UNIQUE INDEX "UQ_notification_deliveries_notification_device" ON "notification_deliveries" ("notification_id", "device_id") WHERE "device_id" IS NOT NULL`);
    await queryRunner.query(`CREATE INDEX "IDX_notification_deliveries_status_next_attempt" ON "notification_deliveries" ("status", "next_attempt_at")`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "notification_deliveries"`);
    await queryRunner.query(`DROP TABLE "notifications"`);
    await queryRunner.query(`DROP TABLE "user_devices"`);
    await queryRunner.query(`DROP TYPE "notification_deliveries_status_enum"`);
    await queryRunner.query(`DROP TYPE "notifications_type_enum"`);
    await queryRunner.query(`DROP TYPE "user_devices_platform_enum"`);
  }
}
