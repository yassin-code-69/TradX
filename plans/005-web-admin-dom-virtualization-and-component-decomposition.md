# Plan 005: Web-Admin DOM Virtualization and Monolithic View Decomposition

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 40c50e3..HEAD -- web-admin/src/components/finance/FinanceView.tsx web-admin/src/app/draws/page.tsx web-admin/src/app/tickets/page.tsx web-admin/src/app/results/page.tsx web-admin/src/components/users/UsersView.tsx`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: none
- **Category**: perf
- **Planned at**: commit `40c50e3`, 2026-08-28

## Why this matters

The primary administrative views in `web-admin` are monolithic single-file components (`FinanceView.tsx` 1,177 LOC, `draws/page.tsx` 1,348 LOC, `results/page.tsx` 1,214 LOC, `tickets/page.tsx` 916 LOC). In each of these, extensive data tables render thousands of unbounded DOM nodes inside `<ScrollArea>` or `<Table.Tbody>` without virtualization or server pagination. Furthermore, input state changes (e.g. typing in search bars) trigger cascading full-tree re-renders of all tabs and modals simultaneously. Virtualizing table rows and decomposing tabs into discrete sub-components eliminates main-thread UI jank, lowers memory consumption, and accelerates rendering.

## Current state

- `web-admin/src/app/tickets/page.tsx:70-130`:
  Renders entire filtered array of tickets directly into DOM `<Table.Tr>` elements.
- `web-admin/src/components/finance/FinanceView.tsx`:
  Contains all 4 tabs (Deposits, Withdrawals, Transfers, Ledger) and 6 modal triggers inside one top-level component, causing state updates in one tab to re-render all others.
- Biome warnings:
  Multiple `any` assertions in `draws/page.tsx:188,513,1007` and `settings/page.tsx:121,226,993`.

## Commands you will need

| Purpose   | Command                  | Expected on success |
|-----------|--------------------------|---------------------|
| Lint      | `bun run lint` (in `web-admin/`)   | exit 0, 0 warnings |
| Typecheck | `bunx tsc --noEmit` (in `web-admin/`) | exit 0, no errors |

## Scope

**In scope**:
- `web-admin/src/components/finance/FinanceView.tsx` (and newly extracted tab components)
- `web-admin/src/app/tickets/page.tsx`
- `web-admin/src/app/draws/page.tsx`
- `web-admin/src/app/results/page.tsx`
- `web-admin/src/components/users/UsersView.tsx`

**Out of scope**:
- Backend API endpoints

## Git workflow

- Branch: `advisor/005-dom-virtualization-and-decomposition`
- Commit message style: `perf(web-admin): decompose monolithic views and add table pagination and row windowing`

## Steps

### Step 1: Decompose `FinanceView.tsx` into dedicated tab components

Split `FinanceView.tsx` into:
- `web-admin/src/components/finance/tabs/DepositsTab.tsx`
- `web-admin/src/components/finance/tabs/WithdrawalsTab.tsx`
- `web-admin/src/components/finance/tabs/TransfersTab.tsx`
- `web-admin/src/components/finance/tabs/LedgerTab.tsx`

Co-locate search and filter state within each respective tab component so typing in the deposits search bar does not trigger re-renders in the withdrawals or transfers tabs.

### Step 2: Implement table pagination / virtualization for Tickets and Finance lists

In `web-admin/src/app/tickets/page.tsx` and `FinanceView` tabs:
1. Add Mantine `<Pagination>` controls or windowing with a default page size of 25/50 rows.
2. Ensure only active visible rows are rendered to the DOM at any given moment.
3. Clean up `any` casts in event handlers to resolve all Biome lint warnings.

**Verify**: `bun run lint` in `web-admin/` → exits 0 with 0 warnings.

## Test plan

- Test searching across 1,000+ items; verify typing response is instantaneous without frame drops.
- Test tab switching in `FinanceView`; verify memory remains stable and modal states operate cleanly.

## Done criteria

- [ ] `FinanceView.tsx` reduced to a clean tab orchestration shell (<250 LOC).
- [ ] Table rows are paginated / capped per render frame across all admin views.
- [ ] `bun run lint` in `web-admin/` exits 0 with 0 warnings.
- [ ] `bunx tsc --noEmit` in `web-admin/` exits 0.

## STOP conditions

- If Mantine theme styles or tab active states break during decomposition.

## Maintenance notes

- Any future table in `web-admin` should default to paginated rendering or virtualized windowing.
