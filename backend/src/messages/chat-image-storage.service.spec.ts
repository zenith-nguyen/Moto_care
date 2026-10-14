import { BadRequestException, NotFoundException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { ChatImageStorageService } from "./chat-image-storage.service";

const png = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
  "base64",
);

describe("ChatImageStorageService", () => {
  let directory: string;
  let storage: ChatImageStorageService;

  beforeAll(async () => {
    directory = await mkdtemp(join(tmpdir(), "motocare-chat-image-test-"));
    storage = new ChatImageStorageService(
      new ConfigService({
        CHAT_UPLOAD_DIR: directory,
        CHAT_IMAGE_MAX_BYTES: 1024,
      }),
    );
  });

  afterAll(async () => {
    await rm(directory, { recursive: true, force: true });
  });

  it("stores and reads an allowlisted image under a generated key", async () => {
    const stored = await storage.save(
      file(png, "image/png", "../unsafe-name.png"),
    );
    expect(stored).toMatchObject({
      mimeType: "image/png",
      sizeBytes: png.length,
    });
    expect(stored.storageKey).toMatch(/^[0-9a-f-]{36}\.png$/);
    expect(await storage.read(stored.storageKey)).toEqual(png);
  });

  it("rejects a spoofed MIME type and path-like storage keys", async () => {
    await expect(
      storage.save(file(Buffer.from("not an image"), "image/png", "fake.png")),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(storage.read("../secret")).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it("rejects images above the configured limit", async () => {
    const oversized = Buffer.concat([png, Buffer.alloc(1024)]);
    await expect(
      storage.save(file(oversized, "image/png", "large.png")),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});

function file(
  buffer: Buffer,
  mimetype: string,
  originalname: string,
): Express.Multer.File {
  return {
    fieldname: "image",
    originalname,
    encoding: "7bit",
    mimetype,
    size: buffer.length,
    destination: "",
    filename: "",
    path: "",
    buffer,
    stream: undefined as never,
  };
}
