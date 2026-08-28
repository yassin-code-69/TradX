import type { Context, Next } from 'hono';
import jwt from 'jsonwebtoken';
import { supabaseAdmin, query } from '../db/client.ts';
import { config } from '../config/index.ts';
import { UnauthorizedError, ForbiddenError } from '../utils/response.ts';
import type { AuthUser, UserProfile } from '../types/auth.ts';

// Ensure Hono context typing is registered
export * from '../types/auth.ts';

/**
 * Helper to fetch user profile, roles, and permissions from DB
 */
async function fetchUserProfileAndPermissions(userId: string): Promise<{
  profile: UserProfile | null;
  roles: string[];
  permissions: string[];
}> {
  try {
    // 1. Fetch Profile
    const profileRes = await query<any>(
      `SELECT 
        user_id as "userId",
        public_id as "publicId",
        username,
        full_name as "fullName",
        phone,
        email,
        avatar_asset_id as "avatarAssetId",
        status,
        kyc_status as "kycStatus",
        referral_code as "referralCode",
        referred_by as "referredBy",
        created_at as "createdAt",
        updated_at as "updatedAt"
       FROM profiles 
       WHERE user_id = $1 
       LIMIT 1`,
      [userId]
    );

    const profile: UserProfile | null = profileRes.rows[0] || null;

    // 2. Fetch User Roles
    const rolesRes = await query<{ code: string }>(
      `SELECT r.code
       FROM user_roles ur
       JOIN roles r ON ur.role_id = r.id
       WHERE ur.user_id = $1`,
      [userId]
    );

    let roles = rolesRes.rows.map((row) => row.code);
    if (roles.length === 0) {
      roles = ['USER'];
    }

    // 3. Fetch User Permissions (via roles)
    const permissionsRes = await query<{ code: string }>(
      `SELECT DISTINCT p.code
       FROM user_roles ur
       JOIN role_permissions rp ON ur.role_id = rp.role_id
       JOIN permissions p ON rp.permission_id = p.id
       WHERE ur.user_id = $1`,
      [userId]
    );

    const permissions = permissionsRes.rows.map((row) => row.code);

    return { profile, roles, permissions };
  } catch {
    // Fallback: If DB query fails (e.g. offline during tests or pre-migration), return standard defaults
    return { profile: null, roles: ['USER'], permissions: [] };
  }
}

/**
 * Validate JWT access token and return verified Supabase auth payload
 */
async function verifyAccessToken(token: string): Promise<{
  id: string;
  email?: string;
  phone?: string;
  role?: string;
  app_metadata?: Record<string, any>;
  user_metadata?: Record<string, any>;
}> {
  // Option 1: Fast local verification with JWT secret if available
  const jwtSecret = config.SUPABASE_JWT_SECRET || config.jwtSecret;
  if (jwtSecret) {
    try {
      const decoded = jwt.verify(token, jwtSecret) as any;
      if (decoded && (decoded.sub || decoded.userId || decoded.id)) {
        const userId = decoded.sub || decoded.userId || decoded.id;
        return {
          id: userId,
          email: decoded.email,
          phone: decoded.phone,
          role: decoded.role || decoded.app_metadata?.role,
          app_metadata: decoded.app_metadata,
          user_metadata: decoded.user_metadata,
        };
      }
    } catch {
      // If local JWT verify fails with secret, fall through to try Supabase API or reject
    }
  }

  // Option 2: Fallback to Supabase Auth API
  try {
    const timeoutPromise = new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error('Supabase Auth timeout')), 2000)
    );

    const authPromise = supabaseAdmin.auth.getUser(token);
    const { data: { user }, error } = await Promise.race([authPromise, timeoutPromise]) as any;

    if (!error && user) {
      return {
        id: user.id,
        email: user.email,
        phone: user.phone,
        role: user.role || user.app_metadata?.role,
        app_metadata: user.app_metadata,
        user_metadata: user.user_metadata,
      };
    }
  } catch {
    // Continue to error
  }

  throw new UnauthorizedError('Invalid or expired authentication token', 'UNAUTHORIZED');
}

/**
 * Extract and authenticate user from request Context
 */
