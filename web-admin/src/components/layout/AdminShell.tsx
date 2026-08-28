"use client";

import { AppShell, useComputedColorScheme } from "@mantine/core";
import { useDisclosure } from "@mantine/hooks";
import { usePathname } from "next/navigation";
import type React from "react";
import { useEffect, useState } from "react";
import { Sidebar } from "./Sidebar";
import { TopHeader } from "./TopHeader";

interface AdminShellProps {
  children: React.ReactNode;
}

const SIDEBAR_COLLAPSED_KEY = "tradex_admin_sidebar_collapsed";

export function AdminShell({ children }: AdminShellProps) {
  const pathname = usePathname();
  const [mobileOpened, { toggle: toggleMobile, close: closeMobile }] =
    useDisclosure(false);
  const [isCollapsed, setIsCollapsed] = useState(false);
  const computedColorScheme = useComputedColorScheme("dark", {
    getInitialValueInEffect: true,
  });
  const isDark = computedColorScheme === "dark";

  // Load saved sidebar collapsed state on mount
  useEffect(() => {
    try {
      const saved = localStorage.getItem(SIDEBAR_COLLAPSED_KEY);
      if (saved !== null) {
        setIsCollapsed(saved === "true");
      }
    } catch {
      // Ignore localStorage errors
    }
  }, []);

  // Close mobile drawer on route change
  useEffect(() => {
    closeMobile();
  }, [closeMobile]);

  const toggleCollapse = () => {
    setIsCollapsed((prev) => {
      const next = !prev;
      try {
        localStorage.setItem(SIDEBAR_COLLAPSED_KEY, String(next));
      } catch {
        // Ignore localStorage errors
      }
      return next;
    });
  };

  // If on login screen, render plain children without admin shell chrome
  if (pathname === "/login") {
    return <>{children}</>;
  }

  const navbarWidth = isCollapsed ? 80 : 260;

  return (
    <AppShell
      header={{ height: 64 }}
      navbar={{
        width: navbarWidth,
        breakpoint: "sm",
        collapsed: { mobile: !mobileOpened },
      }}
      padding="lg"
      styles={{
        header: {
          backgroundColor: isDark ? "#0F172A" : "#FFFFFF",
          borderColor: isDark ? "#1E293B" : "#E2E8F0",
          transition: "background-color 0.2s ease, border-color 0.2s ease",
        },
        navbar: {
          backgroundColor: isDark ? "#0F172A" : "#FFFFFF",
          borderColor: isDark ? "#1E293B" : "#E2E8F0",
          transition:
            "width 0.2s cubic-bezier(0.4, 0, 0.2, 1), background-color 0.2s ease, border-color 0.2s ease",
        },
        main: {
          backgroundColor: isDark ? "#0A0F1D" : "#F8FAFC",
          minHeight: "100vh",
          transition: "background-color 0.2s ease",
        },
      }}
    >
      <AppShell.Header>
        <TopHeader
          mobileOpened={mobileOpened}
          onToggleMobile={toggleMobile}
          isCollapsed={isCollapsed}
          onToggleCollapse={toggleCollapse}
        />
      </AppShell.Header>

      <AppShell.Navbar>
        <Sidebar isCollapsed={isCollapsed} onToggleCollapse={toggleCollapse} />
      </AppShell.Navbar>

      <AppShell.Main>{children}</AppShell.Main>
    </AppShell>
  );
}

export default AdminShell;
