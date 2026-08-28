import { describe, expect, it } from 'bun:test';
import {
  calculateBasisPoints,
  formatMoney,
  fromMinorUnits,
  toMinorUnits,
} from '../src/utils/money.ts';

describe('Financial Money Utilities', () => {
  it('converts decimal amounts to minor units accurately', () => {
    expect(toMinorUnits(100)).toBe(10000n);
    expect(toMinorUnits(100.5)).toBe(10050n);
    expect(toMinorUnits(100.55)).toBe(10055n);
    expect(toMinorUnits('250.75')).toBe(25075n);
    expect(toMinorUnits(50000n)).toBe(50000n);
  });

  it('converts minor units back to decimal amounts', () => {
    expect(fromMinorUnits(10000n)).toBe(100);
    expect(fromMinorUnits(10050n)).toBe(100.5);
    expect(fromMinorUnits(25075n)).toBe(250.75);
    expect(fromMinorUnits('5000')).toBe(50);
  });

  it('formats currency correctly', () => {
    expect(formatMoney(10000n, 'BDT')).toBe('৳100.00');
    expect(formatMoney(25075n, 'BDT')).toBe('৳250.75');
    expect(formatMoney(5000n, 'USD')).toBe('USD 50.00');
  });

  it('calculates basis points percentage correctly without float inaccuracies', () => {
    // 2.5% on 100,000 minor units (1000 BDT) -> 250 basis points -> 2500 minor units (25 BDT)
    const amount = 100000n;
    const fee = calculateBasisPoints(amount, 250);
    expect(fee).toBe(2500n);

    // 0 basis points
    expect(calculateBasisPoints(100000n, 0)).toBe(0n);

    // 1% (100 bp) on 10000 minor units
    expect(calculateBasisPoints(10000n, 100)).toBe(100n);
  });
});
