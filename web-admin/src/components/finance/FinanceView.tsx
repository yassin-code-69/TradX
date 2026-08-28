"use client";

import {
  Badge,
  Button,
  Group,
  Paper,
  SimpleGrid,
  Stack,
  Tabs,
  Text,
  Title,
} from "@mantine/core";
import {
  IconArrowDownLeft,
  IconArrowsExchange,
  IconArrowUpRight,
  IconReceipt2,
  IconScale,
} from "@tabler/icons-react";
import { useSearchParams } from "next/navigation";
import { useState } from "react";
import { formatBDT } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";
import { AdminAdjustBalanceModal } from "./AdminAdjustBalanceModal";
import { AdjustmentsTab } from "./tabs/AdjustmentsTab";
import { DepositsTab } from "./tabs/DepositsTab";
import { LedgerTab } from "./tabs/LedgerTab";
import { TransfersTab } from "./tabs/TransfersTab";
import { WithdrawalsTab } from "./tabs/WithdrawalsTab";

export function FinanceView() {
  const searchParams = useSearchParams();
  const initialTab = searchParams.get("tab") || "deposits";
  const [activeTab, setActiveTab] = useState<string | null>(initialTab);
  const [adjustmentModalOpened, setAdjustmentModalOpened] = useState(false);

  const { transfers, kpis } = useAdminStore();

  return (
    <Stack gap="lg">
      {/* Top Header */}
      <Group justify="space-between" align="flex-end">
        <Stack gap={2}>
          <Group gap="xs">
            <Text size="xs" c="dimmed" tt="uppercase" fw={700}>
              TRADEX Admin
            </Text>
            <Text size="xs" c="dimmed">
              /
            </Text>
            <Text size="xs" c="yellow.4" fw={700}>
              Financial Operations
            </Text>
          </Group>
          <Title order={2} fw={800} c="white">
            Financial Management & Ledger
          </Title>
          <Text size="sm" c="dimmed">
            Manage deposit approvals, withdrawal payouts, peer transfers, and
            immutable double-entry ledger journals.
          </Text>
        </Stack>

        <Group gap="sm">
          <Button
            color="yellow"
            leftSection={<IconScale size={16} />}
            onClick={() => setAdjustmentModalOpened(true)}
          >
            Adjust Balance
          </Button>
        </Group>
      </Group>

      {/* Summary KPI Cards */}
      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} spacing="md">
        <Paper p="md" radius="md" withBorder bg="dark.8">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Pending Deposits
            </Text>
            <Badge color="yellow" size="sm">
              {kpis.pendingDepositsCount} Needs Review
            </Badge>
          </Group>
          <Text size="xl" fw={800} c="yellow.4" mt="xs">
            {kpis.pendingDepositsAmount}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            bKash, Nagad, Rocket, Bank
          </Text>
        </Paper>

        <Paper p="md" radius="md" withBorder bg="dark.8">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Pending Withdrawals
            </Text>
            <Badge color="orange" size="sm">
              {kpis.pendingWithdrawalsCount} Payouts
            </Badge>
          </Group>
          <Text size="xl" fw={800} c="orange.4" mt="xs">
            {kpis.pendingWithdrawalsAmount}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            Awaiting manual disbursement
          </Text>
        </Paper>

        <Paper p="md" radius="md" withBorder bg="dark.8">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              User Transfers Today
            </Text>
            <Badge color="cyan" size="sm">
              {transfers.length} Transactions
            </Badge>
          </Group>
          <Text size="xl" fw={800} c="cyan.4" mt="xs">
            {formatBDT(transfers.reduce((acc, t) => acc + t.amountMinor, 0))}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            Zero fee peer-to-peer volume
          </Text>
        </Paper>

        <Paper p="md" radius="md" withBorder bg="dark.8">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Total Revenue Pool
            </Text>
            <Badge color="teal" size="sm">
              Financial Health
            </Badge>
          </Group>
          <Text size="xl" fw={800} c="emerald.4" mt="xs">
            {kpis.totalRevenue}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            Gross platform ticket margins
          </Text>
        </Paper>
      </SimpleGrid>

      {/* Main Tabs Component */}
      <Tabs
        value={activeTab}
        onChange={setActiveTab}
        variant="pills"
        radius="md"
        styles={{
          tab: {
            background: "rgba(15, 23, 42, 0.6)",
            border: "1px solid rgba(255, 255, 255, 0.08)",
            color: "#94a3b8",
            fontWeight: 600,
            padding: "10px 18px",
          },
        }}
      >
        <Tabs.List mb="md">
          <Tabs.Tab
            value="deposits"
            leftSection={<IconArrowDownLeft size={16} />}
            rightSection={
              kpis.pendingDepositsCount > 0 ? (
                <Badge color="yellow" size="xs" variant="filled">
                  {kpis.pendingDepositsCount}
                </Badge>
              ) : undefined
            }
          >
            Deposits
          </Tabs.Tab>

          <Tabs.Tab
            value="withdrawals"
            leftSection={<IconArrowUpRight size={16} />}
            rightSection={
              kpis.pendingWithdrawalsCount > 0 ? (
                <Badge color="orange" size="xs" variant="filled">
                  {kpis.pendingWithdrawalsCount}
                </Badge>
              ) : undefined
            }
          >
            Withdrawals
          </Tabs.Tab>

          <Tabs.Tab
            value="transfers"
            leftSection={<IconArrowsExchange size={16} />}
          >
            Internal Transfers
          </Tabs.Tab>

          <Tabs.Tab value="ledger" leftSection={<IconReceipt2 size={16} />}>
            All Ledger Transactions
          </Tabs.Tab>

          <Tabs.Tab value="adjustments" leftSection={<IconScale size={16} />}>
            Admin Balance Adjustment
          </Tabs.Tab>
        </Tabs.List>

        <Tabs.Panel value="deposits">
          <DepositsTab />
        </Tabs.Panel>

        <Tabs.Panel value="withdrawals">
          <WithdrawalsTab />
        </Tabs.Panel>

        <Tabs.Panel value="transfers">
          <TransfersTab />
        </Tabs.Panel>

        <Tabs.Panel value="ledger">
          <LedgerTab />
        </Tabs.Panel>

        <Tabs.Panel value="adjustments">
          <AdjustmentsTab
            onOpenAdjustmentModal={() => setAdjustmentModalOpened(true)}
          />
        </Tabs.Panel>
      </Tabs>

      <AdminAdjustBalanceModal
        opened={adjustmentModalOpened}
        onClose={() => setAdjustmentModalOpened(false)}
      />
    </Stack>
  );
}
