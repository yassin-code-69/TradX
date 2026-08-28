import 'hono';

export interface UserProfile {
  id?: string;
  userId: string;
  publicId?: string;
  username?: string | null;
  fullName?: string | null;
  phone?: string | null;
  email?: string | null;
  avatarAssetId?: number | null;
  status?: number | string;
  kycStatus?: number | string;
  referralCode?: string | null;
  referredBy?: string | null;
  createdAt?: string;
  updatedAt?: string;
  [key: string]: any;
}

export interface AuthUser {
  id: string;
  userId: string;
  email?: string;
  phone?: string;
  username?: string;
  role: string;
  roles: string[];
  permissions: string[];
  status?: string | number;
  appMetadata?: Record<string, any>;
  userMetadata?: Record<string, any>;
  profile: UserProfile | null;
}

export type AuthenticatedUser = AuthUser;

export interface AppVariables {
  user: AuthUser;
  userId: string;
  roles: string[];
  permissions: string[];
  token: string;
}

export type AppEnv = {
  Variables: AppVariables;
};

// Augment Hono's ContextVariableMap so c.get('user') and c.set('user', ...) are strictly typed
declare module 'hono' {
  interface ContextVariableMap {
    user: AuthUser;
    userId: string;
    roles: string[];
    permissions: string[];
    token: string;
  }
}
