"use client";

import { MantineProvider } from "@mantine/core";
import { ModalsProvider } from "@mantine/modals";
import { Notifications } from "@mantine/notifications";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type React from "react";
import { useState } from "react";
import { AdminShell } from "@/components/layout/AdminShell";
import { AuthProvider } from "@/context/AuthContext";
import { theme } from "@/theme";

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000,
            refetchOnWindowFocus: false,
          },
        },
      }),
  );

  return (
    <QueryClientProvider client={queryClient}>
      <MantineProvider theme={theme} defaultColorScheme="dark">
        <Notifications position="top-right" zIndex={2000} autoClose={4000} />
        <ModalsProvider>
          <AuthProvider>
            <AdminShell>{children}</AdminShell>
          </AuthProvider>
        </ModalsProvider>
      </MantineProvider>
    </QueryClientProvider>
  );
}

export default Providers;
