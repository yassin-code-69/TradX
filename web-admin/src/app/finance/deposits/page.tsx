"use client";

import { Stack } from "@mantine/core";
import { FinanceHeader } from "@/components/finance/FinanceHeader";
import { DepositsTab } from "@/components/finance/tabs/DepositsTab";

export default function DepositsPage() {
  return (
    <Stack gap="lg">
      <FinanceHeader />
      <DepositsTab />
    </Stack>
  );
}
