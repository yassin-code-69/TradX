import { describe, expect, it, mock, spyOn, beforeEach, afterEach } from 'bun:test';
import * as dbModule from '../../db/index.ts';
import { ResultsService } from './results.service.ts';
import { WinnersService } from '../winners/winners.service.ts';
import { DrawsService } from '../draws/draws.service.ts';
import { processOutboxEvents } from '../worker/worker.ts';
import type pg from 'pg';

describe('Atomic Draw Result Publishing & Outbox Worker Suite', () => {
  let resultsService: ResultsService;
  let winnersService: WinnersService;
  let drawsService: DrawsService;

  beforeEach(() => {
    resultsService = new ResultsService();
    winnersService = new WinnersService();
    drawsService = new DrawsService();
  });

  describe('1. ResultsService.publishResult Atomic Transactions', () => {
    it('executes draw result creation, winner payouts, and completion inside a single withTransaction', async () => {
      const mockDraw = {
        id: 42,
        public_id: 'draw-uuid-42',
        draw_type_code: 'MEGA',
        digit_length: 7,
        sequence_number: 'MG-2026-001',
        ticket_price_minor: '10000',
        sale_open_at: new Date().toISOString(),
        sale_close_at: new Date().toISOString(),
        draw_at: new Date().toISOString(),
      };

      const getDrawSpy = spyOn(drawsService, 'getDrawById').mockResolvedValue(mockDraw as any);

      const executedQueries: string[] = [];
      const mockClient = {
        query: mock(async (text: string) => {
          executedQueries.push(text.trim());
          if (text.includes('FROM draw_results WHERE draw_id')) {
            return { rows: [] };
          }
          if (text.includes("UPDATE draws SET status = 'PROCESSING'") || text.includes("UPDATE draws SET status = 'COMPLETED'")) {
            return { rows: [{ id: 42, status: 'COMPLETED' }] };
          }
          if (text.includes('INSERT INTO draw_results')) {
            return {
              rows: [
                {
                  id: 10,
                  public_id: 'res-uuid-10',
                  draw_id: 42,
                  winning_number: '1234567',
                  published_by: 'admin-1',
                  published_at: new Date().toISOString(),
                  created_at: new Date().toISOString(),
                },
              ],
            };
          }
          return { rows: [] };
        }),
      } as unknown as pg.PoolClient;

      let withTransactionCalled = false;
      const withTxSpy = spyOn(dbModule, 'withTransaction').mockImplementation(async (cb: any) => {
        withTransactionCalled = true;
        return await cb(mockClient);
      });

      const mockStats = {
        totalTicketsEvaluated: 5,
        winnersCount: 2,
        totalPrizePaidMinor: '550000',
        winners: [],
      };
      const processWinnersSpy = spyOn(winnersService, 'processDrawWinners').mockResolvedValue(mockStats as any);

      // Temporarily inject mocks into module
      const origGetDraw = (await import('../draws/draws.service.ts')).drawsService.getDrawById;
      const origProcessWinners = (await import('../winners/winners.service.ts')).winnersService.processDrawWinners;
      (await import('../draws/draws.service.ts')).drawsService.getDrawById = getDrawSpy;
      (await import('../winners/winners.service.ts')).winnersService.processDrawWinners = processWinnersSpy;

      try {
        const res = await resultsService.publishResult('admin-1', {
          draw_id: 42,
          winning_number: '1234567',
        });

        expect(withTransactionCalled).toBe(true);
        expect(processWinnersSpy).toHaveBeenCalledWith(42, '1234567', 'admin-1', mockClient);
        expect(res.result?.winning_number).toBe('1234567');
        expect(res.stats.winnersCount).toBe(2);
        expect(executedQueries.some((q) => q.includes("UPDATE draws SET status = 'PROCESSING'"))).toBe(true);
        expect(executedQueries.some((q) => q.includes("UPDATE draws SET status = 'COMPLETED'"))).toBe(true);
      } finally {
        (await import('../draws/draws.service.ts')).drawsService.getDrawById = origGetDraw;
        (await import('../winners/winners.service.ts')).winnersService.processDrawWinners = origProcessWinners;
        withTxSpy.mockRestore();
      }
    });

    it('propagates transaction abort when winner payout calculation fails', async () => {
      const mockDraw = {
        id: 99,
        public_id: 'draw-uuid-99',
        draw_type_code: 'DAILY',
        digit_length: 3,
        sequence_number: 'DL-2026-001',
      };

      const mockClient = {
        query: mock(async (text: string) => {
          if (text.includes('FROM draw_results WHERE draw_id')) {
            return { rows: [] };
          }
          if (text.includes('INSERT INTO draw_results')) {
            return {
              rows: [{ id: 1, draw_id: 99, winning_number: '789' }],
            };
          }
          return { rows: [] };
        }),
      } as unknown as pg.PoolClient;

      const withTxSpy = spyOn(dbModule, 'withTransaction').mockImplementation(async (cb: any) => {
        return await cb(mockClient);
      });

      const origGetDraw = (await import('../draws/draws.service.ts')).drawsService.getDrawById;
      const origProcessWinners = (await import('../winners/winners.service.ts')).winnersService.processDrawWinners;
      (await import('../draws/draws.service.ts')).drawsService.getDrawById = mock(async () => mockDraw as any);
      (await import('../winners/winners.service.ts')).winnersService.processDrawWinners = mock(async () => {
        throw new Error('Simulated payout failure: ledger lock timeout');
      });

      try {
        await expect(
          resultsService.publishResult('admin-1', {
            draw_id: 99,
            winning_number: '789',
          })
        ).rejects.toThrow('Simulated payout failure: ledger lock timeout');
      } finally {
        (await import('../draws/draws.service.ts')).drawsService.getDrawById = origGetDraw;
        (await import('../winners/winners.service.ts')).winnersService.processDrawWinners = origProcessWinners;
        withTxSpy.mockRestore();
      }
    });

    it('rejects invalid winning number formats before opening a transaction', async () => {
      const mockDraw = {
        id: 1,
        draw_type_code: 'DAILY',
        digit_length: 3,
      };

      const origGetDraw = (await import('../draws/draws.service.ts')).drawsService.getDrawById;
      (await import('../draws/draws.service.ts')).drawsService.getDrawById = mock(async () => mockDraw as any);

      let txCalled = false;
      const withTxSpy = spyOn(dbModule, 'withTransaction').mockImplementation(async (cb: any) => {
        txCalled = true;
        return await cb({} as any);
      });

      try {
        await expect(
          resultsService.publishResult('admin-1', {
            draw_id: 1,
            winning_number: '12a',
          })
        ).rejects.toThrow('Winning number must contain digits only');

        await expect(
          resultsService.publishResult('admin-1', {
            draw_id: 1,
            winning_number: '12',
          })
        ).rejects.toThrow('Winning number must be exactly 3 digits');

        expect(txCalled).toBe(false);
      } finally {
        (await import('../draws/draws.service.ts')).drawsService.getDrawById = origGetDraw;
        withTxSpy.mockRestore();
      }
    });
  });

  describe('2. WinnersService.processDrawWinners Transaction & Caching Behavior', () => {
    it('caches PRIZE_POOL account lookup and balances ledger entries to zero', async () => {
      const queries: { text: string; params?: any[] }[] = [];

      const mockClient = {
        query: mock(async (text: string, params?: any[]) => {
          queries.push({ text: text.trim(), params });

          if (text.includes('FROM draws d')) {
            return {
              rows: [{ id: 10, draw_type_id: 1, code: 'DAILY', sequence_number: 'DL-01' }],
            };
          }
          if (text.includes('FROM prize_rules')) {
            return {
              rows: [
                {
                  id: 1,
                  draw_type_id: 1,
                  name: '1st Prize',
                  match_type: 'MATCH_3',
                  prize_amount_minor: '500000',
                  priority: 1,
                  status: 'ACTIVE',
                },
              ],
            };
          }
          if (text.includes('FROM tickets')) {
            return {
              rows: [
                {
                  id: 101,
                  public_id: 't-101',
                  user_id: 'user-alpha',
                  selected_number: '777',
                  ticket_price_minor: '5000',
                },
                {
                  id: 102,
                  public_id: 't-102',
                  user_id: 'user-beta',
                  selected_number: '777',
                  ticket_price_minor: '5000',
                },
              ],
            };
          }
          if (text.includes("FROM ledger_accounts WHERE account_type = 'PRIZE_POOL'")) {
            return { rows: [{ id: 999 }] };
          }
          if (text.includes("FROM ledger_accounts WHERE owner_id = $1 AND account_type = 'USER_AVAILABLE'")) {
            return { rows: [{ id: params?.[0] === 'user-alpha' ? 501 : 502 }] };
          }
          if (text.includes('FROM winners WHERE ticket_id = $1')) {
            return { rows: [] };
          }
          if (text.includes('FROM wallets WHERE user_id = $1')) {
            return { rows: [{ id: 1, available_balance_minor: '1000' }] };
          }
          if (text.includes('INSERT INTO ledger_transactions')) {
            return { rows: [{ id: 7001 }] };
          }
          if (text.includes('INSERT INTO winners')) {
            return {
              rows: [
                {
                  id: 801,
                  public_id: 'win-uuid',
                  draw_id: 10,
                  ticket_id: params?.[1],
                  user_id: params?.[2],
                  winning_amount_minor: '500000',
                  status: 'PAID',
                },
              ],
            };
          }
          return { rows: [] };
        }),
      } as unknown as pg.PoolClient;

      const result = await winnersService.processDrawWinners(10, '777', 'admin-user', mockClient);

      expect(result.winnersCount).toBe(2);
      expect(result.totalPrizePaidMinor).toBe('1000000');

      // PRIZE_POOL lookup must be executed only ONCE (cached before loop)
      const prizePoolLookups = queries.filter((q) =>
        q.text.includes("FROM ledger_accounts WHERE account_type = 'PRIZE_POOL'")
      );
      expect(prizePoolLookups.length).toBe(1);

      // Ledger entries must balance to zero for each winner
      const ledgerEntries = queries.filter((q) => q.text.includes('INSERT INTO ledger_entries'));
      expect(ledgerEntries.length).toBe(4); // 2 entries per winner * 2 winners = 4 entries

      // Verify debit (-500000) and credit (+500000) for winner 1
      const winner1Debit = ledgerEntries[0]!.params?.[2];
      const winner1Credit = ledgerEntries[1]!.params?.[2];
      expect(BigInt(winner1Debit) + BigInt(winner1Credit)).toBe(0n);

      // Verify debit (-500000) and credit (+500000) for winner 2
      const winner2Debit = ledgerEntries[2]!.params?.[2];
      const winner2Credit = ledgerEntries[3]!.params?.[2];
      expect(BigInt(winner2Debit) + BigInt(winner2Credit)).toBe(0n);
    });
  });

  describe('3. Outbox Worker processOutboxEvents Transactional Safety', () => {
    it('acquires locks and processes events within withTransaction', async () => {
      const executedQueries: string[] = [];
      const mockClient = {
        query: mock(async (text: string) => {
          executedQueries.push(text.trim());
          if (text.includes('FOR UPDATE SKIP LOCKED')) {
            return {
              rows: [
                { id: 1, event_id: 'evt-1', event_type: 'WINNER_NOTIFIED' },
                { id: 2, event_id: 'evt-2', event_type: 'PAYOUT_COMPLETED' },
              ],
            };
          }
          return { rows: [] };
        }),
      } as unknown as pg.PoolClient;

      let withTransactionUsed = false;
      const withTxSpy = spyOn(dbModule, 'withTransaction').mockImplementation(async (cb: any) => {
        withTransactionUsed = true;
        return await cb(mockClient);
      });

      try {
        const processedCount = await processOutboxEvents();

        expect(withTransactionUsed).toBe(true);
        expect(processedCount).toBe(2);
        expect(executedQueries.some((q) => q.includes('FOR UPDATE SKIP LOCKED'))).toBe(true);
        expect(executedQueries.filter((q) => q.includes("UPDATE outbox_events SET status = 'PROCESSED'")).length).toBe(2);
      } finally {
        withTxSpy.mockRestore();
      }
    });

    it('logs structured error and returns 0 when outbox processing fails', async () => {
      const consoleErrorSpy = spyOn(console, 'error').mockImplementation(() => {});
      const withTxSpy = spyOn(dbModule, 'withTransaction').mockRejectedValue(new Error('Outbox connection failure'));

      try {
        const processedCount = await processOutboxEvents();

        expect(processedCount).toBe(0);
        expect(consoleErrorSpy).toHaveBeenCalled();
      } finally {
        consoleErrorSpy.mockRestore();
        withTxSpy.mockRestore();
      }
    });
  });
});
