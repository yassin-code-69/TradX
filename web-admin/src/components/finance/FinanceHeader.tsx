"use client";

import {
  Badge,
  Button,
  Group,
  Paper,
  SimpleGrid,
  Stack,
  Text,
  Title,
  UnstyledButton,
} from "@mantine/core";
import {
  IconArrowDownLeft,
  IconArrowsExchange,
  IconArrowUpRight,
  IconReceipt2,
  IconScale,
} from "@tabler/icons-react";
import dynamic from "next/dynamic";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { formatBDT } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";

const AdminAdjustBalanceModal = dynamic(
  () =>
    import("./AdminAdjustBalanceModal").then(
      (mod) => mod.AdminAdjustBalanceModal,
    ),
  { ssr: false },
);

const FINANCE_NAV_LINKS = [
  {
    label: "Deposit Requests",
    href: "/finance/deposits",
    icon: IconArrowDownLeft,
    badgeKey: "deposits",
  },
  {
    label: "Withdrawal Requests",
    href: "/finance/withdrawals",
    icon: IconArrowUpRight,
    badgeKey: "withdrawals",
  },
  {
    label: "Internal Transfers",
    href: "/finance/transfers",
    icon: IconArrowsExchange,
  },
  {
    label: "All Ledger Transactions",
    href: "/finance/ledger",
    icon: IconReceipt2,
  },
  {
    label: "Balance Adjustments",
    href: "/finance/adjustments",
    icon: IconScale,
  },
];

export function FinanceHeader() {
  const pathname = usePathname();
  const [adjustmentModalOpened, setAdjustmentModalOpened] = useState(false);

  const kpis = useAdminStore((s) => s.kpis);
  const transfers = useAdminStore((s) => s.transfers);

  const isLinkActive = (href: string) => {
    if (href === "/finance/deposits") {
      return pathname === "/finance/deposits" || pathname === "/finance";
    }
    return pathname === href || pathname.startsWith(`${href}/`);
  };

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
            <Text size="xs" c="var(--color-gold-400)" fw={700}>
              Financial Operations
            </Text>
          </Group>
          <Title order={2} fw={800} c="var(--mantine-color-text)">
            Financial Management & Ledger
          </Title>
          <Text size="sm" c="dimmed">
            Direct routing for deposit approvals, withdrawal payouts, peer
            transfers, and immutable double-entry ledger journals.
          </Text>
        </Stack>

        <Group gap="sm">
          <Button
            color="yellow"
            leftSection={<IconScale size={16} />}
            onClick={() => setAdjustmentModalOpened(true)}
            style={{ fontWeight: 700 }}
          >
            Adjust Balance
          </Button>
        </Group>
      </Group>

      {/* Summary KPI Cards with direct route links */}
      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} spacing="md">
        <Paper
          p="md"
          radius="md"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
          component={Link}
          href="/finance/deposits"
          prefetch={true}
          style={{ textDecoration: "none", cursor: "pointer" }}
          className="glass-card-hover"
        >
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Pending Deposits
            </Text>
            <Badge color="yellow" size="sm">
              {kpis.pendingDepositsCount} Needs Review
            </Badge>
          </Group>
          <Text
            size="xl"
            fw={800}
            c="var(--color-gold-400)"
            mt="xs"
            className="font-tabular"
          >
            {kpis.pendingDepositsAmount}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            bKash, Nagad, Rocket, Bank
          </Text>
        </Paper>

        <Paper
          p="md"
          radius="md"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
          component={Link}
          href="/finance/withdrawals"
          prefetch={true}
          style={{ textDecoration: "none", cursor: "pointer" }}
          className="glass-card-hover"
        >
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Pending Withdrawals
            </Text>
            <Badge color="orange" size="sm">
              {kpis.pendingWithdrawalsCount} Payouts
            </Badge>
          </Group>
          <Text
            size="xl"
            fw={800}
            c="orange.4"
            mt="xs"
            className="font-tabular"
          >
            {kpis.pendingWithdrawalsAmount}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            Awaiting manual disbursement
          </Text>
        </Paper>

        <Paper
          p="md"
          radius="md"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
          component={Link}
          href="/finance/transfers"
          prefetch={true}
          style={{ textDecoration: "none", cursor: "pointer" }}
          className="glass-card-hover"
        >
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              User Transfers Today
            </Text>
            <Badge color="cyan" size="sm">
              {transfers.length} Transactions
            </Badge>
          </Group>
          <Text size="xl" fw={800} c="cyan.4" mt="xs" className="font-tabular">
            {formatBDT(transfers.reduce((acc, t) => acc + t.amountMinor, 0))}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            Zero fee peer-to-peer volume
          </Text>
        </Paper>

        <Paper
          p="md"
          radius="md"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
          component={Link}
          href="/finance/ledger"
          prefetch={true}
          style={{ textDecoration: "none", cursor: "pointer" }}
          className="glass-card-hover"
        >
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Total Revenue Pool
            </Text>
            <Badge color="teal" size="sm">
              Financial Health
            </Badge>
          </Group>
          <Text
            size="xl"
            fw={800}
            c="emerald.4"
            mt="xs"
            className="font-tabular"
          >
            {kpis.totalRevenue}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            Gross platform ticket margins
          </Text>
        </Paper>
      </SimpleGrid>

      {/* Direct Route Navigation Bar (No Mantine Tabs) */}
      <Group gap="xs" wrap="wrap" mb="xs">
        {FINANCE_NAV_LINKS.map((link) => {
          const active = isLinkActive(link.href);
          const Icon = link.icon;
          const badgeCount =
            link.badgeKey === "deposits"
              ? kpis.pendingDepositsCount
              : link.badgeKey === "withdrawals"
                ? kpis.pendingWithdrawalsCount
                : 0;

          return (
            <Link
              key={link.href}
              href={link.href}
              prefetch={true}
              style={{ textDecoration: "none" }}
            >
              <UnstyledButton
                px="md"
                py="xs"
                style={{
                  borderRadius: "10px",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px",
                  fontSize: "13px",
                  fontWeight: active ? 700 : 500,
                  backgroundColor: active
                    ? "var(--brand-gold-bg, rgba(245, 158, 11, 0.15))"
                    : "var(--surface-card, rgba(255, 255, 255, 0.04))",
                  border: active
                    ? "1px solid var(--color-gold-500, #F59E0B)"
                    : "1px solid var(--surface-border, rgba(255, 255, 255, 0.08))",
                  color: active
                    ? "var(--color-gold-400, #FBBF24)"
                    : "var(--mantine-color-text)",
                  boxShadow: active
                    ? "0 4px 12px rgba(245, 158, 11, 0.15)"
                    : "none",
                  transition: "all 0.18s cubic-bezier(0.16, 1, 0.3, 1)",
                }}
              >
                <Icon size={16} stroke={active ? 2 : 1.6} />
                <span>{link.label}</span>
                {badgeCount > 0 && (
                  <Badge
                    color={link.badgeKey === "deposits" ? "yellow" : "orange"}
                    size="xs"
                    variant="filled"
                  >
                    {badgeCount}
                  </Badge>
                )}
              </UnstyledButton>
            </Link>
          );
        })}
      </Group>

      {adjustmentModalOpened && (
        <AdminAdjustBalanceModal
          opened={adjustmentModalOpened}
          onClose={() => setAdjustmentModalOpened(false)}
        />
      )}
    </Stack>
  );
}

export default FinanceHeader;
