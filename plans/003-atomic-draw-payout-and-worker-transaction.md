# Plan 003: Atomic Draw Result Publishing and Outbox Transaction Safety

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 40c50e3..HEAD -- backend/src/modules/results/results.service.ts backend/src/modules/winners/winners.service.ts backend/src/modules/worker/worker.ts`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: none
- **Category**: correctness
- **Planned at**: commit `40c50e3`, 2026-08-28

## Why this matters

1. In `results.service.ts`, `publishResult` executes multiple database mutations (updating draw to `PROCESSING`, inserting `draw_results`, calculating winners, and setting draw to `COMPLETED`) across separate, non-transactional queries. If a failure occurs during winner evaluation or payout crediting, the draw result remains recorded while tickets are partially processed, leaving the ledger in an inconsistent state and preventing retries due to duplicate key constraints.
2. In `worker.ts`, `processOutboxEvents` runs `SELECT ... FOR UPDATE SKIP LOCKED` on the root pool client without `BEGIN/COMMIT`, which immediately drops the lock and allows concurrent workers to race.

## Current state

- `backend/src/modules/results/results.service.ts:242-265`:
  ```ts
  await query("UPDATE draws SET status = 'PROCESSING' WHERE id = $1", [draw.id]);
  const resultRes = await query(insertResultSql, [...]);
  const winnerStats = await winnersService.processDrawWinners(draw.id, cleanWinningNumber, adminUserId);
  await query("UPDATE draws SET status = 'COMPLETED' WHERE id = $1", [draw.id]);
  ```
- `backend/src/modules/worker/worker.ts:3-24`:
  Executes `query(...)` with `FOR UPDATE SKIP LOCKED` without `withTransaction`.
- Exemplar transaction pattern:
  See `backend/src/modules/deposits/deposits.service.ts:341-450` using `withTransaction(async (client) => { ... })`.

## Commands you will need

| Purpose   | Command                  | Expected on success |
|-----------|--------------------------|---------------------|
| Typecheck | `bunx tsc --noEmit`       | exit 0, no errors   |
| Tests     | `bun test`               | all pass            |

## Scope

**In scope**:
- `backend/src/modules/results/results.service.ts`
- `backend/src/modules/winners/winners.service.ts`
- `backend/src/modules/worker/worker.ts`

**Out of scope**:
- Migration SQL files (tables and ledger rules are already verified)

## Git workflow

- Branch: `advisor/003-atomic-draw-payout`
- Commit message style: `fix(results): wrap draw result publishing and outbox worker in atomic transactions`

## Steps

### Step 1: Wrap `publishResult` and winner payouts in a single transactional context or batch

In `backend/src/modules/results/results.service.ts`:
1. Use `withTransaction` so that draw status transition to `COMPLETED`, insertion into `draw_results`, all winner rows, and all corresponding double-entry ledger transactions (`PRIZE_POOL` -> `USER_AVAILABLE`) commit atomically.
2. In `backend/src/modules/winners/winners.service.ts`, accept an optional `client?: pg.PoolClient` in `processDrawWinners` so queries participate in the caller's transaction.
3. Cache system ledger account lookups (`PRIZE_POOL`) once before iterating over winning tickets rather than querying `SELECT id FROM ledger_accounts WHERE account_type = 'PRIZE_POOL'` on each iteration.

**Verify**: `bun test` in `backend/` → all tests pass.

### Step 2: Fix Outbox worker lock acquisition with `withTransaction`

In `backend/src/modules/worker/worker.ts`:
Wrap the `SELECT ... FOR UPDATE SKIP LOCKED` and subsequent event processing inside `withTransaction(async (client) => { ... })`.
Add structured logging if an error occurs rather than silent `catch (err) {}`.

**Verify**: `bun test` in `backend/` → all tests pass.

## Test plan

- Test simulating a winner payout calculation failure; verify that no partial `draw_results` or unbalanced ledger transactions remain committed.
- Test successful result publication with multiple winning tickets; verify `draw_results`, `winners`, and `ledger_entries` balance to zero.

## Done criteria

- [ ] `publishResult` is wrapped in `withTransaction`.
- [ ] `processOutboxEvents` executes `FOR UPDATE SKIP LOCKED` inside `withTransaction`.
- [ ] `bunx tsc --noEmit` exits 0.
- [ ] `bun test` exits 0.

## STOP conditions

- If high ticket volumes (>50,000 per draw) cause Postgres statement timeouts inside single transactions; if so, switch to cursor-based chunking with idempotent batch checkpoints.

## Maintenance notes

- Ensure `PRIZE_POOL` system account is pre-seeded across all environments.
