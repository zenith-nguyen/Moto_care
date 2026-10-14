import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddWeatherPricingSnapshot1760000000008 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE "orders" ADD "base_price" numeric(12,2)');
    await queryRunner.query('UPDATE "orders" SET "base_price" = "estimated_price"');
    await queryRunner.query('ALTER TABLE "orders" ALTER COLUMN "base_price" SET NOT NULL');
    await queryRunner.query('ALTER TABLE "orders" ADD "weather_surcharge" numeric(12,2) NOT NULL DEFAULT 0');
    await queryRunner.query('ALTER TABLE "orders" ADD "weather_multiplier" numeric(5,4) NOT NULL DEFAULT 1');
    await queryRunner.query(`ALTER TABLE "orders" ADD "weather_category" varchar(20) NOT NULL DEFAULT 'DISABLED'`);
    await queryRunner.query(`ALTER TABLE "orders" ADD "weather_source" varchar(30) NOT NULL DEFAULT 'FALLBACK'`);
    await queryRunner.query('ALTER TABLE "orders" ADD "weather_observed_at" timestamptz');
    await queryRunner.query('ALTER TABLE "orders" ADD "weather_code" smallint');
    await queryRunner.query('ALTER TABLE "orders" ADD "weather_precipitation_mm" numeric(7,2)');
    await queryRunner.query('ALTER TABLE "orders" ADD "weather_wind_speed_kmh" numeric(7,2)');
    await queryRunner.query('ALTER TABLE "orders" ADD "weather_wind_gust_kmh" numeric(7,2)');
    await queryRunner.query('ALTER TABLE "orders" ADD CONSTRAINT "CHK_orders_base_price_non_negative" CHECK ("base_price" >= 0)');
    await queryRunner.query(
      'ALTER TABLE "orders" ADD CONSTRAINT "CHK_orders_weather_surcharge_non_negative" CHECK ("weather_surcharge" >= 0)',
    );
    await queryRunner.query(
      'ALTER TABLE "orders" ADD CONSTRAINT "CHK_orders_weather_multiplier_range" CHECK ("weather_multiplier" BETWEEN 1 AND 1.2)',
    );
    await queryRunner.query(
      `ALTER TABLE "orders" ADD CONSTRAINT "CHK_orders_weather_category" CHECK ("weather_category" IN ('DISABLED', 'UNAVAILABLE', 'NORMAL', 'MODERATE', 'SEVERE'))`,
    );
    await queryRunner.query(
      `ALTER TABLE "orders" ADD CONSTRAINT "CHK_orders_weather_source" CHECK ("weather_source" IN ('OPEN_METEO', 'FALLBACK'))`,
    );
    await queryRunner.query(
      'ALTER TABLE "orders" ADD CONSTRAINT "CHK_orders_weather_measurements_non_negative" CHECK (("weather_precipitation_mm" IS NULL OR "weather_precipitation_mm" >= 0) AND ("weather_wind_speed_kmh" IS NULL OR "weather_wind_speed_kmh" >= 0) AND ("weather_wind_gust_kmh" IS NULL OR "weather_wind_gust_kmh" >= 0))',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE "orders" DROP CONSTRAINT "CHK_orders_weather_measurements_non_negative"');
    await queryRunner.query('ALTER TABLE "orders" DROP CONSTRAINT "CHK_orders_weather_source"');
    await queryRunner.query('ALTER TABLE "orders" DROP CONSTRAINT "CHK_orders_weather_category"');
    await queryRunner.query('ALTER TABLE "orders" DROP CONSTRAINT "CHK_orders_weather_multiplier_range"');
    await queryRunner.query('ALTER TABLE "orders" DROP CONSTRAINT "CHK_orders_weather_surcharge_non_negative"');
    await queryRunner.query('ALTER TABLE "orders" DROP CONSTRAINT "CHK_orders_base_price_non_negative"');
    await queryRunner.query('ALTER TABLE "orders" DROP COLUMN "weather_wind_gust_kmh"');
    await queryRunner.query('ALTER TABLE "orders" DROP COLUMN "weather_wind_speed_kmh"');
    await queryRunner.query('ALTER TABLE "orders" DROP COLUMN "weather_precipitation_mm"');
    await queryRunner.query('ALTER TABLE "orders" DROP COLUMN "weather_code"');
    await queryRunner.query('ALTER TABLE "orders" DROP COLUMN "weather_observed_at"');
    await queryRunner.query('ALTER TABLE "orders" DROP COLUMN "weather_source"');
    await queryRunner.query('ALTER TABLE "orders" DROP COLUMN "weather_category"');
    await queryRunner.query('ALTER TABLE "orders" DROP COLUMN "weather_multiplier"');
    await queryRunner.query('ALTER TABLE "orders" DROP COLUMN "weather_surcharge"');
    await queryRunner.query('ALTER TABLE "orders" DROP COLUMN "base_price"');
  }
}
