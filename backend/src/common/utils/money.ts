const moneyPattern = /^(0|[1-9]\d*)(?:\.(\d{1,2}))?$/;

export function moneyToCents(value: string): bigint {
  const match = moneyPattern.exec(value);
  if (!match) throw new Error('Invalid decimal money value');
  const fraction = (match[2] ?? '').padEnd(2, '0');
  return BigInt(match[1]) * 100n + BigInt(fraction);
}

export function centsToMoney(cents: bigint): string {
  if (cents < 0n) throw new Error('Money cannot be negative');
  const whole = cents / 100n;
  const fraction = (cents % 100n).toString().padStart(2, '0');
  return `${whole}.${fraction}`;
}
