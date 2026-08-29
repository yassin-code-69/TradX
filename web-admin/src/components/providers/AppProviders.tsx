"use client";

import { MantineProvider } from "@mantine/core";
import { ModalsProvider } from "@mantine/modals";
import { Notifications } from "@mantine/notifications";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type React from "react";
import { useState } from "react";
import { ErrorBoundary } from "@/components/common/ErrorBoundary";
import { TopProgressBar } from "@/components/common/TopProgressBar";
import { AdminShell } from "@/components/layout/AdminShell";
import { AuthProvider } from "@/context/AuthContext";
import { theme } from "@/theme";

interface AppProvidersProps {
  children: React.ReactNode;
}

export function AppProviders({ children }: AppProvidersProps) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000,
            retry: 1,
            refetchOnWindowFocus: false,
          },
        },
      }),
  );

  return (
    <QueryClientProvider client={queryClient}>
      <MantineProvider theme={theme} defaultColorScheme="dark">
        <TopProgressBar />
        <Notifications position="top-right" zIndex={2000} autoClose={4000} />
        <ModalsProvider>
          <AuthProvider>
            <AdminShell>
              <ErrorBoundary>{children}</ErrorBoundary>
            </AdminShell>
          </AuthProvider>
        </ModalsProvider>
      </MantineProvider>
    </QueryClientProvider>
  );
}

export default AppProviders;
