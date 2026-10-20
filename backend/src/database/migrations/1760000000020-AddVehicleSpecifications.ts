import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddVehicleSpecifications1760000000020 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "vehicles" ADD "tire_type" character varying(12) NOT NULL DEFAULT 'tubed'`);
    await queryRunner.query(`ALTER TABLE "vehicles" ADD "engine_type" character varying(12) NOT NULL DEFAULT 'gas'`);
    await queryRunner.query(`UPDATE "vehicles" SET "engine_type" = 'electric' WHERE "type" = 'ELECTRIC_MOTORBIKE'`);
    await queryRunner.query(`ALTER TABLE "vehicles" ADD CONSTRAINT "CHK_vehicles_tire_type" CHECK ("tire_type" IN ('tubed', 'tubeless'))`);
    await queryRunner.query(`ALTER TABLE "vehicles" ADD CONSTRAINT "CHK_vehicles_engine_type" CHECK ("engine_type" IN ('gas', 'electric'))`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "vehicles" DROP CONSTRAINT "CHK_vehicles_engine_type"`);
    await queryRunner.query(`ALTER TABLE "vehicles" DROP CONSTRAINT "CHK_vehicles_tire_type"`);
    await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "engine_type"`);
    await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "tire_type"`);
  }
}
