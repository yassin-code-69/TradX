# Plan 001: Fix Auth Mock Bypass in Web-Admin and Implement Backend Me Endpoint

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 40c50e3..HEAD -- web-admin/src/context/AuthContext.tsx backend/src/app.ts backend/src/modules/auth/`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: MED
- **Depends on**: none
- **Category**: security
- **Planned at**: commit `40c50e3`, 2026-08-28

## Why this matters

The `AuthProvider` in `web-admin/src/context/AuthContext.tsx` currently injects a hardcoded mock `SUPER_ADMIN` session whenever a user visits without an active Supabase session. This completely bypasses authentication and authorization guards, exposing administrative UI and actions to unauthorized visitors. Furthermore, the frontend attempts to call `/api/v1/me` to enrich the session profile, but the backend lacks this endpoint, causing a silent fallback to full admin privileges. Fixing this restores strict role-based access control and enforces authentic Supabase JWT verification.

## Current state

- `web-admin/src/context/AuthContext.tsx:186-246`:
  ```tsx
  } else {
    // Provide default development admin session so all admin views can be operated
    const devAdminUser: AdminUser = {
      id: "usr_admin_super_01",
      userId: "usr_admin_super_01",
      role: "SUPER_ADMIN",
      roles: ["SUPER_ADMIN", "ADMIN", "DRAW_MANAGER", "FINANCE_ADMIN"],
      ...
    };
    setSession(devMockSession);
    setUser(devMockUser);
    setAdminUser(devAdminUser);
  }
  ```
- `web-admin/src/context/AuthContext.tsx:93`:
  ```tsx
  const backendUser = await apiClient.get<AdminUser>("/api/v1/me");
  ```
- `backend/src/app.ts`:
  Lacks `/api/v1/me` or `/api/v1/auth/me` route mapping.
- Exemplar authenticated route pattern:
  See `backend/src/modules/wallet/wallet.routes.ts:14-18` using `requireAuth` and `c.get('user')`.

## Commands you will need

| Purpose   | Command                  | Expected on success |
|-----------|--------------------------|---------------------|
| Backend Typecheck | `bunx tsc --noEmit` (in `backend/`) | exit 0, no errors |
| Backend Tests     | `bun test` (in `backend/`)          | all pass          |
| Web-Admin Lint    | `bun run lint` (in `web-admin/`)   | exit 0            |
| Web-Admin Typecheck | `bunx tsc --noEmit` (in `web-admin/`) | exit 0, no errors |

## Scope

**In scope**:
- `web-admin/src/context/AuthContext.tsx`
- `backend/src/modules/auth/auth.routes.ts` (create)
- `backend/src/app.ts`

**Out of scope**:
- Database schema changes to `profiles` or `user_roles`
- Flutter mobile app authentication flows

## Git workflow

- Branch: `advisor/001-fix-auth-mock-bypass`
- Commit message style: `fix(auth): enforce strict session validation and add me endpoint`

## Steps

### Step 1: Implement GET `/api/v1/me` endpoint in backend

Create `backend/src/modules/auth/auth.routes.ts` mounting:
```ts
import { Hono } from 'hono';
import { requireAuth } from '../../middleware/auth.ts';
import { sendSuccess } from '../../utils/response.ts';

export const authRoutes = new Hono();

authRoutes.get('/me', requireAuth, async (c) => {
  const user = c.get('user');
  return sendSuccess(c, user);
});
```
Mount `authRoutes` in `backend/src/app.ts`:
```ts
import { authRoutes } from './modules/auth/auth.routes.ts';
// ...
app.route('/api/v1', authRoutes);
```

**Verify**: `bun test` in `backend/` → passes without errors.

### Step 2: Remove mock session fallback in `web-admin/src/context/AuthContext.tsx`

In `web-admin/src/context/AuthContext.tsx`:
1. Remove lines 186-246 where `devMockSession`, `devMockUser`, and `devAdminUser` are set.
2. In the `else` branch of `if (initialSession?.user)`, explicitly set:
   ```ts
   setSession(null);
   setUser(null);
   setAdminUser(null);
   setRoles([]);
   setPermissions([]);
   ```
3. Ensure unauthenticated users are redirected to `/login` via the existing route protection effect.

**Verify**: `bun run lint` in `web-admin/` and `bunx tsc --noEmit` in `web-admin/` → exits 0.

## Test plan

- Test that visiting `/dashboard` without an active session immediately redirects to `/login`.
- Test that authenticating with valid Supabase admin credentials fetches `/api/v1/me` and sets verified roles.
- Test that logging out clears session and prevents access to `/draws`, `/finance`, and `/tickets`.

## Done criteria

- [ ] `web-admin/src/context/AuthContext.tsx` contains no hardcoded mock `SUPER_ADMIN` fallback.
- [ ] Backend provides authenticated `GET /api/v1/me` route returning current `AuthUser`.
- [ ] `bunx tsc --noEmit` in `backend/` and `web-admin/` exits 0.
- [ ] `bun run lint` in `web-admin/` exits 0.

## STOP conditions

- If `profiles` table does not contain role/permission join views.
- If `web-admin` fails to build due to missing types.

## Maintenance notes

- Any new admin route in `web-admin` must verify permissions using `hasPermission('...')` provided by `useAuth()`.
