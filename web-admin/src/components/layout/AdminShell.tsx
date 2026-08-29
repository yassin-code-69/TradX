"use client";

import { AppShell, Box } from "@mantine/core";
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
          backgroundColor: "var(--glass-bg)",
          borderColor: "var(--glass-border)",
          backdropFilter: "blur(16px)",
          WebkitBackdropFilter: "blur(16px)",
          transition: "background-color 0.25s ease, border-color 0.25s ease",
          zIndex: 100,
        },
        navbar: {
          backgroundColor: "var(--glass-bg-elevated)",
          borderColor: "var(--glass-border)",
          // PERF-06: Removed backdropFilter blur to eliminate expensive GPU rasterization on 95% opaque navbar
          transition:
            "width 0.25s cubic-bezier(0.16, 1, 0.3, 1), background-color 0.25s ease, border-color 0.25s ease",
        },
        main: {
          backgroundColor: "var(--surface-ground, var(--mantine-color-body))",
          backgroundImage: "var(--surface-bg-gradient)",
          minHeight: "100vh",
          transition: "background-color 0.25s ease",
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

      <AppShell.Main>
        <Box maw={1600} mx="auto">
          {children}
        </Box>
      </AppShell.Main>
    </AppShell>
  );
}

export default AdminShell;
