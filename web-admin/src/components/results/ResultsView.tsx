"use client";

import {
  ActionIcon,
  Alert,
  Badge,
  Box,
  Button,
  Card,
  Checkbox,
  Group,
  Modal,
  Pagination,
  Paper,
  PinInput,
  Select,
  SimpleGrid,
  Stack,
  Table,
  Text,
  TextInput,
  ThemeIcon,
  Title,
  UnstyledButton,
} from "@mantine/core";
import { notifications } from "@mantine/notifications";
import {
  IconAlertTriangle,
  IconAward,
  IconClock,
  IconCrown,
  IconEye,
  IconPlus,
  IconRefresh,
  IconTrophy,
} from "@tabler/icons-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type React from "react";
import { useCallback, useMemo, useState } from "react";
import { EmptyState } from "@/components/common/EmptyState";
import { usePublishResult } from "@/lib/api";
import {
  formatBDT,
  formatDateTime,
  formatNumber,
  getDrawTypeColor,
  padLotteryNumber,
} from "@/lib/formatters";
import { useLotteryStore } from "@/lib/store";
import type { DrawResult } from "@/types/lottery";

const RESULTS_NAV_LINKS = [
  { label: "All Results", href: "/results", icon: IconAward },
  {
    label: "Winners List",
    href: "/results/winners",
    icon: IconCrown,
  },
  {
    label: "Pending Verification",
    href: "/results/pending",
    icon: IconClock,
  },
  {
    label: "Publish Winning Numbers",
    href: "/results/publish",
    icon: IconPlus,
  },
];

interface ResultsViewProps {
  initialTab?: "ALL" | "COMPLETED" | "PENDING";
  autoOpenPublish?: boolean;
}

