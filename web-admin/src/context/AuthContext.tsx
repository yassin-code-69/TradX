"use client";

import { Center, Loader, Stack, Text } from "@mantine/core";
import type { Session, User } from "@supabase/supabase-js";
import { usePathname, useRouter } from "next/navigation";
import type React from "react";
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { apiClient } from "@/lib/api/client";
import { supabase } from "@/lib/supabase/client";

export const SUPER_ADMIN_ROLE = "SUPER_ADMIN";

export const DEFAULT_ADMIN_ROLES = [
  SUPER_ADMIN_ROLE,
  "ADMIN",
  "FINANCE_ADMIN",
  "DRAW_MANAGER",
  "SUPPORT",
  "AGENT",
];

export const FULL_ADMIN_PERMISSIONS: string[] = [
  "dashboard.view",
  "draw.view",
  "draw.create",
  "draw.update",
  "draw.open",
  "draw.close",
  "draw.execute",
  "tickets.view",
  "result.view",
  "result.publish",
  "wallet.view",
  "deposit.view",
  "deposit.approve",
  "deposit.reject",
  "withdraw.view",
  "withdraw.approve",
  "withdraw.reject",
  "transfer.view",
  "users.view",
  "users.update",
  "users.block",
  "settings.manage",
  "admins.manage",
  "roles.manage",
  "reports.view",
];

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
}

export interface AdminUser {
  id: string;
  userId: string;
  email?: string;
  phone?: string;
  username?: string;
  role: string;
  roles: string[];
  permissions: string[];
  status?: string | number;
  profile: UserProfile | null;
  appMetadata?: Record<string, unknown>;
  userMetadata?: Record<string, unknown>;
}

