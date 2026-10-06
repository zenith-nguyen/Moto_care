import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddChatImageAttachments1760000000006 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE "messages" ALTER COLUMN "content" DROP NOT NULL',
    );
    await queryRunner.query(
      'ALTER TABLE "messages" ADD "image_storage_key" character varying(100)',
    );
    await queryRunner.query(
      'ALTER TABLE "messages" ADD "image_mime_type" character varying(50)',
    );
    await queryRunner.query(
      'ALTER TABLE "messages" ADD "image_size_bytes" integer',
    );
    await queryRunner.query(`
      ALTER TABLE "messages" ADD CONSTRAINT "CHK_messages_content_or_image"
      CHECK (
        ("content" IS NOT NULL AND length(btrim("content")) > 0)
        OR "image_storage_key" IS NOT NULL
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "messages" ADD CONSTRAINT "CHK_messages_image_metadata"
      CHECK (
        ("image_storage_key" IS NULL AND "image_mime_type" IS NULL AND "image_size_bytes" IS NULL)
        OR
        ("image_storage_key" IS NOT NULL AND "image_mime_type" IS NOT NULL AND "image_size_bytes" > 0)
      )
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE "messages" DROP CONSTRAINT "CHK_messages_image_metadata"',
    );
    await queryRunner.query(
      'ALTER TABLE "messages" DROP CONSTRAINT "CHK_messages_content_or_image"',
    );
    await queryRunner.query(
      'ALTER TABLE "messages" DROP COLUMN "image_size_bytes"',
    );
    await queryRunner.query(
      'ALTER TABLE "messages" DROP COLUMN "image_mime_type"',
    );
    await queryRunner.query(
      'ALTER TABLE "messages" DROP COLUMN "image_storage_key"',
    );
    await queryRunner.query(
      'UPDATE "messages" SET "content" = \'\' WHERE "content" IS NULL',
    );
    await queryRunner.query(
      'ALTER TABLE "messages" ALTER COLUMN "content" SET NOT NULL',
    );
  }
}
