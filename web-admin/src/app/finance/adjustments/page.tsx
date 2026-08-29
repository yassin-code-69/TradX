"use client";

import { Stack } from "@mantine/core";
import dynamic from "next/dynamic";
import { useState } from "react";
import { FinanceHeader } from "@/components/finance/FinanceHeader";
import { AdjustmentsTab } from "@/components/finance/tabs/AdjustmentsTab";

const AdminAdjustBalanceModal = dynamic(
  () =>
    import("@/components/finance/AdminAdjustBalanceModal").then(
      (mod) => mod.AdminAdjustBalanceModal,
    ),
  { ssr: false },
);

export default function AdjustmentsPage() {
  const [adjustmentModalOpened, setAdjustmentModalOpened] = useState(false);

  return (
    <Stack gap="lg">
      <FinanceHeader />
      <AdjustmentsTab
        onOpenAdjustmentModal={() => setAdjustmentModalOpened(true)}
      />
      {adjustmentModalOpened && (
        <AdminAdjustBalanceModal
          opened={adjustmentModalOpened}
          onClose={() => setAdjustmentModalOpened(false)}
        />
      )}
    </Stack>
  );
}