export interface AuthContextType {
  session: Session | null;
  user: User | null;
  adminUser: AdminUser | null;
  roles: string[];
  permissions: string[];
  isLoading: boolean;
  isAuthenticated: boolean;
  isAdmin: boolean;
  login: (email: string, password: string) => Promise<{ error: Error | null }>;
  logout: () => Promise<void>;
  hasRole: (requiredRoles: string | string[]) => boolean;
  hasPermission: (requiredPermissions: string | string[]) => boolean;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

/**
 * Extract project ref from configured Supabase URL
 */
const SUPABASE_PROJECT_REF = (() => {
  const url =
    process.env.NEXT_PUBLIC_SUPABASE_URL ||
    "https://mqrtqldebapvllidkcgs.supabase.co";
  try {
    const hostname = new URL(url).hostname;
    return hostname.split(".")[0] || "mqrtqldebapvllidkcgs";
  } catch {
    return "mqrtqldebapvllidkcgs";
  }
})();

/**
 * Sync Supabase authentication session to HTTP cookies for Edge Middleware route guards
 */
export function syncAuthCookies(session: Session | null) {
  if (typeof document === "undefined") return;

  const cookieNames = [
    `sb-${SUPABASE_PROJECT_REF}-auth-token`,
    "sb-access-token",
    "auth_token",
  ];

  if (session?.access_token) {
    const sessionJson = encodeURIComponent(JSON.stringify(session));
    const maxAge = 60 * 60 * 24 * 7; // 7 days
    // biome-ignore lint/suspicious/noDocumentCookie: Synchronize auth token cookies for Next.js Edge Middleware
    document.cookie = `sb-${SUPABASE_PROJECT_REF}-auth-token=${sessionJson}; path=/; max-age=${maxAge}; SameSite=Lax`;
    // biome-ignore lint/suspicious/noDocumentCookie: Synchronize auth token cookies for Next.js Edge Middleware
    document.cookie = `sb-access-token=${session.access_token}; path=/; max-age=${maxAge}; SameSite=Lax`;
  } else {
    for (const name of cookieNames) {
      // biome-ignore lint/suspicious/noDocumentCookie: Clear auth token cookies on signout
      document.cookie = `${name}=; path=/; max-age=0; SameSite=Lax`;
    }
  }
}

/**
 * Strictly extract valid administrative roles from Supabase user metadata.
 * Returns empty array if user has no authorized admin roles.
 */
export function extractUserRoles(user: User): string[] {
  const extractedRoles: string[] = [];

  // 1. Inspect app_metadata
  if (user.app_metadata) {
    if (Array.isArray(user.app_metadata.roles)) {
      for (const r of user.app_metadata.roles) {
        if (typeof r === "string") extractedRoles.push(r);
      }
    }
    if (typeof user.app_metadata.role === "string") {
      extractedRoles.push(user.app_metadata.role);
    }
    if (
      user.app_metadata.is_admin === true ||
      user.app_metadata.isAdmin === true
    ) {
      extractedRoles.push("ADMIN");
    }
  }

  // 2. Inspect user_metadata
  if (user.user_metadata) {
    if (Array.isArray(user.user_metadata.roles)) {
      for (const r of user.user_metadata.roles) {
        if (typeof r === "string") extractedRoles.push(r);
      }
    }
    if (typeof user.user_metadata.role === "string") {
      extractedRoles.push(user.user_metadata.role);
    }
    if (
      user.user_metadata.is_admin === true ||
      user.user_metadata.isAdmin === true
    ) {
      extractedRoles.push("ADMIN");
    }
  }

  // Normalize: trim, uppercase, remove hyphens
  const normalized = extractedRoles
    .map((r) => {
      const clean = r.trim().toUpperCase().replace(/-/g, "_");
      if (clean === "SUPERADMIN") return "SUPER_ADMIN";
      if (clean === "FINANCE") return "FINANCE_ADMIN";
      return clean;
    })
    .filter(Boolean);

  // Filter strictly against known valid administrative roles
  const validAdminRoles = Array.from(new Set(normalized)).filter((r) =>
    DEFAULT_ADMIN_ROLES.includes(r),
  );

  return validAdminRoles;
}

/**
 * Check whether a Supabase user possesses authorized administrative roles
 */
export function isUserAdmin(user: User | null): boolean {
  if (!user) return false;
  return extractUserRoles(user).length > 0;
}

function createAdminUserFromSession(
  activeUser: User,
  userRoles: string[],
): AdminUser {
  return {
    id: activeUser.id,
    userId: activeUser.id,
    email: activeUser.email,
    phone: activeUser.phone,
    username:
      activeUser.user_metadata?.username ||
      activeUser.email?.split("@")[0] ||
      "Admin",
    role: userRoles[0] || "ADMIN",
    roles: userRoles,
    permissions: FULL_ADMIN_PERMISSIONS,
    profile: {
      userId: activeUser.id,
      email: activeUser.email,
      fullName:
        activeUser.user_metadata?.full_name ||
        activeUser.user_metadata?.name ||
        "Admin User",
    },
    appMetadata: activeUser.app_metadata,
    userMetadata: activeUser.user_metadata,
  };
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [roles, setRoles] = useState<string[]>([]);
  const [permissions, setPermissions] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const router = useRouter();
  const pathname = usePathname();

  const loadUserProfile = useCallback(
    async (activeUser: User, knownRoles: string[]) => {
      // 1. Establish profile from validated session roles
      const localAdmin = createAdminUserFromSession(activeUser, knownRoles);
      setAdminUser(localAdmin);
      setRoles(knownRoles);
      setPermissions(localAdmin.permissions);

      // 2. Asynchronously attempt backend enrichment in background without blocking
      try {
        const backendUser = await Promise.race([
          apiClient.get<AdminUser>("/api/v1/me"),
          new Promise<never>((_, reject) =>
            setTimeout(() => reject(new Error("Timeout")), 2000),
          ),
        ]);

        if (backendUser?.roles && backendUser.roles.length > 0) {
          const backendAdminRoles = backendUser.roles.filter((r) =>
            DEFAULT_ADMIN_ROLES.includes(r.toUpperCase()),
          );
          if (backendAdminRoles.length > 0) {
            setAdminUser(backendUser);
            setRoles(backendAdminRoles);
            setPermissions(backendUser.permissions || FULL_ADMIN_PERMISSIONS);
          }
        }
      } catch {
        // Backend is offline or optional in standalone admin mode
      }
    },
    [],
  );

  // Initialize session and auth state listener
  useEffect(() => {
    let isMounted = true;

    async function initAuth() {
      try {
        const {
          data: { session: initialSession },
        } = await supabase.auth.getSession();

        if (!isMounted) return;

        if (initialSession?.user) {
          const adminRoles = extractUserRoles(initialSession.user);
          if (adminRoles.length === 0) {
            // Strictly reject non-admin session
            await supabase.auth.signOut();
            syncAuthCookies(null);
            setSession(null);
            setUser(null);
            setAdminUser(null);
            setRoles([]);
            setPermissions([]);
          } else {
            setSession(initialSession);
            setUser(initialSession.user);
            syncAuthCookies(initialSession);
            await loadUserProfile(initialSession.user, adminRoles);
          }
        } else {
          syncAuthCookies(null);
          setSession(null);
          setUser(null);
          setAdminUser(null);
          setRoles([]);
          setPermissions([]);
        }
      } catch (err) {
        console.error("Auth initialization error:", err);
      } finally {
        if (isMounted) {
          setIsLoading(false);
        }
      }
    }

    initAuth();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (_event, newSession) => {
      if (!isMounted) return;

      if (newSession?.user) {
        const adminRoles = extractUserRoles(newSession.user);
        if (adminRoles.length === 0) {
          // Strictly reject non-admin session
          await supabase.auth.signOut();
          syncAuthCookies(null);
          setSession(null);
          setUser(null);
          setAdminUser(null);
          setRoles([]);
          setPermissions([]);
        } else {
          setSession(newSession);
          setUser(newSession.user);
          syncAuthCookies(newSession);
          await loadUserProfile(newSession.user, adminRoles);
        }
      } else {
        syncAuthCookies(null);
        setSession(null);
        setUser(null);
        setAdminUser(null);
        setRoles([]);
        setPermissions([]);
      }
      setIsLoading(false);
    });

    const handleUnauthorized = () => {
      // Only sign out if actively in protected app area
      if (pathname !== "/login") {
        syncAuthCookies(null);
        supabase.auth.signOut();
        router.replace("/login");
      }
    };

    window.addEventListener("tradex:unauthorized", handleUnauthorized);

    return () => {
      isMounted = false;
      subscription.unsubscribe();
      window.removeEventListener("tradex:unauthorized", handleUnauthorized);
    };
  }, [loadUserProfile, pathname, router]);

