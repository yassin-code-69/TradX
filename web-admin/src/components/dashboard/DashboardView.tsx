"use client";

import {
  ActionIcon,
  Badge,
  Button,
  Card,
  Group,
  Paper,
  SimpleGrid,
  Stack,
  Table,
  Text,
  Title,
  Tooltip,
  useComputedColorScheme,
} from "@mantine/core";
import {
  IconArrowDownLeft,
  IconArrowUpRight,
  IconBuildingBank,
  IconCheck,
  IconClock,
  IconExternalLink,
  IconEye,
  IconReceipt2,
  IconSparkles,
  IconTicket,
  IconTrendingUp,
  IconUsers,
  IconX,
} from "@tabler/icons-react";
import Link from "next/link";
import { useEffect, useState } from "react";
import { ApproveDepositModal } from "@/components/finance/ApproveDepositModal";
import { ApproveWithdrawalModal } from "@/components/finance/ApproveWithdrawalModal";
import { DepositReceiptModal } from "@/components/finance/DepositReceiptModal";
import { RejectDepositModal } from "@/components/finance/RejectDepositModal";
import { RejectWithdrawalModal } from "@/components/finance/RejectWithdrawalModal";
import {
  formatDateTime,
  formatTimeAgo,
  formatTimeRemaining,
  getStatusColor,
} from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";
import type { DepositItem, WithdrawalItem } from "@/types";

