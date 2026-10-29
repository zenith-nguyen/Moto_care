import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddOrderPhotos1760000000021 implements MigrationInterface {
  name = 'AddOrderPhotos1760000000021';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "order_photos" (
        "id" SERIAL NOT NULL,
        "order_id" integer NOT NULL,
        "uploaded_by_id" integer NOT NULL,
        "storage_key" character varying(100) NOT NULL,
        "mime_type" character varying(50) NOT NULL,
        "size_bytes" integer NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_order_photos_id" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_order_photos_storage_key" UNIQUE ("storage_key"),
        CONSTRAINT "CHK_order_photos_size_positive" CHECK ("size_bytes" > 0),
        CONSTRAINT "FK_order_photos_order" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_order_photos_uploaded_by" FOREIGN KEY ("uploaded_by_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_order_photos_order_created" ON "order_photos" ("order_id", "created_at")`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "IDX_order_photos_order_created"`,
    );
    await queryRunner.query(`DROP TABLE "order_photos"`);
  }
}
