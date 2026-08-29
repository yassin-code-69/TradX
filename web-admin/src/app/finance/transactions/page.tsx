"use client";

import { Stack } from "@mantine/core";
import { FinanceHeader } from "@/components/finance/FinanceHeader";
import { LedgerTab } from "@/components/finance/tabs/LedgerTab";

export default function TransactionsPage() {
  return (
    <Stack gap="lg">
      <FinanceHeader />
      <LedgerTab />
    </Stack>
  );
}
