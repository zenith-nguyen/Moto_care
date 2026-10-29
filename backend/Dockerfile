# MotoCare backend — production image.
# Multi-stage: build with full deps, run with production deps only.
# bookworm-slim (glibc) is used so native modules (argon2) load prebuilt
# binaries without a compiler toolchain.

# ---- Build stage ---------------------------------------------------------
FROM node:22-bookworm-slim AS builder
WORKDIR /app

# Install all dependencies (including dev) for the Nest build.
COPY package.json package-lock.json ./
RUN npm ci

# Compile TypeScript to dist/.
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
RUN npm run build

# ---- Runtime stage -------------------------------------------------------
FROM node:22-bookworm-slim AS runtime
ENV NODE_ENV=production
WORKDIR /app

# Production dependencies only (typeorm CLI stays available for migrations).
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Compiled application and the TypeORM data source + migrations.
COPY --from=builder /app/dist ./dist

# The platform (Render/Railway/Fly) injects PORT and the DATABASE_* / SEPAY_*
# env vars; dotenv/config is a no-op when no .env file is present.
EXPOSE 3000

# Apply pending migrations, then boot the API. Migrations are idempotent
# (TypeORM skips already-applied ones), so this is safe on every restart.
CMD ["sh", "-c", "npm run migration:run:prod && npm run start:prod"]
