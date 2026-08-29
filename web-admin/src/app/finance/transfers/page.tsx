"use client";

import { Stack } from "@mantine/core";
import { FinanceHeader } from "@/components/finance/FinanceHeader";
import { TransfersTab } from "@/components/finance/tabs/TransfersTab";

export default function TransfersPage() {
  return (
    <Stack gap="lg">
      <FinanceHeader />
      <TransfersTab />
    </Stack>
  );
}