export function DashboardView() {
  const { kpis, draws, deposits, withdrawals, ledgerTransactions } =
    useAdminStore();

  const computedColorScheme = useComputedColorScheme("dark", {
    getInitialValueInEffect: true,
  });
  const isDark = computedColorScheme === "dark";

  // State for live countdown ticker
  const [_ticker, setTicker] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setTicker((prev) => prev + 1);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // Modal states
  const [selectedReceiptDeposit, setSelectedReceiptDeposit] =
    useState<DepositItem | null>(null);
  const [selectedApproveDeposit, setSelectedApproveDeposit] =
    useState<DepositItem | null>(null);
  const [selectedRejectDeposit, setSelectedRejectDeposit] =
    useState<DepositItem | null>(null);
  const [selectedApproveWithdrawal, setSelectedApproveWithdrawal] =
    useState<WithdrawalItem | null>(null);
  const [selectedRejectWithdrawal, setSelectedRejectWithdrawal] =
    useState<WithdrawalItem | null>(null);

  const pendingDeposits = deposits
    .filter((d) => d.status === "PENDING")
    .slice(0, 4);
  const pendingWithdrawals = withdrawals
    .filter((w) => w.status === "PENDING")
    .slice(0, 4);
  const recentTransactions = ledgerTransactions.slice(0, 6);

  return (
    <Stack gap="xl">
      {/* Page Header */}
      <Group justify="space-between" align="flex-end">
        <Stack gap={2}>
          <Group gap="xs">
            <Text size="xs" c="dimmed" tt="uppercase" fw={700}>
              TRADEX Platform
            </Text>
            <Text size="xs" c="dimmed">
              /
            </Text>
            <Text size="xs" c={isDark ? "yellow.4" : "tradexGold.7"} fw={700}>
              Operational Command Center
            </Text>
          </Group>
          <Title order={2} fw={800}>
            Operational Overview & Finance
          </Title>
          <Text size="sm" c="dimmed">
            Real-time financial flows, pending review queues, and lottery draw
            execution monitor.
          </Text>
        </Stack>

        <Group gap="sm">
          <Badge color="gray" size="lg" variant="outline">
            Refreshed 1s ago
          </Badge>
          <Button
            component={Link}
            href="/finance"
            variant="light"
            color="yellow"
            leftSection={<IconBuildingBank size={16} />}
          >
            Financial Management
          </Button>
        </Group>
      </Group>

      {/* Row 1: KPI Stat Cards */}
      <SimpleGrid cols={{ base: 1, sm: 2, md: 3, xl: 6 }} spacing="md">
        {/* Total Revenue */}
        <Card
          p="md"
          radius="md"
          withBorder
          bg="var(--mantine-color-body)"
          className="glass-card-hover"
        >
          <Group justify="space-between" mb="xs">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Total Revenue
            </Text>
            <ActionIcon variant="light" color="yellow" size="sm" radius="md">
              <IconTrendingUp size={16} />
            </ActionIcon>
          </Group>
          <Text size="xl" fw={800}>
            {kpis.totalRevenue}
          </Text>
          <Text
            size="xs"
            c={isDark ? "emerald.4" : "emerald.7"}
            fw={600}
            mt={4}
          >
            {kpis.totalRevenueDelta}
          </Text>
        </Card>

        {/* Today Ticket Sales */}
        <Card
          p="md"
          radius="md"
          withBorder
          bg="var(--mantine-color-body)"
          className="glass-card-hover"
        >
          <Group justify="space-between" mb="xs">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Today Ticket Sales
            </Text>
            <ActionIcon variant="light" color="teal" size="sm" radius="md">
              <IconTicket size={16} />
            </ActionIcon>
          </Group>
          <Text size="xl" fw={800} c={isDark ? "emerald.4" : "emerald.7"}>
            {kpis.todayTicketSales}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            {kpis.todayTicketSalesCount.toLocaleString()} tickets issued
          </Text>
        </Card>

        {/* Active Users */}
        <Card
          p="md"
          radius="md"
          withBorder
          bg="var(--mantine-color-body)"
          className="glass-card-hover"
        >
          <Group justify="space-between" mb="xs">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Active Users
            </Text>
            <ActionIcon variant="light" color="blue" size="sm" radius="md">
              <IconUsers size={16} />
            </ActionIcon>
          </Group>
          <Text size="xl" fw={800}>
            {kpis.activeUsers.toLocaleString()}
          </Text>
          <Text size="xs" c={isDark ? "blue.4" : "blue.7"} fw={600} mt={4}>
            {kpis.activeUsersDelta}
          </Text>
        </Card>

        {/* Pending Deposits */}
        <Card
          p="md"
          radius="md"
          withBorder
          bg="var(--mantine-color-body)"
          className="glass-card-hover"
          component={Link}
          href="/finance?tab=deposits"
          style={{ textDecoration: "none" }}
        >
          <Group justify="space-between" mb="xs">
            <Text
              size="xs"
              c={isDark ? "yellow.4" : "yellow.7"}
              fw={700}
              tt="uppercase"
            >
              Pending Deposits
            </Text>
            <ActionIcon variant="filled" color="yellow" size="sm" radius="md">
              <IconArrowDownLeft size={16} />
            </ActionIcon>
          </Group>
          <Text size="xl" fw={800} c={isDark ? "yellow.4" : "yellow.7"}>
            {kpis.pendingDepositsCount} Requests
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            {kpis.pendingDepositsAmount} in queue
          </Text>
        </Card>

        {/* Pending Withdrawals */}
        <Card
          p="md"
          radius="md"
          withBorder
          bg="var(--mantine-color-body)"
          className="glass-card-hover"
          component={Link}
          href="/finance?tab=withdrawals"
          style={{ textDecoration: "none" }}
        >
          <Group justify="space-between" mb="xs">
            <Text
              size="xs"
              c={isDark ? "orange.4" : "orange.7"}
              fw={700}
              tt="uppercase"
            >
              Pending Payouts
            </Text>
            <ActionIcon variant="filled" color="orange" size="sm" radius="md">
              <IconArrowUpRight size={16} />
            </ActionIcon>
          </Group>
          <Text size="xl" fw={800} c={isDark ? "orange.4" : "orange.7"}>
            {kpis.pendingWithdrawalsCount} Requests
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            {kpis.pendingWithdrawalsAmount} to disburse
          </Text>
        </Card>

        {/* Active Draws */}
        <Card
          p="md"
          radius="md"
          withBorder
          bg="var(--mantine-color-body)"
          className="glass-card-hover"
        >
          <Group justify="space-between" mb="xs">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Active Draws
            </Text>
            <ActionIcon variant="light" color="indigo" size="sm" radius="md">
              <IconSparkles size={16} />
            </ActionIcon>
          </Group>
          <Text size="xl" fw={800} c={isDark ? "cyan.4" : "cyan.8"}>
            {draws.filter((d) => d.status === "OPEN").length} Live
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            Mega, Daily & Hourly
          </Text>
        </Card>
      </SimpleGrid>

      {/* Row 2: Live Active Draws Status Overview */}
      <Stack gap="sm">
        <Group justify="space-between" align="center">
          <Group gap="xs">
            <IconSparkles size={20} color={isDark ? "#fad045" : "#d97706"} />
            <Title order={4} fw={700}>
              Live Platform Draws Status
            </Title>
          </Group>
          <Text size="xs" c="dimmed">
            Authoritative ticket pools & countdown timers
          </Text>
        </Group>

        <SimpleGrid cols={{ base: 1, md: 3 }} spacing="md">
          {draws.map((draw) => (
            <Card
              key={draw.id}
              p="lg"
              radius="md"
              withBorder
              bg="var(--mantine-color-body)"
              style={{
                borderLeft: `4px solid ${
                  draw.type === "MEGA"
                    ? isDark
                      ? "#fad045"
                      : "#d97706"
                    : draw.type === "DAILY"
                      ? "#20c997"
                      : "#4c7cd9"
                }`,
              }}
            >
              <Stack gap="sm">
                <Group justify="space-between" align="flex-start">
                  <Stack gap={2}>
                    <Group gap="xs">
                      <Badge
                        color={
                          draw.type === "MEGA"
                            ? "yellow"
                            : draw.type === "DAILY"
                              ? "teal"
                              : "blue"
                        }
                        variant="filled"
                        size="sm"
                      >
                        {draw.type}
                      </Badge>
                      <Text size="sm" fw={700} ff="monospace">
                        #{draw.sequenceNumber}
                      </Text>
                    </Group>
                    <Text size="md" fw={700}>
                      {draw.name}
                    </Text>
                  </Stack>
                  <Badge color="teal" variant="dot" size="md">
                    {draw.status}
                  </Badge>
                </Group>

                <Paper
                  p="sm"
                  radius="md"
                  bg="var(--mantine-color-default)"
                  withBorder
                >
                  <Group justify="space-between" align="center">
                    <Stack gap={1}>
                      <Text size="10px" c="dimmed" tt="uppercase" fw={700}>
                        Prize Jackpot
                      </Text>
                      <Text
                        size="lg"
                        fw={800}
                        c={isDark ? "yellow.4" : "yellow.7"}
                      >
                        {draw.formattedJackpot}
                      </Text>
                    </Stack>
                    <Stack gap={1} ta="right">
                      <Text size="10px" c="dimmed" tt="uppercase" fw={700}>
                        Ticket Price
                      </Text>
                      <Text size="sm" fw={700}>
                        {draw.formattedTicketPrice}
                      </Text>
                    </Stack>
                  </Group>
                </Paper>

                <Group justify="space-between">
                  <Group gap={6}>
                    <IconClock
                      size={16}
                      color={isDark ? "#fad045" : "#d97706"}
                    />
                    <Text size="xs" c="dimmed">
                      Closes in:
                    </Text>
                  </Group>
                  <Text
                    size="xs"
                    fw={700}
                    ff="monospace"
                    c={isDark ? "yellow.3" : "yellow.8"}
                  >
                    {formatTimeRemaining(draw.saleClosesAt)}
                  </Text>
                </Group>

                <Group justify="space-between">
                  <Text size="xs" c="dimmed">
                    Tickets Sold:
                  </Text>
                  <Text size="xs" fw={700}>
                    {draw.ticketsSold.toLocaleString()} ({draw.digitLength}
                    -digit)
                  </Text>
                </Group>

                <Button
                  component={Link}
                  href={`/draws`}
                  variant="subtle"
                  size="xs"
                  fullWidth
                  rightSection={<IconExternalLink size={14} />}
                >
                  Manage Draw
                </Button>
              </Stack>
            </Card>
          ))}
        </SimpleGrid>
      </Stack>

      {/* Row 3: Actionable Pending Queue Cards */}
      <SimpleGrid cols={{ base: 1, lg: 2 }} spacing="lg">
        {/* Left: Pending Deposits Queue */}
        <Card p="md" radius="md" withBorder bg="var(--mantine-color-body)">
          <Group justify="space-between" mb="md">
            <Group gap="xs">
              <IconArrowDownLeft
                size={20}
                color={isDark ? "#fad045" : "#d97706"}
              />
              <Title order={4} fw={700}>
                Pending Deposits Queue
              </Title>
              <Badge color="yellow" size="sm" variant="filled">
                {pendingDeposits.length}
              </Badge>
            </Group>
            <Button
              component={Link}
              href="/finance?tab=deposits"
              variant="subtle"
              size="xs"
              rightSection={<IconChevronRightSmall />}
            >
              View All
            </Button>
          </Group>

          {pendingDeposits.length === 0 ? (
            <Paper
              p="xl"
              withBorder
              radius="md"
              ta="center"
              bg="var(--mantine-color-default)"
            >
              <IconCheck
                size={32}
                color="#20c997"
                style={{ margin: "0 auto 8px" }}
              />
              <Text size="sm" fw={600}>
                All clear!
              </Text>
              <Text size="xs" c="dimmed">
                No pending manual deposits in queue.
              </Text>
            </Paper>
          ) : (
            <Stack gap="xs">
              {pendingDeposits.map((deposit) => (
                <Paper
                  key={deposit.id}
                  p="sm"
                  radius="md"
                  withBorder
                  bg="var(--mantine-color-default)"
                  className="glass-card-hover"
                >
                  <Group justify="space-between" wrap="nowrap">
                    <Stack gap={2} style={{ flex: 1, minWidth: 0 }}>
                      <Group gap="xs">
                        <Text size="sm" fw={700} truncate>
                          {deposit.userFullName}
                        </Text>
                        <Badge color="gray" variant="light" size="xs">
                          {deposit.paymentMethod}
                        </Badge>
                      </Group>
                      <Group gap="xs">
                        <Text size="xs" c="dimmed" ff="monospace">
                          TrxID: {deposit.providerTransactionId}
                        </Text>
                        <Text size="xs" c="dimmed">
                          •
                        </Text>
                        <Text size="xs" c="dimmed">
                          {formatTimeAgo(deposit.submittedAt)}
                        </Text>
                      </Group>
                    </Stack>

                    <Stack gap={4} align="flex-end">
                      <Text
                        size="md"
                        fw={800}
                        c={isDark ? "emerald.4" : "emerald.7"}
                      >
                        {deposit.formattedAmount}
                      </Text>
                      <Group gap={6}>
                        {deposit.proofImageUrl && (
                          <Tooltip label="View Screenshot Proof">
                            <ActionIcon
                              size="sm"
                              variant="light"
                              color="gray"
                              onClick={() => setSelectedReceiptDeposit(deposit)}
                            >
                              <IconEye size={14} />
                            </ActionIcon>
                          </Tooltip>
                        )}
                        <Tooltip label="Quick Reject">
                          <ActionIcon
                            size="sm"
                            variant="light"
                            color="red"
                            onClick={() => setSelectedRejectDeposit(deposit)}
                          >
                            <IconX size={14} />
                          </ActionIcon>
                        </Tooltip>
                        <Button
                          size="xs"
                          color="teal"
                          px="xs"
                          leftSection={<IconCheck size={14} />}
                          onClick={() => setSelectedApproveDeposit(deposit)}
                        >
                          Approve
                        </Button>
                      </Group>
                    </Stack>
                  </Group>
                </Paper>
              ))}
            </Stack>
          )}
        </Card>

        {/* Right: Pending Withdrawals Queue */}
        <Card p="md" radius="md" withBorder bg="var(--mantine-color-body)">
          <Group justify="space-between" mb="md">
            <Group gap="xs">
              <IconArrowUpRight
                size={20}
                color={isDark ? "#ff8787" : "#e03131"}
              />
              <Title order={4} fw={700}>
                Pending Withdrawals Queue
              </Title>
              <Badge color="orange" size="sm" variant="filled">
                {pendingWithdrawals.length}
              </Badge>
            </Group>
            <Button
              component={Link}
              href="/finance?tab=withdrawals"
              variant="subtle"
              size="xs"
              rightSection={<IconChevronRightSmall />}
            >
              View All
            </Button>
          </Group>

          {pendingWithdrawals.length === 0 ? (
            <Paper
              p="xl"
              withBorder
              radius="md"
              ta="center"
              bg="var(--mantine-color-default)"
            >
              <IconCheck
                size={32}
                color="#20c997"
                style={{ margin: "0 auto 8px" }}
              />
              <Text size="sm" fw={600}>
                All clear!
              </Text>
              <Text size="xs" c="dimmed">
                No pending user withdrawal requests.
              </Text>
            </Paper>
          ) : (
            <Stack gap="xs">
              {pendingWithdrawals.map((withdrawal) => (
                <Paper
                  key={withdrawal.id}
                  p="sm"
                  radius="md"
                  withBorder
                  bg="var(--mantine-color-default)"
                  className="glass-card-hover"
                >
                  <Group justify="space-between" wrap="nowrap">
                    <Stack gap={2} style={{ flex: 1, minWidth: 0 }}>
                      <Group gap="xs">
                        <Text size="sm" fw={700} truncate>
                          {withdrawal.userFullName}
                        </Text>
                        <Badge color="blue" size="xs" variant="light">
                          {withdrawal.paymentMethod}
                        </Badge>
                      </Group>
                      <Group gap="xs">
                        <Text
                          size="xs"
                          c={isDark ? "cyan.4" : "cyan.8"}
                          ff="monospace"
                        >
                          To: {withdrawal.receiverAccount}
                        </Text>
                        <Text size="xs" c="dimmed">
                          •
                        </Text>
                        <Text size="xs" c="dimmed">
                          {formatTimeAgo(withdrawal.requestedAt)}
                        </Text>
                      </Group>
                    </Stack>

                    <Stack gap={4} align="flex-end">
                      <Group gap={4} align="baseline">
                        <Text size="xs" c="dimmed">
                          Net:
                        </Text>
                        <Text size="md" fw={800}>
                          {withdrawal.formattedNetAmount}
                        </Text>
                      </Group>
                      <Group gap={6}>
                        <Tooltip label="Reject & Refund">
                          <ActionIcon
                            size="sm"
                            variant="light"
                            color="red"
                            onClick={() =>
                              setSelectedRejectWithdrawal(withdrawal)
                            }
                          >
                            <IconX size={14} />
                          </ActionIcon>
                        </Tooltip>
                        <Button
                          size="xs"
                          color="teal"
                          px="xs"
                          leftSection={<IconCheck size={14} />}
                          onClick={() =>
                            setSelectedApproveWithdrawal(withdrawal)
                          }
                        >
                          Approve Payout
                        </Button>
                      </Group>
                    </Stack>
                  </Group>
                </Paper>
              ))}
            </Stack>
          )}
        </Card>
      </SimpleGrid>

      {/* Row 4: Recent Financial Transactions Table */}
      <Card p="md" radius="md" withBorder bg="var(--mantine-color-body)">
        <Group justify="space-between" mb="md">
          <Group gap="xs">
            <IconReceipt2 size={20} color={isDark ? "#638cdd" : "#3b5bdb"} />
            <Title order={4} fw={700}>
              Recent Financial Transactions
            </Title>
          </Group>
          <Button
            component={Link}
            href="/finance?tab=ledger"
            variant="light"
            size="xs"
            rightSection={<IconExternalLink size={14} />}
          >
            Full Ledger History
          </Button>
        </Group>

        <Table.ScrollContainer minWidth={750}>
          <Table verticalSpacing="sm">
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Trx ID</Table.Th>
                <Table.Th>User Account</Table.Th>
                <Table.Th>Type</Table.Th>
                <Table.Th>Amount</Table.Th>
                <Table.Th>Status</Table.Th>
                <Table.Th>Timestamp</Table.Th>
                <Table.Th>Note</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {recentTransactions.map((tx) => (
                <Table.Tr key={tx.id}>
                  <Table.Td>
                    <Text size="xs" ff="monospace" fw={600} c="dimmed">
                      {tx.id}
                    </Text>
                  </Table.Td>
                  <Table.Td>
                    <Text size="sm" fw={600}>
                      {tx.userFullName}
                    </Text>
                    <Text size="xs" c="dimmed">
                      @{tx.username}
                    </Text>
                  </Table.Td>
                  <Table.Td>
                    <Badge
                      color={getTransactionTypeColor(tx.transactionType)}
                      size="sm"
                    >
                      {tx.transactionType}
                    </Badge>
                  </Table.Td>
                  <Table.Td>
                    <Text
                      size="sm"
                      fw={700}
                      c={
                        tx.direction === "CREDIT"
                          ? isDark
                            ? "emerald.4"
                            : "emerald.7"
                          : isDark
                            ? "red.4"
                            : "red.7"
                      }
                    >
                      {tx.direction === "CREDIT" ? "+" : "-"}{" "}
                      {tx.formattedAmount}
                    </Text>
                  </Table.Td>
                  <Table.Td>
                    <Badge
                      color={getStatusColor(tx.status)}
                      size="xs"
                      variant="light"
                    >
                      {tx.status}
                    </Badge>
                  </Table.Td>
                  <Table.Td>
                    <Text size="xs" c="dimmed">
                      {formatDateTime(tx.createdAt)}
                    </Text>
                  </Table.Td>
                  <Table.Td>
                    <Text size="xs" c="dimmed" lineClamp={1}>
                      {tx.note || "-"}
                    </Text>
                  </Table.Td>
                </Table.Tr>
              ))}
            </Table.Tbody>
          </Table>
        </Table.ScrollContainer>
      </Card>

      {/* Action Modals */}
      <DepositReceiptModal
        opened={!!selectedReceiptDeposit}
        onClose={() => setSelectedReceiptDeposit(null)}
        deposit={selectedReceiptDeposit}
        onApprove={(dep) => setSelectedApproveDeposit(dep)}
        onReject={(dep) => setSelectedRejectDeposit(dep)}
      />

      <ApproveDepositModal
        opened={!!selectedApproveDeposit}
        onClose={() => setSelectedApproveDeposit(null)}
        deposit={selectedApproveDeposit}
      />

      <RejectDepositModal
        opened={!!selectedRejectDeposit}
        onClose={() => setSelectedRejectDeposit(null)}
        deposit={selectedRejectDeposit}
      />

      <ApproveWithdrawalModal
        opened={!!selectedApproveWithdrawal}
        onClose={() => setSelectedApproveWithdrawal(null)}
        withdrawal={selectedApproveWithdrawal}
      />

      <RejectWithdrawalModal
        opened={!!selectedRejectWithdrawal}
        onClose={() => setSelectedRejectWithdrawal(null)}
        withdrawal={selectedRejectWithdrawal}
      />
    </Stack>
  );
}

function IconChevronRightSmall() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      aria-hidden="true"
    >
      <polyline points="9 18 15 12 9 6" />
    </svg>
  );
}

function getTransactionTypeColor(type: string): string {
  switch (type) {
    case "DEPOSIT":
      return "teal";
    case "WITHDRAWAL":
      return "orange";
    case "TICKET_PURCHASE":
      return "blue";
    case "WINNING":
      return "yellow";
    case "ADMIN_ADJUSTMENT":
      return "grape";
    case "USER_TRANSFER":
      return "cyan";
    default:
      return "gray";
  }
}
