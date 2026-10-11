import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddProviderProfessionalProfiles1760000000014 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE TYPE "providers_tier_enum" AS ENUM ('STANDARD', 'SILVER', 'GOLD', 'PLATINUM')`);
    await queryRunner.query(`CREATE TYPE "provider_skills_verification_status_enum" AS ENUM ('PENDING', 'VERIFIED', 'REJECTED')`);
    await queryRunner.query(`
      ALTER TABLE "providers"
        ADD COLUMN "bio" text,
        ADD COLUMN "years_of_experience" smallint NOT NULL DEFAULT 0,
        ADD COLUMN "service_radius_km" numeric(5,2) NOT NULL DEFAULT 10,
        ADD COLUMN "tier" "providers_tier_enum" NOT NULL DEFAULT 'STANDARD'
    `);
    await queryRunner.query(`
      ALTER TABLE "providers"
        ADD CONSTRAINT "CHK_providers_years_experience" CHECK ("years_of_experience" BETWEEN 0 AND 70),
        ADD CONSTRAINT "CHK_providers_service_radius" CHECK ("service_radius_km" BETWEEN 1 AND 100)
    `);
    await queryRunner.query(`
      CREATE TABLE "skills" (
        "id" SERIAL NOT NULL,
        "code" varchar(50) NOT NULL,
        "name" varchar(100) NOT NULL,
        "is_active" boolean NOT NULL DEFAULT true,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_skills" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`CREATE UNIQUE INDEX "UQ_skills_code" ON "skills" ("code")`);
    await queryRunner.query(`
      CREATE TABLE "provider_skills" (
        "id" SERIAL NOT NULL,
        "provider_id" integer NOT NULL,
        "skill_id" integer NOT NULL,
        "verification_status" "provider_skills_verification_status_enum" NOT NULL DEFAULT 'PENDING',
        "verified_at" timestamptz,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_provider_skills" PRIMARY KEY ("id"),
        CONSTRAINT "FK_provider_skills_provider" FOREIGN KEY ("provider_id") REFERENCES "providers"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_provider_skills_skill" FOREIGN KEY ("skill_id") REFERENCES "skills"("id") ON DELETE RESTRICT,
        CONSTRAINT "CHK_provider_skills_verified_at" CHECK (
          ("verification_status" = 'VERIFIED' AND "verified_at" IS NOT NULL)
          OR ("verification_status" <> 'VERIFIED' AND "verified_at" IS NULL)
        )
      )
    `);
    await queryRunner.query(`CREATE UNIQUE INDEX "UQ_provider_skills_provider_skill" ON "provider_skills" ("provider_id", "skill_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_provider_skills_provider_status" ON "provider_skills" ("provider_id", "verification_status")`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "IDX_provider_skills_provider_status"`);
    await queryRunner.query(`DROP INDEX "UQ_provider_skills_provider_skill"`);
    await queryRunner.query(`DROP TABLE "provider_skills"`);
    await queryRunner.query(`DROP INDEX "UQ_skills_code"`);
    await queryRunner.query(`DROP TABLE "skills"`);
    await queryRunner.query(`ALTER TABLE "providers" DROP CONSTRAINT "CHK_providers_service_radius"`);
    await queryRunner.query(`ALTER TABLE "providers" DROP CONSTRAINT "CHK_providers_years_experience"`);
    await queryRunner.query(`
      ALTER TABLE "providers"
        DROP COLUMN "tier",
        DROP COLUMN "service_radius_km",
        DROP COLUMN "years_of_experience",
        DROP COLUMN "bio"
    `);
    await queryRunner.query(`DROP TYPE "provider_skills_verification_status_enum"`);
    await queryRunner.query(`DROP TYPE "providers_tier_enum"`);
  }
}
