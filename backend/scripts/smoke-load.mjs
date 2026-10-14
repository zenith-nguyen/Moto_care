const baseUrl = (process.env.SMOKE_BASE_URL ?? 'http://localhost:3000').replace(/\/$/, '');
const requestCount = readPositiveInteger('SMOKE_REQUESTS', 40);
const concurrency = Math.min(readPositiveInteger('SMOKE_CONCURRENCY', 5), requestCount);
const timeoutMs = readPositiveInteger('SMOKE_TIMEOUT_MS', 5_000);
const p95LimitMs = readPositiveInteger('SMOKE_P95_LIMIT_MS', 1_500);

const paths = ['/health', '/health/ready'];
const durations = [];
const failures = [];
let nextRequest = 0;

function readPositiveInteger(name, fallback) {
  const raw = process.env[name];
  if (raw === undefined) return fallback;
  const value = Number(raw);
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new Error(`${name} must be a positive integer`);
  }
  return value;
}

async function worker() {
  while (nextRequest < requestCount) {
    const index = nextRequest++;
    const path = paths[index % paths.length];
    const startedAt = performance.now();
    try {
      const response = await fetch(`${baseUrl}${path}`, { signal: AbortSignal.timeout(timeoutMs) });
      const body = await response.json();
      if (!response.ok || body.status !== 'ok' || (path.endsWith('/ready') && body.database !== 'ok')) {
        failures.push(`${path}: HTTP ${response.status} or invalid health body`);
      }
    } catch (error) {
      failures.push(`${path}: ${error instanceof Error ? error.message : 'unknown request error'}`);
    } finally {
      durations.push(performance.now() - startedAt);
    }
  }
}

await Promise.all(Array.from({ length: concurrency }, () => worker()));

durations.sort((left, right) => left - right);
const percentile = (ratio) => durations[Math.min(Math.ceil(durations.length * ratio) - 1, durations.length - 1)];
const p50 = percentile(0.5);
const p95 = percentile(0.95);
const maximum = durations.at(-1);

console.log(JSON.stringify({
  baseUrl,
  requests: requestCount,
  concurrency,
  successful: requestCount - failures.length,
  failed: failures.length,
  latencyMs: {
    p50: Number(p50.toFixed(1)),
    p95: Number(p95.toFixed(1)),
    maximum: Number(maximum.toFixed(1)),
    p95Limit: p95LimitMs,
  },
}, null, 2));

if (failures.length > 0) {
  console.error(`Smoke-load failures:\n${failures.slice(0, 10).join('\n')}`);
  process.exitCode = 1;
} else if (p95 > p95LimitMs) {
  console.error(`Smoke-load p95 ${p95.toFixed(1)} ms exceeded ${p95LimitMs} ms`);
  process.exitCode = 1;
}
