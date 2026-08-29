"use client";

import { Stack } from "@mantine/core";
import { FinanceHeader } from "@/components/finance/FinanceHeader";
import { WithdrawalsTab } from "@/components/finance/tabs/WithdrawalsTab";

export default function WithdrawalsPage() {
  return (
    <Stack gap="lg">
      <FinanceHeader />
      <WithdrawalsTab />
    </Stack>
  );
}