export async function authenticateToken(c: Context): Promise<AuthUser | null> {
  const authHeader = c.req.header('Authorization') || c.req.header('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  const token = authHeader.substring(7).trim();
  if (!token) {
    return null;
  }

  try {
    const authData = await verifyAccessToken(token);
    const { profile, roles, permissions } = await fetchUserProfileAndPermissions(authData.id);

    // If token has explicit role claim and DB returned default 'USER', reflect token role
    const resolvedRoles = authData.role && !roles.includes(authData.role)
      ? [authData.role, ...roles]
      : roles;

    const primaryRole = resolvedRoles[0] || 'USER';
    const statusVal = profile?.status ?? 'ACTIVE';

    const authUser: AuthUser = {
      id: authData.id,
      userId: authData.id,
      email: authData.email || profile?.email || undefined,
      phone: authData.phone || profile?.phone || undefined,
      username: profile?.username || authData.user_metadata?.username || `user_${authData.id.slice(0, 8)}`,
      role: primaryRole,
      roles: resolvedRoles,
      permissions,
      status: statusVal,
      appMetadata: authData.app_metadata,
      userMetadata: authData.user_metadata,
      profile,
    };

    return authUser;
  } catch {
    return null;
  }
}

/**
 * Require Authentication Middleware
 * Validates Bearer token, fetches user profile & roles, and attaches them to Context.
 */
export async function requireAuth(c: Context, next: Next) {
  const authHeader = c.req.header('Authorization') || c.req.header('authorization');

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new UnauthorizedError('Missing or malformed Authorization header', 'UNAUTHORIZED');
  }

  const token = authHeader.substring(7).trim();
  if (!token) {
    throw new UnauthorizedError('Bearer token is required', 'UNAUTHORIZED');
  }

  const authData = await verifyAccessToken(token);
  const { profile, roles, permissions } = await fetchUserProfileAndPermissions(authData.id);

  // Check account status if profile exists
  if (profile) {
    const status = profile.status;
    if (status === 2 || status === 'SUSPENDED') {
      throw new ForbiddenError('Account is currently suspended', 'ACCOUNT_SUSPENDED');
    }
    if (status === 3 || status === 'BLOCKED' || status === 4 || status === 'CLOSED') {
      throw new ForbiddenError('Account is blocked or closed', 'ACCOUNT_BLOCKED');
    }
  }

  const resolvedRoles = authData.role && !roles.includes(authData.role)
    ? [authData.role, ...roles]
    : roles;

  const primaryRole = resolvedRoles[0] || 'USER';
  const statusVal = profile?.status ?? 'ACTIVE';

  const authUser: AuthUser = {
    id: authData.id,
    userId: authData.id,
    email: authData.email || profile?.email || undefined,
    phone: authData.phone || profile?.phone || undefined,
    username: profile?.username || authData.user_metadata?.username || `user_${authData.id.slice(0, 8)}`,
    role: primaryRole,
    roles: resolvedRoles,
    permissions,
    status: statusVal,
    appMetadata: authData.app_metadata,
    userMetadata: authData.user_metadata,
    profile,
  };

  // Set Hono Context variables
  c.set('user', authUser);
  c.set('userId', authUser.id);
  c.set('roles', resolvedRoles);
  c.set('permissions', permissions);
  c.set('token', token);

  await next();
}

/**
 * Require Admin Middleware (shorthand for admin check)
 */
export async function requireAdmin(c: Context, next: Next) {
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
    throw new UnauthorizedError('Authentication required to access admin resources', 'AUTH_REQUIRED');
  }

  const roles = user.roles || [];
  const isAdmin = roles.includes('SUPER_ADMIN') || roles.includes('ADMIN') || roles.includes('FINANCE_ADMIN');
  if (!isAdmin) {
    throw new ForbiddenError('Admin privileges required', 'FORBIDDEN_ROLE', {
      requiredRoles: ['SUPER_ADMIN', 'ADMIN', 'FINANCE_ADMIN'],
      userRoles: roles,
    });
  }

  await next();
}

/**
 * Optional Authentication Middleware
 * If token is present, verifies it and populates context without failing if not provided.
 */
export async function optionalAuth(c: Context, next: Next) {
  const user = await authenticateToken(c);
  if (user) {
    c.set('user', user);
    c.set('userId', user.id);
    c.set('roles', user.roles);
    c.set('permissions', user.permissions);
  }
  await next();
}

/**
 * Convenience helper to extract authenticated user from context
 */
export function getAuthUser(c: Context): AuthUser {
  const user = c.get('user');
  if (!user) {
    throw new UnauthorizedError('User is not authenticated', 'AUTH_REQUIRED');
  }
  return user;
}

/**
 * Convenience helper to extract authenticated user ID from context
 */
export function getUserId(c: Context): string {
  const userId = c.get('userId') || (c.get('user') as AuthUser | undefined)?.id;
  if (!userId) {
    throw new UnauthorizedError('User ID is not present in context', 'AUTH_REQUIRED');
  }
  return userId;
}
