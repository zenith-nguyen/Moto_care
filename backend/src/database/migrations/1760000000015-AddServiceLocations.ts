import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddServiceLocations1760000000015 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE TYPE "service_locations_source_enum" AS ENUM ('OSM', 'MANUAL')`);
    await queryRunner.query(`CREATE TYPE "service_locations_type_enum" AS ENUM ('REPAIR_SHOP', 'CHARGING_STATION', 'FUEL_STATION', 'PARTS_STORE')`);
    await queryRunner.query(`
      CREATE TABLE "service_locations" (
        "id" SERIAL NOT NULL,
        "source" "service_locations_source_enum" NOT NULL,
        "source_id" varchar(80) NOT NULL,
        "type" "service_locations_type_enum" NOT NULL,
        "name" varchar(200) NOT NULL,
        "address" text,
        "phone" varchar(50),
        "website" varchar(500),
        "opening_hours" varchar(300),
        "location" geography(Point,4326) NOT NULL,
        "is_verified" boolean NOT NULL DEFAULT false,
        "is_partner" boolean NOT NULL DEFAULT false,
        "is_active" boolean NOT NULL DEFAULT true,
        "source_updated_at" timestamptz,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_service_locations" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`CREATE UNIQUE INDEX "UQ_service_locations_source_id" ON "service_locations" ("source", "source_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_service_locations_type_active" ON "service_locations" ("type", "is_active")`);
    await queryRunner.query(`CREATE INDEX "IDX_service_locations_location_gist" ON "service_locations" USING GIST ("location")`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "IDX_service_locations_location_gist"`);
    await queryRunner.query(`DROP INDEX "IDX_service_locations_type_active"`);
    await queryRunner.query(`DROP INDEX "UQ_service_locations_source_id"`);
    await queryRunner.query(`DROP TABLE "service_locations"`);
    await queryRunner.query(`DROP TYPE "service_locations_type_enum"`);
    await queryRunner.query(`DROP TYPE "service_locations_source_enum"`);
  }
}