  // Route protection guard
  useEffect(() => {
    if (isLoading) return;

    const isLoginRoute = pathname === "/login";

    if (!session && !isLoginRoute) {
      router.replace("/login");
    } else if (session && isLoginRoute) {
      router.replace("/dashboard");
    }
  }, [isLoading, session, pathname, router]);

  const login = useCallback(
    async (email: string, password: string) => {
      try {
        const { data, error } = await supabase.auth.signInWithPassword({
          email,
          password,
        });

        if (error) {
          return { error };
        }

        if (!data.session || !data.user) {
          return {
            error: new Error(
              "Authentication failed. No active session created.",
            ),
          };
        }

        // Strictly verify administrative authorization
        const adminRoles = extractUserRoles(data.user);
        if (adminRoles.length === 0) {
          // Reject non-admin logins immediately
          await supabase.auth.signOut();
          syncAuthCookies(null);
          return {
            error: new Error(
              "Access denied: Unauthorized. Administrator privileges required to access TRADEX Admin Portal.",
            ),
          };
        }

        setSession(data.session);
        setUser(data.user);
        syncAuthCookies(data.session);

        const adminProfile = createAdminUserFromSession(data.user, adminRoles);
        setAdminUser(adminProfile);
        setRoles(adminRoles);
        setPermissions(adminProfile.permissions);

        // Background enrichment
        loadUserProfile(data.user, adminRoles).catch(() => {});

        router.replace("/dashboard");
        return { error: null };
      } catch (err) {
        return {
          error:
            err instanceof Error ? err : new Error("Authentication failed"),
        };
      }
    },
    [router, loadUserProfile],
  );

  const logout = useCallback(async () => {
    try {
      syncAuthCookies(null);
      await supabase.auth.signOut();
    } finally {
      syncAuthCookies(null);
      setSession(null);
      setUser(null);
      setAdminUser(null);
      setRoles([]);
      setPermissions([]);
      router.replace("/login");
    }
  }, [router]);

  const hasRole = useCallback(
    (requiredRoles: string | string[]): boolean => {
      if (roles.includes(SUPER_ADMIN_ROLE)) return true;
      const targets = Array.isArray(requiredRoles)
        ? requiredRoles
        : [requiredRoles];
      return targets.some((role) => roles.includes(role));
    },
    [roles],
  );

  const hasPermission = useCallback(
    (requiredPermissions: string | string[]): boolean => {
      if (roles.includes(SUPER_ADMIN_ROLE)) return true;
      const targets = Array.isArray(requiredPermissions)
        ? requiredPermissions
        : [requiredPermissions];
      return targets.some((perm) => permissions.includes(perm));
    },
    [roles, permissions],
  );

  const isAdmin = useMemo(() => {
    if (roles.includes(SUPER_ADMIN_ROLE)) return true;
    return roles.some((r) => DEFAULT_ADMIN_ROLES.includes(r));
  }, [roles]);

  const refreshProfile = useCallback(async () => {
    if (user) {
      const adminRoles = extractUserRoles(user);
      if (adminRoles.length > 0) {
        await loadUserProfile(user, adminRoles);
      }
    }
  }, [user, loadUserProfile]);

  const contextValue = useMemo(
    () => ({
      session,
      user,
      adminUser,
      roles,
      permissions,
      isLoading,
      isAuthenticated: !!session && roles.length > 0,
      isAdmin,
      login,
      logout,
      hasRole,
      hasPermission,
      refreshProfile,
    }),
    [
      session,
      user,
      adminUser,
      roles,
      permissions,
      isLoading,
      isAdmin,
      login,
      logout,
      hasRole,
      hasPermission,
      refreshProfile,
    ],
  );

  if (isLoading) {
    return (
      <Center h="100vh" bg="#0A0F1D">
        <Stack align="center" gap="md">
          <Loader color="tradexGold" size="lg" type="dots" />
          <Text c="#94A3B8" size="sm" fw={500}>
            Loading TRADEX Admin...
          </Text>
        </Stack>
      </Center>
    );
  }

  return (
    <AuthContext.Provider value={contextValue}>{children}</AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}

export default AuthContext;
