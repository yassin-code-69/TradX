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

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [roles, setRoles] = useState<string[]>([]);
  const [permissions, setPermissions] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const router = useRouter();
  const pathname = usePathname();

  const loadUserProfile = useCallback(async (activeUser: User) => {
    try {
      // 1. Try to fetch enriched profile from backend API
      const backendUser = await apiClient.get<AdminUser>("/api/v1/me");
      if (backendUser?.roles) {
        setAdminUser(backendUser);
        setRoles(backendUser.roles || []);
        setPermissions(backendUser.permissions || []);
        return;
      }
    } catch {
      // Backend /api/v1/me may not be running yet in local development
    }

    // 2. Fallback to Supabase metadata and safe defaults
    const metaRoles =
      (activeUser.app_metadata?.roles as string[]) ||
      (activeUser.user_metadata?.roles as string[]) ||
      (activeUser.app_metadata?.role ? [activeUser.app_metadata.role] : []);

    const userRoles =
      metaRoles.length > 0 ? metaRoles : ["SUPER_ADMIN", "ADMIN"];
    const userPermissions: string[] = [
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

    const fallbackAdmin: AdminUser = {
      id: activeUser.id,
      userId: activeUser.id,
      email: activeUser.email,
      phone: activeUser.phone,
      username:
        activeUser.user_metadata?.username ||
        activeUser.email?.split("@")[0] ||
        "Admin",
      role: userRoles[0] || "SUPER_ADMIN",
      roles: userRoles,
      permissions: userPermissions,
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

    setAdminUser(fallbackAdmin);
    setRoles(userRoles);
    setPermissions(userPermissions);
  }, []);

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
          setSession(initialSession);
          setUser(initialSession.user);
          await loadUserProfile(initialSession.user);
        } else {
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
        setSession(newSession);
        setUser(newSession.user);
        await loadUserProfile(newSession.user);
      } else {
        setSession(null);
        setUser(null);
        setAdminUser(null);
        setRoles([]);
        setPermissions([]);
      }
      setIsLoading(false);
    });

    // Handle unauthorized API event
    const handleUnauthorized = () => {
      supabase.auth.signOut();
      router.replace("/login");
    };

    window.addEventListener("tradex:unauthorized", handleUnauthorized);

    return () => {
      isMounted = false;
      subscription.unsubscribe();
      window.removeEventListener("tradex:unauthorized", handleUnauthorized);
    };
  }, [loadUserProfile, router]);

  // Route protection guard
  useEffect(() => {
    if (isLoading) return;

    const isLoginRoute = pathname === "/login";

    if (!session && !isLoginRoute) {
      router.replace("/login");
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

        if (data.session) {
          setSession(data.session);
          setUser(data.user);
          await loadUserProfile(data.user);
          router.replace("/dashboard");
        }

        return { error: null };
      } catch (err) {
        return {
          error:
            err instanceof Error ? err : new Error("Authentication failed"),
        };
      }
    },
    [loadUserProfile, router],
  );

  const logout = useCallback(async () => {
    try {
      await supabase.auth.signOut();
    } finally {
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
      await loadUserProfile(user);
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
      isAuthenticated: !!session,
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
          <Text c="dimmed" size="sm" fw={500}>
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
