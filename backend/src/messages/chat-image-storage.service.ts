import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { randomUUID } from "node:crypto";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { isAbsolute, join, resolve } from "node:path";

export type StoredChatImage = {
  storageKey: string;
  mimeType: string;
  sizeBytes: number;
};

const imageFormats = [
  {
    mimeType: "image/jpeg",
    extension: "jpg",
    matches: (buffer: Buffer) =>
      buffer.length >= 3 &&
      buffer[0] === 0xff &&
      buffer[1] === 0xd8 &&
      buffer[2] === 0xff,
  },
  {
    mimeType: "image/png",
    extension: "png",
    matches: (buffer: Buffer) =>
      buffer.length >= 8 &&
      buffer
        .subarray(0, 8)
        .equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
  },
  {
    mimeType: "image/webp",
    extension: "webp",
    matches: (buffer: Buffer) =>
      buffer.length >= 12 &&
      buffer.subarray(0, 4).toString("ascii") === "RIFF" &&
      buffer.subarray(8, 12).toString("ascii") === "WEBP",
  },
];

@Injectable()
export class ChatImageStorageService {
  private readonly uploadDirectory: string;
  private readonly maxBytes: number;

  constructor(config: ConfigService) {
    const configuredDirectory =
      config.get<string>("CHAT_UPLOAD_DIR") ?? "storage/chat";
    this.uploadDirectory = isAbsolute(configuredDirectory)
      ? resolve(configuredDirectory)
      : resolve(process.cwd(), configuredDirectory);
    this.maxBytes = Number(config.get("CHAT_IMAGE_MAX_BYTES") ?? 5_242_880);
  }

  async save(file: Express.Multer.File): Promise<StoredChatImage> {
    if (!file.buffer?.length)
      throw new BadRequestException("Image file is empty");
    if (file.size > this.maxBytes || file.buffer.length > this.maxBytes) {
      throw new BadRequestException(
        `Image must not exceed ${this.maxBytes} bytes`,
      );
    }
    const format = imageFormats.find((candidate) =>
      candidate.matches(file.buffer),
    );
    if (!format || file.mimetype !== format.mimeType) {
      throw new BadRequestException(
        "Only genuine JPEG, PNG or WebP images are allowed",
      );
    }

    const storageKey = `${randomUUID()}.${format.extension}`;
    await mkdir(this.uploadDirectory, { recursive: true });
    await writeFile(this.pathFor(storageKey), file.buffer, { flag: "wx" });
    return {
      storageKey,
      mimeType: format.mimeType,
      sizeBytes: file.buffer.length,
    };
  }

  async read(storageKey: string): Promise<Buffer> {
    try {
      return await readFile(this.pathFor(storageKey));
    } catch {
      throw new NotFoundException("Message image not found");
    }
  }

  async remove(storageKey: string): Promise<void> {
    await rm(this.pathFor(storageKey), { force: true });
  }

  private pathFor(storageKey: string): string {
    if (!/^[0-9a-f-]{36}\.(jpg|png|webp)$/.test(storageKey)) {
      throw new NotFoundException("Message image not found");
    }
    return join(this.uploadDirectory, storageKey);
  }
}
