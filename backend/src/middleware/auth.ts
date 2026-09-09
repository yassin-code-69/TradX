import type { Context, Next } from 'hono';
import jwt from 'jsonwebtoken';
import { supabaseAdmin, supabaseAnon, query } from '../db/client.ts';
import { config } from '../config/index.ts';
import { UnauthorizedError, ForbiddenError } from '../utils/response.ts';
import type { AuthUser, UserProfile } from '../types/auth.ts';

// Ensure Hono context typing is registered
export * from '../types/auth.ts';

/**
 * Standard deterministic role permissions mapping
 */
const ROLE_PERMISSIONS_MAP: Record<string, string[]> = {
  SUPER_ADMIN: [
    'dashboard.view',
    'users.view', 'users.manage', 'users.block', 'kyc.view', 'kyc.review',
    'deposits.view', 'deposits.approve', 'deposits.reject',
    'withdrawals.view', 'withdrawals.approve', 'withdrawals.reject',
    'wallet.view', 'wallet.adjust', 'wallet.transfer',
    'draws.view', 'draws.create', 'draws.manage', 'draws.execute', 'draws.open', 'draws.close',
    'tickets.view', 'tickets.purchase',
    'results.view', 'results.publish', 'winners.view', 'winners.process',
    'settings.view', 'settings.manage', 'admins.manage', 'roles.manage',
    'audit.view', 'reports.view'
  ],
  ADMIN: [
    'dashboard.view',
    'users.view', 'users.manage', 'users.block', 'kyc.view', 'kyc.review',
    'deposits.view', 'deposits.approve', 'deposits.reject',
    'withdrawals.view', 'withdrawals.approve', 'withdrawals.reject',
    'wallet.view', 'wallet.adjust',
    'draws.view', 'draws.create', 'draws.manage', 'tickets.view',
    'results.view', 'winners.view', 'settings.view', 'audit.view', 'reports.view'
  ],
  FINANCE_ADMIN: [
    'dashboard.view',
    'deposits.view', 'deposits.approve', 'deposits.reject',
    'withdrawals.view', 'withdrawals.approve', 'withdrawals.reject',
    'wallet.view', 'wallet.adjust', 'reports.view', 'audit.view',
    'settings.view', 'settings.manage'
  ],
  DRAW_MANAGER: [
    'draws.view', 'draws.create', 'draws.manage', 'draws.execute',
    'tickets.view', 'results.view', 'results.publish', 'winners.view', 'winners.process'
  ],
  SUPPORT: [
    'users.view', 'kyc.view', 'kyc.review', 'tickets.view', 'deposits.view', 'withdrawals.view'
  ],
  AGENT: [
    'wallet.transfer', 'tickets.purchase', 'draws.view', 'tickets.view', 'results.view'
  ],
  CUSTOMER: [
    'tickets.purchase', 'wallet.transfer', 'draws.view', 'tickets.view', 'results.view'
  ],
  USER: [
    'tickets.purchase', 'wallet.transfer', 'draws.view', 'tickets.view', 'results.view'
  ]
};

export function resolveRolePermissions(roles: string[]): string[] {
  const permSet = new Set<string>();
  for (const role of roles) {
    const perms = ROLE_PERMISSIONS_MAP[role] || [];
    for (const p of perms) {
      permSet.add(p);
    }
  }
  if (roles.includes('SUPER_ADMIN')) {
    for (const perms of Object.values(ROLE_PERMISSIONS_MAP)) {
      for (const p of perms) {
        permSet.add(p);
      }
    }
  }
  return Array.from(permSet);
}

/**
 * Helper to fetch user profile, roles, and permissions from DB
 */
