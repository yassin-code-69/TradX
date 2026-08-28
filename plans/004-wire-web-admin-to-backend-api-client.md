# Plan 004: Wire Web-Admin Views and Modals to Backend REST API

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 40c50e3..HEAD -- web-admin/src/components/finance/ web-admin/src/app/draws/page.tsx web-admin/src/app/results/page.tsx web-admin/src/app/tickets/page.tsx web-admin/src/lib/api/`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/001-fix-auth-mock-bypass-and-profile-endpoint.md, plans/002-unify-error-handling-and-response-envelope.md
- **Category**: architecture
- **Planned at**: commit `40c50e3`, 2026-08-28

## Why this matters

Currently, all `web-admin` views (`FinanceView`, `ApproveDepositModal`, `DrawsPage`, `ResultsPage`, `TicketsPage`) perform state mutations directly on in-memory Zustand client mock stores (`useAdminStore`, `useLotteryStore`) with `setTimeout` delays rather than making authenticated HTTP requests to the backend REST API. As a result, actions performed in the admin panel do not persist to Postgres or trigger backend double-entry ledger records.

## Current state

- `web-admin/src/components/finance/ApproveDepositModal.tsx:37-51`:
  ```tsx
  const handleApprove = () => {
    setLoading(true);
    setTimeout(() => {
      approveDeposit(deposit.id, adminNote);
      setLoading(false);
      ...
    }, 400);
  };
  ```
- Backend REST API endpoints are already available:
  - `POST /api/v1/admin/deposits/:id/approve`
  - `POST /api/v1/admin/deposits/:id/reject`
  - `POST /api/v1/admin/withdrawals/:id/approve`
  - `POST /api/v1/admin/withdrawals/:id/reject`
  - `POST /api/v1/admin/wallet/adjust`
  - `POST /api/v1/admin/draws`
  - `POST /api/v1/admin/results/publish`

## Commands you will need

| Purpose   | Command                  | Expected on success |
|-----------|--------------------------|---------------------|
| Lint      | `bun run lint` (in `web-admin/`)   | exit 0            |
| Typecheck | `bunx tsc --noEmit` (in `web-admin/`) | exit 0, no errors |

## Scope

**In scope**:
- `web-admin/src/lib/api/` (API hook functions or queries)
- `web-admin/src/components/finance/ApproveDepositModal.tsx`
- `web-admin/src/components/finance/RejectDepositModal.tsx`
- `web-admin/src/components/finance/ApproveWithdrawalModal.tsx`
- `web-admin/src/components/finance/RejectWithdrawalModal.tsx`
- `web-admin/src/components/finance/AdminAdjustBalanceModal.tsx`
- `web-admin/src/app/results/page.tsx`
- `web-admin/src/app/draws/page.tsx`

**Out of scope**:
- Changes to backend database schema

## Git workflow

- Branch: `advisor/004-wire-web-admin-api`
- Commit message style: `feat(admin): connect finance and lottery operations to backend REST endpoints`

## Steps

### Step 1: Create TanStack Query mutation / fetch hooks for Admin operations

Under `web-admin/src/lib/api/`:
Create hooks/functions using `apiClient`:
- `useApproveDeposit()` -> calls `POST /api/v1/admin/deposits/${id}/approve`
- `useRejectDeposit()` -> calls `POST /api/v1/admin/deposits/${id}/reject`
- `useApproveWithdrawal()` -> calls `POST /api/v1/admin/withdrawals/${id}/approve`
- `useRejectWithdrawal()` -> calls `POST /api/v1/admin/withdrawals/${id}/reject`
- `useAdminAdjustBalance()` -> calls `POST /api/v1/admin/wallet/adjust`
- `usePublishResult()` -> calls `POST /api/v1/admin/results/publish`
- `useCreateDraw()` -> calls `POST /api/v1/admin/draws`

### Step 2: Replace Zustand mock calls in modals and pages

In `ApproveDepositModal.tsx`, `RejectDepositModal.tsx`, `ApproveWithdrawalModal.tsx`, `RejectWithdrawalModal.tsx`, `AdminAdjustBalanceModal.tsx`, `DrawsPage.tsx`, and `ResultsPage.tsx`:
Replace `setTimeout` and `useAdminStore` / `useLotteryStore` local mutations with TanStack Query mutations that invalidate corresponding query keys on success.

**Verify**: `bun run lint` in `web-admin/` and `bunx tsc --noEmit` in `web-admin/` → exits 0.

## Test plan

- Test approving a pending deposit from the admin dashboard; verify backend receives the request, updates the database, and returns HTTP 200.
- Test publishing a draw result; verify result is created in database and UI receives the updated state.

## Done criteria

- [ ] Modals in `web-admin/src/components/finance/` invoke `apiClient` instead of `setTimeout`.
- [ ] Draw creation and result publishing send requests to `/api/v1/admin/*`.
- [ ] `bun run lint` in `web-admin/` exits 0 with 0 errors.
- [ ] `bunx tsc --noEmit` in `web-admin/` exits 0.

## STOP conditions

- If backend endpoints return 401/403 due to missing admin token; verify `apiClient` Bearer token header injection in `client.ts:66-71`.

## Maintenance notes

- Future admin forms should define typed Zod input contracts and TanStack Query mutations.
