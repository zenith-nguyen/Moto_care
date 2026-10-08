import { applyDecorators, SetMetadata } from "@nestjs/common";

// @nestjs/throttler reads these metadata keys. Keeping the integration here
// avoids importing its CommonJS decorator from every ESM-tested controller.
export function RateLimit(limit: number, ttlMs: number): MethodDecorator {
  return applyDecorators(
    SetMetadata("THROTTLER:LIMITdefault", limit),
    SetMetadata("THROTTLER:TTLdefault", ttlMs),
  );
}
