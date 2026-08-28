/**
 * Financial Money Utilities for TRADEX.
 * TRADEX strictly stores authoritative money as integers/bigints in minor units (e.g. Poisha / Cents).
 * 1 BDT = 100 Poisha.
 */

export const MINOR_UNIT_SCALE = 100n;

/**
 * Converts a decimal amount (e.g. 100.50) to integer minor units (e.g. 10050n).
 */
export function toMinorUnits(amount: number | string | bigint): bigint {
  if (typeof amount === 'bigint') {
    return amount;
  }
  if (typeof amount === 'number') {
    // Round to avoid floating point precision quirks
    return BigInt(Math.round(amount * 100));
  }
  const parsed = parseFloat(amount);
  if (isNaN(parsed)) {
    throw new Error(`Invalid monetary amount: ${amount}`);
  }
  return BigInt(Math.round(parsed * 100));
}

/**
 * Converts minor units to formatted decimal number (e.g. 10050n -> 100.5).
 */
export function fromMinorUnits(minorUnits: bigint | string | number): number {
  const value = typeof minorUnits === 'bigint' ? Number(minorUnits) : Number(minorUnits);
  return value / 100;
}

/**
 * Formats minor units as currency string (e.g. "৳100.50").
 */
export function formatMoney(minorUnits: bigint | string | number, currency: string = 'BDT'): string {
  const decimal = fromMinorUnits(minorUnits);
  return `${currency === 'BDT' ? '৳' : currency + ' '}${decimal.toFixed(2)}`;
}

/**
 * Calculate percentage in basis points (1 bp = 0.01% = 0.0001).
 * Example: 200 bp on 10000 minor units = (10000 * 200) / 10000 = 200 minor units (2%).
 */
export function calculateBasisPoints(amountMinor: bigint, basisPoints: number): bigint {
  if (basisPoints <= 0) return 0n;
  return (amountMinor * BigInt(basisPoints)) / 10000n;
}
