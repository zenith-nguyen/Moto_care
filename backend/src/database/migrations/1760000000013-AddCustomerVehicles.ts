import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddCustomerVehicles1760000000013 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE TYPE "vehicles_type_enum" AS ENUM ('MOTORBIKE', 'ELECTRIC_MOTORBIKE', 'CAR', 'OTHER')`);
    await queryRunner.query(`
      CREATE TABLE "vehicles" (
        "id" SERIAL NOT NULL,
        "customer_id" integer NOT NULL,
        "type" "vehicles_type_enum" NOT NULL,
        "brand" character varying(80) NOT NULL,
        "model" character varying(100) NOT NULL,
        "license_plate" character varying(20) NOT NULL,
        "color" character varying(40),
        "is_default" boolean NOT NULL DEFAULT false,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_vehicles_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_vehicles_license_plate" UNIQUE ("license_plate"),
        CONSTRAINT "CHK_vehicles_license_plate" CHECK ("license_plate" ~ '^[A-Z0-9.-]{4,20}$'),
        CONSTRAINT "FK_vehicles_customer" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`CREATE INDEX "IDX_vehicles_customer" ON "vehicles" ("customer_id")`);
    await queryRunner.query(
      `CREATE UNIQUE INDEX "UQ_vehicles_one_default_per_customer" ON "vehicles" ("customer_id") WHERE "is_default" = true`,
    );

    await queryRunner.query(`CREATE TYPE "orders_vehicle_type_enum" AS ENUM ('MOTORBIKE', 'ELECTRIC_MOTORBIKE', 'CAR', 'OTHER')`);
    await queryRunner.query(`ALTER TABLE "orders" ADD "vehicle_id" integer`);
    await queryRunner.query(`ALTER TABLE "orders" ADD "vehicle_type" "orders_vehicle_type_enum"`);
    await queryRunner.query(`ALTER TABLE "orders" ADD "vehicle_brand" character varying(80)`);
    await queryRunner.query(`ALTER TABLE "orders" ADD "vehicle_model" character varying(100)`);
    await queryRunner.query(`ALTER TABLE "orders" ADD "vehicle_license_plate" character varying(20)`);
    await queryRunner.query(`ALTER TABLE "orders" ADD "vehicle_color" character varying(40)`);
    await queryRunner.query(`
      ALTER TABLE "orders" ADD CONSTRAINT "CHK_orders_vehicle_snapshot_complete" CHECK (
        ("vehicle_type" IS NULL AND "vehicle_brand" IS NULL AND "vehicle_model" IS NULL AND "vehicle_license_plate" IS NULL)
        OR
        ("vehicle_type" IS NOT NULL AND "vehicle_brand" IS NOT NULL AND "vehicle_model" IS NOT NULL AND "vehicle_license_plate" IS NOT NULL)
      )
    `);
    await queryRunner.query(
      `ALTER TABLE "orders" ADD CONSTRAINT "FK_orders_vehicle" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE SET NULL`,
    );
    await queryRunner.query(`CREATE INDEX "IDX_orders_vehicle_id" ON "orders" ("vehicle_id")`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "IDX_orders_vehicle_id"`);
    await queryRunner.query(`ALTER TABLE "orders" DROP CONSTRAINT "FK_orders_vehicle"`);
    await queryRunner.query(`ALTER TABLE "orders" DROP CONSTRAINT "CHK_orders_vehicle_snapshot_complete"`);
    await queryRunner.query(`ALTER TABLE "orders" DROP COLUMN "vehicle_color"`);
    await queryRunner.query(`ALTER TABLE "orders" DROP COLUMN "vehicle_license_plate"`);
    await queryRunner.query(`ALTER TABLE "orders" DROP COLUMN "vehicle_model"`);
    await queryRunner.query(`ALTER TABLE "orders" DROP COLUMN "vehicle_brand"`);
    await queryRunner.query(`ALTER TABLE "orders" DROP COLUMN "vehicle_type"`);
    await queryRunner.query(`ALTER TABLE "orders" DROP COLUMN "vehicle_id"`);
    await queryRunner.query(`DROP TYPE "orders_vehicle_type_enum"`);

    await queryRunner.query(`DROP INDEX "UQ_vehicles_one_default_per_customer"`);
    await queryRunner.query(`DROP INDEX "IDX_vehicles_customer"`);
    await queryRunner.query(`DROP TABLE "vehicles"`);
    await queryRunner.query(`DROP TYPE "vehicles_type_enum"`);
  }
}
