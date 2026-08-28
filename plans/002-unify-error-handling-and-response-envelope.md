# Plan 002: Unify Error Handling and Standardize Response Envelopes

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 40c50e3..HEAD -- backend/src/modules/tickets/tickets.routes.ts backend/src/modules/draws/draws.routes.ts backend/src/modules/results/results.routes.ts backend/src/modules/notifications/notifications.routes.ts backend/src/middleware/errorHandler.ts`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `40c50e3`, 2026-08-28

## Why this matters

The backend has a centralized global error handler `errorHandler.ts` that maps errors (Zod validation, Postgres codes, domain `AppError`, JWT errors) into a structured JSON envelope `{ success: false, data: null, error: { code, message, details }, timestamp }`. However, multiple route files (`tickets.routes.ts`, `draws.routes.ts`, `results.routes.ts`, `notifications.routes.ts`) catch errors in local `try/catch` blocks and return non-standard shapes such as `{ success: false, error: string, code?: string }`. This obscures domain error classes (e.g. `InsufficientBalanceError` is treated as a generic 400), breaks client error parsers in `web-admin/src/lib/api/client.ts`, and strips request correlation IDs.

## Current state

- `backend/src/modules/tickets/tickets.routes.ts:60-69`:
  ```ts
  } catch (error: any) {
    return c.json(
      {
        success: false,
        error: error?.message || 'Failed to purchase tickets',
        code: 'TICKET_PURCHASE_FAILED',
      },
      400
    );
  }
  ```
- `backend/src/middleware/errorHandler.ts:90-164`:
  Standard handler expects unhandled exceptions to bubble up and maps them with HTTP status codes and typed details.
- Exemplar clean route:
  See `backend/src/modules/wallet/wallet.routes.ts` where route handlers let exceptions bubble up to `app.onError(errorHandler)` and use `sendSuccess` for returns.

## Commands you will need

| Purpose   | Command                  | Expected on success |
|-----------|--------------------------|---------------------|
| Typecheck | `bunx tsc --noEmit`       | exit 0, no errors   |
| Tests     | `bun test`               | all pass            |

## Scope

**In scope**:
- `backend/src/modules/tickets/tickets.routes.ts`
- `backend/src/modules/draws/draws.routes.ts`
- `backend/src/modules/results/results.routes.ts`
- `backend/src/modules/notifications/notifications.routes.ts`
- `backend/src/middleware/errorHandler.ts`

**Out of scope**:
- Database migrations or table schemas
- Modification of business logic in `tickets.service.ts` or `wallet.service.ts`

## Git workflow

- Branch: `advisor/002-unify-error-handling`
- Commit message style: `fix(api): standardize error responses and remove ad-hoc catch blocks`

## Steps

### Step 1: Remove ad-hoc try/catch in route handlers and standardize on `sendSuccess` / `sendError`

Refactor route handlers in:
1. `backend/src/modules/tickets/tickets.routes.ts`
2. `backend/src/modules/draws/draws.routes.ts`
3. `backend/src/modules/results/results.routes.ts`
4. `backend/src/modules/notifications/notifications.routes.ts`

Remove manual `try { ... } catch (error: any) { return c.json({ success: false, error: ... }, 400|500) }` wrappers around service calls. Let errors propagate naturally to `errorHandler.ts`. Use `sendSuccess` and `paginatedResponse` from `../../utils/response.ts` for successful responses.

**Verify**: `bun test` in `backend/` → all tests pass.

### Step 2: Ensure Postgres and Domain error mappings in `errorHandler.ts`

Confirm that `backend/src/middleware/errorHandler.ts` properly captures `AppError`, `InsufficientBalanceError`, `ConflictError`, `NotFoundError`, and Postgres constraints (`23505`, `23503`, `23502`, `22P02`).

**Verify**: `bunx tsc --noEmit` in `backend/` → exit 0.

## Test plan

- Test that an invalid ticket purchase (e.g. negative quantity or non-existent draw) returns HTTP 400 or 422 with `{ success: false, error: { code: '...', message: '...' } }`.
- Test that an unauthorized request returns HTTP 401 with standard error format.
- Test that successful requests return `{ success: true, data: ..., timestamp: '...' }`.

## Done criteria

- [ ] Zero routes in `backend/src/modules/` return raw non-standard `{ success: false, error: string }`.
- [ ] All error responses match `ApiErrorResponse` type definition.
- [ ] `bunx tsc --noEmit` exits 0.
- [ ] `bun test` exits 0.

## STOP conditions

- If an external consumer strictly requires legacy error JSON without `error.code`.

## Maintenance notes

- Future routes must follow the pattern of throwing typed errors (`BadRequestError`, `NotFoundError`, `ConflictError`) rather than returning ad-hoc error JSON.
