import { describe, expect, it } from 'bun:test';
import { winnersService } from './winners.service.ts';
import type { PrizeRule } from '../draws/draws.service.ts';

describe('WinnersService Matching Logic', () => {
  it('should correctly match Mega Draw 7-digit numbers with leading zeros', () => {
    const winningNumber = '0012345';

    // 1. Exact match (Jackpot)
    const exact = winnersService.evaluateMatch('0012345', winningNumber, 'MEGA', []);
    expect(exact).not.toBeNull();
    expect(exact?.matchType).toBe('MATCH_7');
    expect(exact?.prizeAmountMinor).toBe(1000000000n); // ৳10,000,000

    // 2. Match last 6 digits
    const match6 = winnersService.evaluateMatch('9012345', winningNumber, 'MEGA', []);
    expect(match6).not.toBeNull();
    expect(match6?.matchType).toBe('MATCH_LAST_6');
    expect(match6?.prizeAmountMinor).toBe(50000000n); // ৳500,000

    // 3. Match last 5 digits
    const match5 = winnersService.evaluateMatch('9912345', winningNumber, 'MEGA', []);
    expect(match5).not.toBeNull();
    expect(match5?.matchType).toBe('MATCH_LAST_5');
    expect(match5?.prizeAmountMinor).toBe(5000000n); // ৳50,000

    // 4. Match last 4 digits
    const match4 = winnersService.evaluateMatch('9992345', winningNumber, 'MEGA', []);
    expect(match4).not.toBeNull();
    expect(match4?.matchType).toBe('MATCH_LAST_4');
    expect(match4?.prizeAmountMinor).toBe(500000n); // ৳5,000

    // 5. Match last 3 digits
    const match3 = winnersService.evaluateMatch('9999345', winningNumber, 'MEGA', []);
    expect(match3).not.toBeNull();
    expect(match3?.matchType).toBe('MATCH_LAST_3');
    expect(match3?.prizeAmountMinor).toBe(50000n); // ৳500

    // 6. Match last 2 digits
    const match2 = winnersService.evaluateMatch('9999945', winningNumber, 'MEGA', []);
    expect(match2).not.toBeNull();
    expect(match2?.matchType).toBe('MATCH_LAST_2');
    expect(match2?.prizeAmountMinor).toBe(5000n); // ৳50

    // 7. No match (only last 1 digit matches)
    const noMatch = winnersService.evaluateMatch('9999995', winningNumber, 'MEGA', []);
    expect(noMatch).toBeNull();
  });

  it('should correctly match Daily Draw 3-digit numbers with leading zeros', () => {
    const winningNumber = '007';

    // 1. Exact match
    const exact = winnersService.evaluateMatch('007', winningNumber, 'DAILY', []);
    expect(exact).not.toBeNull();
    expect(exact?.matchType).toBe('MATCH_3');
    expect(exact?.prizeAmountMinor).toBe(500000n); // ৳5,000

    // 2. Match last 2 digits
    const match2 = winnersService.evaluateMatch('107', winningNumber, 'DAILY', []);
    expect(match2).not.toBeNull();
    expect(match2?.matchType).toBe('MATCH_LAST_2');
    expect(match2?.prizeAmountMinor).toBe(50000n); // ৳500

    // 3. Match last 1 digit
    const match1 = winnersService.evaluateMatch('997', winningNumber, 'DAILY', []);
    expect(match1).not.toBeNull();
    expect(match1?.matchType).toBe('MATCH_LAST_1');
    expect(match1?.prizeAmountMinor).toBe(5000n); // ৳50

    // 4. No match
    const noMatch = winnersService.evaluateMatch('999', winningNumber, 'DAILY', []);
    expect(noMatch).toBeNull();
  });

  it('should prioritize dynamic database prize rules when provided', () => {
    const winningNumber = '1234567';
    const dynamicRules: PrizeRule[] = [
      {
        id: 101,
        draw_type_id: 1,
        name: 'Custom Super Jackpot',
        match_type: 'MATCH_7',
        prize_amount_minor: 5000000000n.toString(),
        priority: 1,
        status: 'ACTIVE',
      },
      {
        id: 102,
        draw_type_id: 1,
        name: 'Custom Tier 2',
        match_type: 'MATCH_LAST_4',
        prize_amount_minor: 1000000n.toString(),
        priority: 2,
        status: 'ACTIVE',
      },
    ];

    const match = winnersService.evaluateMatch('1234567', winningNumber, 'MEGA', dynamicRules);
    expect(match).not.toBeNull();
    expect(match?.ruleId).toBe(101);
    expect(match?.name).toBe('Custom Super Jackpot');
    expect(match?.prizeAmountMinor).toBe(5000000000n);

    const matchPartial = winnersService.evaluateMatch('9994567', winningNumber, 'MEGA', dynamicRules);
    expect(matchPartial).not.toBeNull();
    expect(matchPartial?.ruleId).toBe(102);
    expect(matchPartial?.name).toBe('Custom Tier 2');
  });
});