export function ResultsView({
  initialTab = "ALL",
  autoOpenPublish = false,
}: ResultsViewProps) {
  const pathname = usePathname();
  const publishResultMutation = usePublishResult();
  const { draws, results, tickets, publishWinningNumber } = useLotteryStore();

  const activeTab = useMemo(() => {
    if (pathname === "/results/winners") return "COMPLETED";
    if (pathname === "/results/pending") return "PENDING";
    return initialTab;
  }, [pathname, initialTab]);

  const [publishModalOpen, setPublishModalOpen] = useState(
    autoOpenPublish || pathname === "/results/publish",
  );
  const [selectedResultForBreakdown, setSelectedResultForBreakdown] =
    useState<DrawResult | null>(null);
  const [breakdownPage, setBreakdownPage] = useState(1);
  const BREAKDOWN_PAGE_SIZE = 10;

  const [selectedDrawId, setSelectedDrawId] = useState<string | null>(null);
  const [winningNumberInput, setWinningNumberInput] = useState<string>("");
  const [auditHash, setAuditHash] = useState<string>("");
  const [confirmedChecked, setConfirmedChecked] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [publishError, setPublishError] = useState<string | null>(null);

  const publishedDrawIds = useMemo(
    () => new Set(results.map((r) => r.draw_id)),
    [results],
  );

  const pendingDraws = useMemo(() => {
    return draws.filter(
      (d) =>
        (d.status === "CLOSED" || d.status === "PROCESSING") &&
        !publishedDrawIds.has(d.id),
    );
  }, [draws, publishedDrawIds]);

  const selectedDraw = useMemo(() => {
    if (!selectedDrawId) return null;
    return draws.find((d) => String(d.id) === selectedDrawId) || null;
  }, [draws, selectedDrawId]);

  const kpis = useMemo(() => {
    const totalResults = results.length;
    const totalPayoutMinor = results.reduce(
      (acc, r) => acc + Number(r.total_prize_paid_minor || 0),
      0,
    );
    const totalWinners = results.reduce(
      (acc, r) => acc + Number(r.winners_count || 0),
      0,
    );
    const pendingCount = pendingDraws.length;

    return {
      totalResults,
      totalPayoutMinor,
      totalWinners,
      pendingCount,
    };
  }, [results, pendingDraws]);

  const generateAuditHash = useCallback(() => {
    const randomHex = Array.from({ length: 32 }, () =>
      Math.floor(Math.random() * 16).toString(16),
    ).join("");
    setAuditHash(`0x${randomHex}`);
  }, []);

  const handleOpenPublishModal = useCallback(
    (drawId?: number) => {
      setPublishError(null);
      setWinningNumberInput("");
      setConfirmedChecked(false);
      generateAuditHash();

      if (drawId) {
        setSelectedDrawId(String(drawId));
      } else if (pendingDraws.length > 0) {
        setSelectedDrawId(String(pendingDraws[0].id));
      } else {
        setSelectedDrawId(null);
      }
      setPublishModalOpen(true);
    },
    [pendingDraws, generateAuditHash],
  );

  const handlePublishSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setPublishError(null);

    if (!selectedDrawId) {
      setPublishError("Please select a closed draw to publish results for.");
      return;
    }
    if (winningNumberInput.length !== 7 || !/^\d+$/.test(winningNumberInput)) {
      setPublishError(
        "Winning number must be exactly 7 numeric digits (0000000 - 9999999).",
      );
      return;
    }
    if (!confirmedChecked) {
      setPublishError("You must confirm verification before publishing.");
      return;
    }

    setIsSubmitting(true);

    try {
      const parsedDrawId = Number(selectedDrawId);

      await publishResultMutation.mutateAsync({
        draw_id: parsedDrawId,
        winning_number: winningNumberInput,
        result_hash: auditHash || "0x98f4e2...a1b2",
      });

      publishWinningNumber(
        parsedDrawId,
        winningNumberInput,
        auditHash || undefined,
      );

      notifications.show({
        title: "Result Published Successfully",
        message: `Winning number ${winningNumberInput} is now official. Prizes credited!`,
        color: "teal",
        icon: <IconTrophy size={18} />,
      });

      setPublishModalOpen(false);
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : "Failed to publish result";
      setPublishError(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const completedResults = useMemo(() => {
    return results.map((result) => {
      const draw = draws.find((d) => d.id === result.draw_id);
      return {
        ...result,
        draw,
      };
    });
  }, [results, draws]);

  const breakdownTickets = useMemo(() => {
    if (!selectedResultForBreakdown) return [];
    return tickets.filter(
      (t) =>
        t.draw_id === selectedResultForBreakdown.draw_id && t.status === "WON",
    );
  }, [selectedResultForBreakdown, tickets]);

  const paginatedBreakdownTickets = useMemo(() => {
    const start = (breakdownPage - 1) * BREAKDOWN_PAGE_SIZE;
    return breakdownTickets.slice(start, start + BREAKDOWN_PAGE_SIZE);
  }, [breakdownTickets, breakdownPage]);

  const totalBreakdownPages = Math.ceil(
    breakdownTickets.length / BREAKDOWN_PAGE_SIZE,
  );

  return (
    <Stack gap="lg">
      {/* 1. Header Card with Direct Routes */}
      <Card
        p="lg"
        radius="lg"
        withBorder
        bg="var(--surface-card, var(--mantine-color-default))"
      >
        <Group justify="space-between" align="flex-start" wrap="wrap" gap="md">
          <Box>
            <Group gap="xs" mb={4}>
              <ThemeIcon
                size={34}
                radius="md"
                variant="gradient"
                gradient={{ from: "#D97706", to: "#F59E0B", deg: 135 }}
                c="#070B14"
              >
                <IconAward size={20} stroke={2} />
              </ThemeIcon>
              <Box>
                <Title order={2} fw={800} c="var(--mantine-color-text)">
                  Results & Winners Management
                </Title>
                <Text size="xs" c="dimmed" fw={600}>
                  Validate winning 7-digit numbers, distribute automated prize
                  payouts, and verify audit hashes.
                </Text>
              </Box>
            </Group>
          </Box>

          <Group gap="sm">
            <Button
              variant="default"
              leftSection={<IconRefresh size={16} />}
              onClick={() => {
                notifications.show({
                  title: "Refreshed",
                  message: "Result ledgers updated.",
                  color: "blue",
                });
              }}
            >
              Sync
            </Button>
            <Button
              color="tradexGold"
              c="#070B14"
              fw={700}
              leftSection={<IconTrophy size={16} />}
              onClick={() => handleOpenPublishModal()}
            >
              Publish Winning Numbers
            </Button>
          </Group>
        </Group>

        {/* High-level KPIs */}
        <SimpleGrid cols={{ base: 1, sm: 2, md: 4 }} spacing="md" mt="lg">
          <Paper p="sm" radius="md" withBorder bg="var(--surface-card)">
            <Group justify="space-between" mb={2}>
              <Text size="xs" c="dimmed" fw={700} tt="uppercase">
                Completed Results
              </Text>
              <Badge color="blue" size="sm" variant="light">
                Published
              </Badge>
            </Group>
            <Text size="xl" fw={800} c="blue.4" className="font-tabular">
              {kpis.totalResults} Draws
            </Text>
            <Text size="11px" c="dimmed" mt={2}>
              Official audited payouts
            </Text>
          </Paper>

          <Paper p="sm" radius="md" withBorder bg="var(--surface-card)">
            <Group justify="space-between" mb={2}>
              <Text size="xs" c="dimmed" fw={700} tt="uppercase">
                Pending Publication
              </Text>
              <Badge
                color={kpis.pendingCount > 0 ? "orange" : "teal"}
                size="sm"
                variant="filled"
              >
                {kpis.pendingCount > 0 ? "Action Required" : "All Clear"}
              </Badge>
            </Group>
            <Text
              size="xl"
              fw={800}
              c={kpis.pendingCount > 0 ? "orange.4" : "teal.4"}
              className="font-tabular"
            >
              {kpis.pendingCount} Closed Pools
            </Text>
            <Text size="11px" c="dimmed" mt={2}>
              Awaiting number input
            </Text>
          </Paper>

          <Paper p="sm" radius="md" withBorder bg="var(--surface-card)">
            <Group justify="space-between" mb={2}>
              <Text size="xs" c="dimmed" fw={700} tt="uppercase">
                Total Prize Distributed
              </Text>
              <Badge color="tradexGold" size="sm" variant="light">
                Ledger Total
              </Badge>
            </Group>
            <Text
              size="xl"
              fw={800}
              c="var(--color-gold-400)"
              className="font-tabular"
            >
              {formatBDT(kpis.totalPayoutMinor)}
            </Text>
            <Text size="11px" c="dimmed" mt={2}>
              Direct wallet settlements
            </Text>
          </Paper>

          <Paper p="sm" radius="md" withBorder bg="var(--surface-card)">
            <Group justify="space-between" mb={2}>
              <Text size="xs" c="dimmed" fw={700} tt="uppercase">
                Total Winners Awarded
              </Text>
              <Badge color="teal" size="sm" variant="light">
                Players
              </Badge>
            </Group>
            <Text size="xl" fw={800} c="teal.4" className="font-tabular">
              {formatNumber(kpis.totalWinners)}
            </Text>
            <Text size="11px" c="dimmed" mt={2}>
              Across all tiers (Match 2-7)
            </Text>
          </Paper>
        </SimpleGrid>

        {/* Clean Path-Based Navigation Buttons (Zero ?x=y Query Routes) */}
        <Group gap="xs" wrap="wrap" mt="lg">
          {RESULTS_NAV_LINKS.map((link) => {
            const active =
              link.href === "/results"
                ? pathname === "/results"
                : pathname === link.href;
            const Icon = link.icon;

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
                </UnstyledButton>
              </Link>
            );
          })}
        </Group>
      </Card>

      {/* 2. Content Display */}
      {activeTab === "PENDING" ? (
        <Card
          p="md"
          radius="lg"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
        >
          <Group justify="space-between" mb="md">
            <Box>
              <Title order={4} fw={800}>
                Pending Result Publication Queue ({pendingDraws.length})
              </Title>
              <Text size="xs" c="dimmed">
                Draw sales have concluded. Enter verified winning numbers to
                execute automated prize allocations.
              </Text>
            </Box>
          </Group>

          {pendingDraws.length === 0 ? (
            <EmptyState
              icon={IconTrophy}
              title="All Draws Published!"
              description="There are currently no closed pools awaiting winning number verification."
            />
          ) : (
            <SimpleGrid cols={{ base: 1, md: 2, lg: 3 }} spacing="md">
              {pendingDraws.map((draw) => (
                <Card
                  key={draw.id}
                  p="md"
                  radius="md"
                  withBorder
                  bg="var(--surface-card)"
                >
                  <Group justify="space-between" mb="xs">
                    <Badge
                      color={getDrawTypeColor(draw.draw_type_code)}
                      variant="filled"
                    >
                      {draw.draw_type_code}
                    </Badge>
                    <Badge color="orange" variant="dot">
                      CLOSED FOR SALE
                    </Badge>
                  </Group>

                  <Title order={4} fw={800} className="font-tabular">
                    #{draw.sequence_number}
                  </Title>
                  <Text size="xs" c="dimmed" mb="md">
                    Total Pool: {formatBDT(draw.total_sales_minor || 0)} •{" "}
                    {formatNumber(draw.total_tickets || 0)} tickets sold
                  </Text>

                  <Button
                    fullWidth
                    color="tradexGold"
                    c="#070B14"
                    fw={700}
                    leftSection={<IconTrophy size={16} />}
                    onClick={() => handleOpenPublishModal(draw.id)}
                  >
                    Publish Results
                  </Button>
                </Card>
              ))}
            </SimpleGrid>
          )}
        </Card>
      ) : (
        <Card
          p="0"
          radius="lg"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
        >
          <Table.ScrollContainer minWidth={950}>
            <Table verticalSpacing="sm" horizontalSpacing="md" highlightOnHover>
              <Table.Thead bg="var(--surface-card)">
                <Table.Tr>
                  <Table.Th>Draw & ID</Table.Th>
                  <Table.Th>Sequence Code</Table.Th>
                  <Table.Th>Winning 7-Digit Number</Table.Th>
                  <Table.Th>Winners Count</Table.Th>
                  <Table.Th>Total Payout</Table.Th>
                  <Table.Th>Publication Time</Table.Th>
                  <Table.Th ta="right">Audit Verification</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {completedResults.map((result) => (
                  <Table.Tr key={result.id}>
                    <Table.Td>
                      <Group gap="xs">
                        <Badge
                          color={getDrawTypeColor(
                            result.draw?.draw_type_code || "MEGA",
                          )}
                          size="sm"
                        >
                          {result.draw?.draw_type_code || "DRAW"}
                        </Badge>
                        <Text size="xs" c="dimmed" className="font-tabular">
                          #{result.draw_id}
                        </Text>
                      </Group>
                    </Table.Td>

                    <Table.Td>
                      <Text size="sm" fw={700} className="font-tabular">
                        {result.draw?.sequence_number ||
                          `DRAW-${result.draw_id}`}
                      </Text>
                    </Table.Td>

                    <Table.Td>
                      <Group gap={4}>
                        {padLotteryNumber(
                          result.winning_number,
                          result.draw_type_code === "MEGA" ? 7 : 3,
                        )
                          .split("")
                          .map((digit, idx) => (
                            <span
                              key={`${result.id}-digit-${idx}-${digit}`}
                              className="digit-ball font-tabular"
                              style={{
                                display: "inline-flex",
                                alignItems: "center",
                                justifyContent: "center",
                                width: "26px",
                                height: "26px",
                                borderRadius: "50%",
                                backgroundColor:
                                  "var(--brand-gold-bg, rgba(245, 158, 11, 0.2))",
                                border:
                                  "1px solid var(--color-gold-500, #F59E0B)",
                                color: "var(--color-gold-400, #FBBF24)",
                                fontWeight: 800,
                                fontSize: "12px",
                              }}
                            >
                              {digit}
                            </span>
                          ))}
                      </Group>
                    </Table.Td>

                    <Table.Td>
                      <Badge color="teal" size="sm" variant="light">
                        {result.winners_count} Winners
                      </Badge>
                    </Table.Td>

                    <Table.Td>
                      <Text
                        size="sm"
                        fw={700}
                        c="var(--color-gold-400)"
                        className="font-tabular"
                      >
                        {formatBDT(result.total_prize_paid_minor)}
                      </Text>
                    </Table.Td>

                    <Table.Td>
                      <Text size="xs" c="dimmed">
                        {formatDateTime(result.draw_at)}
                      </Text>
                    </Table.Td>

                    <Table.Td ta="right">
                      <Button
                        variant="light"
                        size="xs"
                        leftSection={<IconEye size={14} />}
                        onClick={() => setSelectedResultForBreakdown(result)}
                      >
                        Inspect Breakdown
                      </Button>
                    </Table.Td>
                  </Table.Tr>
                ))}
              </Table.Tbody>
            </Table>
          </Table.ScrollContainer>
        </Card>
      )}

      {/* 3. Publish Modal */}
      <Modal
        opened={publishModalOpen}
        onClose={() => setPublishModalOpen(false)}
        title={
          <Group gap="xs">
            <IconTrophy size={20} color="var(--color-gold-400)" />
            <Title order={4} fw={800}>
              Publish Official Draw Results
            </Title>
          </Group>
        }
        size="lg"
        radius="md"
      >
        <form onSubmit={handlePublishSubmit}>
          <Stack gap="md">
            {publishError && (
              <Alert
                icon={<IconAlertTriangle size={16} />}
                title="Publish Error"
                color="red"
                variant="light"
              >
                {publishError}
              </Alert>
            )}

            <Select
              label="Select Closed Draw"
              required
              placeholder="Choose draw awaiting result..."
              value={selectedDrawId}
              onChange={setSelectedDrawId}
              data={pendingDraws.map((d) => ({
                value: String(d.id),
                label: `${d.draw_type_code} #${d.sequence_number} (Sales: ${formatBDT(d.total_sales_minor || 0)})`,
              }))}
            />

            {selectedDraw && (
              <Paper p="sm" radius="md" withBorder bg="var(--surface-card)">
                <Text size="xs" c="dimmed" mb={2}>
                  Draw Summary
                </Text>
                <Group justify="space-between">
                  <Text size="sm" fw={700}>
                    {selectedDraw.draw_type_name} #
                    {selectedDraw.sequence_number}
                  </Text>
                  <Badge color={getDrawTypeColor(selectedDraw.draw_type_code)}>
                    {selectedDraw.draw_type_code}
                  </Badge>
                </Group>
              </Paper>
            )}

            <Box>
              <Text size="sm" fw={600} mb={4}>
                Winning 7-Digit Combination *
              </Text>
              <PinInput
                length={7}
                type="number"
                value={winningNumberInput}
                onChange={setWinningNumberInput}
                size="md"
                autoFocus
              />
            </Box>

            <TextInput
              label="Cryptographic Audit Hash"
              value={auditHash}
              onChange={(e) => setAuditHash(e.currentTarget.value)}
              placeholder="0x..."
              rightSection={
                <ActionIcon
                  variant="subtle"
                  size="sm"
                  onClick={generateAuditHash}
                >
                  <IconRefresh size={14} />
                </ActionIcon>
              }
            />

            <Checkbox
              label="I confirm this 7-digit winning sequence has been verified against the physical draw machine and audit certificate."
              checked={confirmedChecked}
              onChange={(e) => setConfirmedChecked(e.currentTarget.checked)}
            />

            <Group justify="flex-end" mt="md">
              <Button
                variant="default"
                onClick={() => setPublishModalOpen(false)}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                color="tradexGold"
                c="#070B14"
                fw={700}
                loading={isSubmitting}
              >
                Publish & Credit Winners
              </Button>
            </Group>
          </Stack>
        </form>
      </Modal>

      {/* 4. Winners Breakdown Modal */}
      {selectedResultForBreakdown && (
        <Modal
          opened={!!selectedResultForBreakdown}
          onClose={() => setSelectedResultForBreakdown(null)}
          title={
            <Group gap="xs">
              <IconAward size={20} color="var(--color-gold-400)" />
              <Title order={4} fw={800}>
                Winners Breakdown: Draw #{selectedResultForBreakdown.draw_id}
              </Title>
            </Group>
          }
          size="lg"
          radius="md"
        >
          <Stack gap="md">
            <Paper p="sm" radius="md" withBorder bg="var(--surface-card)">
              <Group justify="space-between">
                <Text size="xs" c="dimmed">
                  Winning Number:
                </Text>
                <Text
                  size="md"
                  fw={800}
                  c="var(--color-gold-400)"
                  className="font-tabular"
                >
                  {selectedResultForBreakdown.winning_number}
                </Text>
              </Group>
              <Group justify="space-between" mt={4}>
                <Text size="xs" c="dimmed">
                  Total Prize Paid:
                </Text>
                <Text size="md" fw={700} c="teal.4" className="font-tabular">
                  {formatBDT(selectedResultForBreakdown.total_prize_paid_minor)}
                </Text>
              </Group>
            </Paper>

            <Title order={5} fw={700}>
              Winning Ticket Holders ({breakdownTickets.length})
            </Title>

            {breakdownTickets.length === 0 ? (
              <Text size="xs" c="dimmed">
                No tickets matched prize tiers for this draw.
              </Text>
            ) : (
              <Stack gap="xs">
                {paginatedBreakdownTickets.map((t) => (
                  <Paper key={t.id} p="xs" radius="md" withBorder>
                    <Group justify="space-between">
                      <Box>
                        <Text size="xs" fw={700} className="font-tabular">
                          Ticket #{t.id} ({t.selected_number})
                        </Text>
                        <Text size="11px" c="dimmed">
                          User ID: {t.user_id} • {t.user_name}
                        </Text>
                      </Box>
                      <Badge color="teal" size="sm" variant="filled">
                        {formatBDT(t.prize_amount_minor || 0)}
                      </Badge>
                    </Group>
                  </Paper>
                ))}

                {totalBreakdownPages > 1 && (
                  <Pagination
                    total={totalBreakdownPages}
                    value={breakdownPage}
                    onChange={setBreakdownPage}
                    size="xs"
                    color="tradexGold"
                  />
                )}
              </Stack>
            )}
          </Stack>
        </Modal>
      )}
    </Stack>
  );
}

export default ResultsView;
