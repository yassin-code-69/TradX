import type { Context, Next } from 'hono';
import { ForbiddenError, UnauthorizedError } from '../utils/response.ts';
import type { AuthUser } from '../types/auth.ts';
import { authenticateToken } from './auth.ts';

export const SUPER_ADMIN_ROLE = 'SUPER_ADMIN';

/**
 * Check if an AuthUser has any of the given roles.
 * Returns true if the user possesses SUPER_ADMIN role.
 */
export function hasRole(user: AuthUser | undefined | null, requiredRoles: string | string[]): boolean {
  if (!user || !user.roles) return false;

  const targetRoles = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];
  if (user.roles.includes(SUPER_ADMIN_ROLE)) {
    return true;
  }

  return targetRoles.some((role) => user.roles.includes(role));
}

/**
 * Check if an AuthUser has any of the given permissions.
 * Returns true if the user possesses SUPER_ADMIN role.
 */
export function hasPermission(user: AuthUser | undefined | null, requiredPermissions: string | string[]): boolean {
  if (!user) return false;

  if (user.roles && user.roles.includes(SUPER_ADMIN_ROLE)) {
    return true;
  }

  if (!user.permissions) return false;

  const targetPermissions = Array.isArray(requiredPermissions) ? requiredPermissions : [requiredPermissions];
  return targetPermissions.some((perm) => user.permissions.includes(perm));
}

/**
 * Middleware requiring the authenticated user to possess at least ONE of the specified roles.
 * Supports string array, single string, or rest parameters.
 * (SUPER_ADMIN always satisfies the requirement).
 *
 * @example
 * app.get('/admin/draws', requireAuth, requireRole(['SUPER_ADMIN', 'DRAW_MANAGER']), handler)
 * app.get('/admin/draws', requireAuth, requireRole('SUPER_ADMIN', 'DRAW_MANAGER'), handler)
 */
export function requireRole(...allowedRoles: (string | string[])[]) {
  const flattenedRoles = allowedRoles.flat();

  return async (c: Context, next: Next) => {
    let user: AuthUser | undefined = c.get('user');
    if (!user) {
      const authed = await authenticateToken(c);
      if (authed) {
        user = authed;
        c.set('user', user);
        c.set('userId', user.id);
        c.set('roles', user.roles);
        c.set('permissions', user.permissions);
      }
    }

    if (!user) {
      throw new UnauthorizedError('Authentication required to access this resource', 'AUTH_REQUIRED');
    }

    const contextRoles = (c.get('roles') as string[] | undefined) || user.roles || [];
    const isSuperAdmin = contextRoles.includes(SUPER_ADMIN_ROLE);
    const hasAllowedRole = isSuperAdmin || flattenedRoles.some((role) => contextRoles.includes(role));

    if (!hasAllowedRole) {
      throw new ForbiddenError(
        `Forbidden: requires one of the following roles: [${flattenedRoles.join(', ')}]`,
        'FORBIDDEN_ROLE',
        { requiredRoles: flattenedRoles, userRoles: contextRoles }
      );
    }

    await next();
  };
}

/**
 * Middleware requiring the authenticated user to possess ALL of the specified roles.
 */
export function requireAllRoles(requiredRoles: string[]) {
  return async (c: Context, next: Next) => {
    let user: AuthUser | undefined = c.get('user');
    if (!user) {
      const authed = await authenticateToken(c);
      if (authed) {
        user = authed;
        c.set('user', user);
        c.set('userId', user.id);
        c.set('roles', user.roles);
        c.set('permissions', user.permissions);
      }
    }

    if (!user) {
      throw new UnauthorizedError('Authentication required to access this resource', 'AUTH_REQUIRED');
    }

    const contextRoles = (c.get('roles') as string[] | undefined) || user.roles || [];
    const isSuperAdmin = contextRoles.includes(SUPER_ADMIN_ROLE);
    const hasAllRoles = isSuperAdmin || requiredRoles.every((role) => contextRoles.includes(role));

    if (!hasAllRoles) {
      throw new ForbiddenError(
        `Forbidden: requires all of the following roles: [${requiredRoles.join(', ')}]`,
        'FORBIDDEN_ROLE',
        { requiredRoles, userRoles: contextRoles }
      );
    }

    await next();
  };
}

/**
 * Middleware requiring the authenticated user to possess at least ONE of the specified permissions.
 * (SUPER_ADMIN always satisfies the requirement).
 *
 * @example
 * app.post('/admin/draws', requireAuth, requirePermission('draw.create'), handler)
 */
export function requirePermission(...requiredPermissions: (string | string[])[]) {
  const flattenedPermissions = requiredPermissions.flat();

  return async (c: Context, next: Next) => {
    let user: AuthUser | undefined = c.get('user');
    if (!user) {
      const authed = await authenticateToken(c);
      if (authed) {
        user = authed;
        c.set('user', user);
        c.set('userId', user.id);
        c.set('roles', user.roles);
        c.set('permissions', user.permissions);
      }
    }

    if (!user) {
      throw new UnauthorizedError('Authentication required to access this resource', 'AUTH_REQUIRED');
    }

    const contextRoles = (c.get('roles') as string[] | undefined) || user.roles || [];
    const contextPermissions = (c.get('permissions') as string[] | undefined) || user.permissions || [];

    const isSuperAdmin = contextRoles.includes(SUPER_ADMIN_ROLE);
    const hasAllowedPermission = isSuperAdmin || flattenedPermissions.some((perm) => contextPermissions.includes(perm));

    if (!hasAllowedPermission) {
      throw new ForbiddenError(
        `Forbidden: requires one of the following permissions: [${flattenedPermissions.join(', ')}]`,
        'FORBIDDEN_PERMISSION',
        { requiredPermissions: flattenedPermissions, userPermissions: contextPermissions }
      );
    }

    await next();
  };
}

/**
 * Middleware requiring the authenticated user to possess ALL of the specified permissions.
 */
export function requireAllPermissions(requiredPermissions: string[]) {
  return async (c: Context, next: Next) => {
    let user: AuthUser | undefined = c.get('user');
    if (!user) {
      const authed = await authenticateToken(c);
      if (authed) {
        user = authed;
        c.set('user', user);
        c.set('userId', user.id);
        c.set('roles', user.roles);
        c.set('permissions', user.permissions);
      }
    }

    if (!user) {
      throw new UnauthorizedError('Authentication required to access this resource', 'AUTH_REQUIRED');
    }

    const contextRoles = (c.get('roles') as string[] | undefined) || user.roles || [];
    const contextPermissions = (c.get('permissions') as string[] | undefined) || user.permissions || [];

    const isSuperAdmin = contextRoles.includes(SUPER_ADMIN_ROLE);
    const hasAll = isSuperAdmin || requiredPermissions.every((perm) => contextPermissions.includes(perm));

    if (!hasAll) {
      throw new ForbiddenError(
        `Forbidden: requires all of the following permissions: [${requiredPermissions.join(', ')}]`,
        'FORBIDDEN_PERMISSION',
        { requiredPermissions, userPermissions: contextPermissions }
      );
    }

    await next();
  };
}