async function fetchUserProfileAndPermissions(userId: string): Promise<{
  profile: UserProfile | null;
  roles: string[];
  permissions: string[];
}> {
  try {
    // 1. Fetch Profile (handling multiple schema variants: user_id, auth_user_id, id)
    let profile: UserProfile | null = null;
    try {
      const profileRes = await query<any>(
        `SELECT 
          id,
          COALESCE(auth_user_id, id) as "userId",
          COALESCE(public_id::text, id) as "publicId",
          COALESCE(username, email) as "username",
          COALESCE(full_name, name) as "fullName",
          phone,
          email,
          avatar_asset_id as "avatarAssetId",
          avatar_url as "avatarUrl",
          status,
          kyc_status as "kycStatus",
          referral_code as "referralCode",
          referred_by as "referredBy",
          is_admin as "isAdmin",
          created_at as "createdAt",
          updated_at as "updatedAt"
         FROM profiles 
         WHERE auth_user_id = $1 OR id = $1
         LIMIT 1`,
        [userId]
      );
      if (profileRes.rows.length > 0) {
        profile = profileRes.rows[0];
      }
    } catch {
      // Try fallback query with user_id column if auth_user_id does not exist
      try {
        const fallbackRes = await query<any>(
          `SELECT 
            user_id as "userId",
            public_id as "publicId",
            username,
            full_name as "fullName",
            phone,
            email,
            status,
            kyc_status as "kycStatus",
            created_at as "createdAt",
            updated_at as "updatedAt"
           FROM profiles 
           WHERE user_id = $1 
           LIMIT 1`,
          [userId]
        );
        if (fallbackRes.rows.length > 0) {
          profile = fallbackRes.rows[0];
        }
      } catch {
        // Ignore fallback query error
      }
    }

    // If pool queries failed or returned null, query via Supabase Admin Client
    if (!profile) {
      try {
        const { data: pData } = await supabaseAdmin
          .from('profiles')
          .select('*')
          .or(`user_id.eq.${userId},id.eq.${userId}`)
          .maybeSingle();
        if (pData) {
          profile = {
            id: pData.id || pData.user_id,
            userId: pData.user_id || pData.id,
            publicId: pData.public_id || pData.id,
            username: pData.username || pData.display_name,
            fullName: pData.full_name || pData.name,
            email: pData.email,
            status: pData.status || 'ACTIVE',
            kycStatus: pData.kyc_status || 'NOT_SUBMITTED',
            createdAt: pData.created_at,
            updatedAt: pData.updated_at,
          };
        }
      } catch {
        // Ignore Supabase fallback error
      }
    }

    // 2. Fetch User Roles
    const profileId = profile?.id || userId;
    let roles: string[] = [];

    try {
      const rolesRes = await query<{ role_code?: string; code?: string; role?: string }>(
        `SELECT COALESCE(ur.role, r.code) as code
         FROM user_roles ur
         LEFT JOIN roles r ON ur.role_id = r.id
         WHERE ur.user_id = $1 OR ur.user_id = $2`,
        [userId, profileId]
      );
      roles = rolesRes.rows.map((row) => row.code || row.role_code || row.role).filter(Boolean) as string[];
    } catch {
      // If user_roles pool query fails, query via Supabase Admin
      try {
        const { data: urData } = await supabaseAdmin
          .from('user_roles')
          .select('role')
          .eq('user_id', userId);
        if (urData && urData.length > 0) {
          roles = urData.map((r: any) => r.role === 'admin' ? 'ADMIN' : r.role.toUpperCase());
        }
      } catch {
        // Ignore fallback error
      }
    }

    if (roles.length === 0) {
      if (profile?.isAdmin || profile?.is_admin || (profile?.role && profile.role.includes('Admin'))) {
        roles = ['SUPER_ADMIN', 'ADMIN'];
      } else {
        roles = ['USER'];
      }
    }

    // 3. Fetch or resolve User Permissions
    let permissions: string[] = [];
    try {
      const permissionsRes = await query<{ code: string }>(
        `SELECT DISTINCT p.code
         FROM user_roles ur
         JOIN role_permissions rp ON ur.role_id = rp.role_id
         JOIN permissions p ON rp.permission_id = p.id
         WHERE ur.user_id = $1 OR ur.user_id = $2`,
        [userId, profileId]
      );
      permissions = permissionsRes.rows.map((row) => row.code);
    } catch {
      // If permissions table not present, resolve via deterministic map
    }

    if (permissions.length === 0) {
      permissions = resolveRolePermissions(roles);
    }

    return { profile, roles, permissions };
  } catch {
    // Fallback: If DB query fails, return standard defaults
    return { profile: null, roles: ['USER'], permissions: resolveRolePermissions(['USER']) };
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

  // Option 2: Verify against Supabase Auth API
  try {
    const timeoutPromise = new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error('Supabase Auth timeout')), 3500)
    );

    const authPromise = supabaseAnon.auth.getUser(token);
    const { data: { user }, error } = (await Promise.race([authPromise, timeoutPromise])) as any;

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
    // Continue to next check
  }

  try {
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);
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

    // Extract authoritative app_metadata roles
    const tokenRoles = (authData.app_metadata?.roles as string[]) || 
                       (authData.app_metadata?.role ? [authData.app_metadata.role] : []);
    
    const normalizedTokenRoles = tokenRoles.map(r => r === 'admin' ? 'ADMIN' : r);
    const normalizedDbRoles = roles.map(r => r === 'admin' ? 'ADMIN' : r);

    const ROLE_PRIORITY = ['SUPER_ADMIN', 'ADMIN', 'FINANCE_ADMIN', 'DRAW_MANAGER', 'SUPPORT', 'AGENT', 'CUSTOMER', 'USER'];
    const mergedRoles = Array.from(new Set([...normalizedTokenRoles, ...normalizedDbRoles]))
      .sort((a, b) => {
        const idxA = ROLE_PRIORITY.indexOf(a);
        const idxB = ROLE_PRIORITY.indexOf(b);
        return (idxA === -1 ? 99 : idxA) - (idxB === -1 ? 99 : idxB);
      });

    const resolvedRoles = mergedRoles.length > 0 ? mergedRoles : ['USER'];
    const resolvedPermissions = resolveRolePermissions(resolvedRoles);

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
      permissions: resolvedPermissions,
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

  // Extract authoritative app_metadata roles
  const tokenRoles = (authData.app_metadata?.roles as string[]) || 
                     (authData.app_metadata?.role ? [authData.app_metadata.role] : []);
  
  const normalizedTokenRoles = tokenRoles.map(r => r === 'admin' ? 'ADMIN' : r);
  const normalizedDbRoles = roles.map(r => r === 'admin' ? 'ADMIN' : r);

  const ROLE_PRIORITY = ['SUPER_ADMIN', 'ADMIN', 'FINANCE_ADMIN', 'DRAW_MANAGER', 'SUPPORT', 'AGENT', 'CUSTOMER', 'USER'];
  const mergedRoles = Array.from(new Set([...normalizedTokenRoles, ...normalizedDbRoles]))
    .sort((a, b) => {
      const idxA = ROLE_PRIORITY.indexOf(a);
      const idxB = ROLE_PRIORITY.indexOf(b);
      return (idxA === -1 ? 99 : idxA) - (idxB === -1 ? 99 : idxB);
    });

  const resolvedRoles = mergedRoles.length > 0 ? mergedRoles : ['USER'];
  const resolvedPermissions = resolveRolePermissions(resolvedRoles);

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
    permissions: resolvedPermissions,
    status: statusVal,
    appMetadata: authData.app_metadata,
    userMetadata: authData.user_metadata,
    profile,
  };

  // Set Hono Context variables
  c.set('user', authUser);
  c.set('userId', authUser.id);
  c.set('roles', resolvedRoles);
  c.set('permissions', resolvedPermissions);
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
