import type { NextRequest } from "next/server";
import { NextResponse } from "next/server";

const PROTECTED_PREFIXES = [
  "/dashboard",
  "/draws",
  "/finance",
  "/results",
  "/settings",
  "/tickets",
  "/users",
];

/**
 * Checks if cookies contain a valid Supabase auth token or session cookie
 */
function hasValidAuthSessionCookie(
  cookies: Array<{ name: string; value: string }>,
): boolean {
  return cookies.some((cookie) => {
    const name = cookie.name.toLowerCase();
    const value = cookie.value ? cookie.value.trim() : "";
    if (!value) return false;

    // Match Supabase auth tokens (e.g. sb-*-auth-token, sb-*-auth-token.0, sb-access-token)
    const isSupabaseToken =
      (name.startsWith("sb-") &&
        (name.includes("auth-token") ||
          name.includes("access-token") ||
          name.includes("token"))) ||
      name.includes("supabase") ||
      name === "sb_token" ||
      name === "auth_token" ||
      name === "session";

    return isSupabaseToken && value.length > 0;
  });
}

/**
 * Next.js Edge Middleware for TRADEX Web Admin Route Guard
 */
export function middleware(request: NextRequest) {
  const { pathname, search } = request.nextUrl;

  const isProtected = PROTECTED_PREFIXES.some(
    (prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`),
  );

  const cookies = request.cookies.getAll();
  const isAuthenticated = hasValidAuthSessionCookie(cookies);

  // 1. Guard protected administrative routes
  if (isProtected && !isAuthenticated) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("redirectTo", `${pathname}${search}`);
    return NextResponse.redirect(loginUrl);
  }

  // 2. Redirect already authenticated users away from /login
  if (pathname === "/login" && isAuthenticated) {
    const redirectTo =
      request.nextUrl.searchParams.get("redirectTo") || "/dashboard";
    const destination = redirectTo.startsWith("/") ? redirectTo : "/dashboard";
    return NextResponse.redirect(new URL(destination, request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/dashboard",
    "/dashboard/:path*",
    "/draws",
    "/draws/:path*",
    "/finance",
    "/finance/:path*",
    "/results",
    "/results/:path*",
    "/settings",
    "/settings/:path*",
    "/tickets",
    "/tickets/:path*",
    "/users",
    "/users/:path*",
    "/login",
  ],
};
