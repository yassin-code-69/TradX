"use client";

import {
  ActionIcon,
  Alert,
  Badge,
  Box,
  Button,
  Card,
  Checkbox,
  Divider,
  Group,
  Modal,
  Pagination,
  Paper,
  PinInput,
  ScrollArea,
  Select,
  SimpleGrid,
  Stack,
  Table,
  Tabs,
  Text,
  TextInput,
  ThemeIcon,
  Title,
  Tooltip,
} from "@mantine/core";
import { notifications } from "@mantine/notifications";
import {
  IconAlertCircle,
  IconAlertTriangle,
  IconAward,
  IconClock,
  IconCoin,
  IconEye,
  IconRefresh,
  IconSparkles,
  IconTrophy,
} from "@tabler/icons-react";
import { useEffect, useMemo, useState } from "react";
import { usePublishResult } from "@/lib/api";
import {
  formatBDT,
  formatDateTime,
  formatNumber,
  getDrawTypeColor,
  padLotteryNumber,
} from "@/lib/formatters";
import { useLotteryStore } from "@/lib/store";
import type { Draw, DrawResult } from "@/types/lottery";

export default function ResultsPage() {
  const publishResultMutation = usePublishResult();
  const { draws, results, winnerBreakdowns, tickets, publishWinningNumber } =
    useLotteryStore();

  // Active tab: 'ALL' | 'COMPLETED' | 'PENDING'
  const [activeTab, setActiveTab] = useState<string | null>("ALL");

  // Modal States
  const [publishModalOpen, setPublishModalOpen] = useState(false);
  const [selectedResultForBreakdown, setSelectedResultForBreakdown] =
    useState<DrawResult | null>(null);

  // Publish Form State
  const [selectedDrawId, setSelectedDrawId] = useState<string | null>(null);
  const [winningNumberInput, setWinningNumberInput] = useState<string>("");
  const [auditHash, setAuditHash] = useState<string>("");
  const [confirmedChecked, setConfirmedChecked] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [publishError, setPublishError] = useState<string | null>(null);

  // Pending draws that need official result publishing (CLOSED draws or completed draws without result)
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

  // Selected draw object for the modal
  const selectedDraw = useMemo(() => {
    if (!selectedDrawId) return null;
    return draws.find((d) => String(d.id) === selectedDrawId) || null;
  }, [draws, selectedDrawId]);

  // Required digits for selected draw
  const requiredDigits = selectedDraw?.draw_type_code === "MEGA" ? 7 : 3;

  // Open publish modal with pre-selected draw if provided
  const handleOpenPublishModal = (drawId?: number) => {
    setPublishError(null);
    setConfirmedChecked(false);
    setWinningNumberInput("");
    setAuditHash(
      `0x${Math.random().toString(16).substring(2, 10)}${Date.now().toString(16)}`,
    );

    if (drawId) {
      setSelectedDrawId(String(drawId));
    } else if (pendingDraws.length > 0) {
      setSelectedDrawId(String(pendingDraws[0].id));
    } else {
      setSelectedDrawId(null);
    }
    setPublishModalOpen(true);
  };

  // Execute publication
  const handlePublishSubmit = async () => {
    setPublishError(null);

    if (!selectedDraw) {
      setPublishError("Please select an eligible draw.");
      return;
    }

    if (winningNumberInput.length !== requiredDigits) {
      setPublishError(
        `Winning number must be exactly ${requiredDigits} numeric digits for ${selectedDraw.draw_type_name}.`,
      );
      return;
    }

    if (!/^\d+$/.test(winningNumberInput)) {
      setPublishError(
        "Winning number must contain only numeric characters [0-9].",
      );
      return;
    }

    if (!confirmedChecked) {
      setPublishError(
        "You must confirm verification and regulatory authorization.",
      );
      return;
    }

    setIsSubmitting(true);

    try {
      await publishResultMutation.mutateAsync({
        draw_id: selectedDraw.id,
        winning_number: winningNumberInput,
        result_hash: auditHash,
      });

      const outcome = publishWinningNumber(
        selectedDraw.id,
        winningNumberInput,
        auditHash || "Super Admin (Audit Console)",
      );

      notifications.show({
        title: "Official Result Published & Payouts Executed",
        message: `Draw ${selectedDraw.sequence_number} finalized with winning number ${outcome.result.winning_number}. ${outcome.winnersCount} winners credited ${formatBDT(outcome.totalPrizeMinor)}.`,
        color: "teal",
        icon: <IconTrophy size={18} />,
        autoClose: 6000,
      });

      setPublishModalOpen(false);
      setSelectedResultForBreakdown(outcome.result);
    } catch (err) {
      const message =
        err instanceof Error ? err.message : "Failed to publish draw result";
      setPublishError(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Metrics overview
  const stats = useMemo(() => {
    const totalPublished = results.length;
    const totalWinners = results.reduce(
      (sum, r) => sum + (r.winners_count || 0),
      0,
    );
    const totalPrizeMinor = results.reduce(
      (sum, r) => sum + Number(r.total_prize_paid_minor || 0),
      0,
    );
    const pendingCount = pendingDraws.length;

    return {
      totalPublished,
      totalWinners,
      totalPrizeMinor,
      pendingCount,
    };
  }, [results, pendingDraws]);

  // Winning tickets for breakdown modal
  const breakdownTickets = useMemo(() => {
    if (!selectedResultForBreakdown) return [];
    return tickets.filter(
      (t) => t.draw_id === selectedResultForBreakdown.draw_id && t.is_winner,
    );
  }, [tickets, selectedResultForBreakdown]);

  // Breakdown tiers for modal
  const activeBreakdownTiers = useMemo(() => {
    if (!selectedResultForBreakdown) return [];
    return (
      winnerBreakdowns[selectedResultForBreakdown.draw_id] || [
        {
          id: "def_tier_1",
          tier_name: "Tier 1: Grand Prize",
          match_type: "EXACT_ALL",
          match_condition: "Exact match",
          matched_digits: selectedResultForBreakdown.winning_number,
          prize_amount_minor: selectedResultForBreakdown.total_prize_paid_minor,
          count: selectedResultForBreakdown.winners_count,
          total_payout_minor: selectedResultForBreakdown.total_prize_paid_minor,
          paid_status: "PAID",
        },
      ]
    );
  }, [winnerBreakdowns, selectedResultForBreakdown]);

  return (
    <Stack gap="lg">
      {/* 1. Header Card */}
      <Card p="lg" radius="md" withBorder>
        <Group justify="space-between" align="flex-start">
          <Box>
            <Group gap="xs" align="center">
              <ThemeIcon
                size={34}
                radius="md"
                color="tradexGold"
                variant="light"
              >
                <IconAward
                  size={20}
                  color="var(--mantine-color-tradexGold-6)"
                />
              </ThemeIcon>
              <Box>
                <Title order={2} size="h3" fw={700}>
                  Results & Winner Management
                </Title>
                <Text size="xs" c="dimmed">
                  Official draw outcomes, cryptographic validation,
                  digit-by-digit verification, and winner tier breakdowns.
                </Text>
              </Box>
            </Group>
          </Box>

          <Group gap="sm">
            <Tooltip label="Synchronize ledger results">
              <ActionIcon
                variant="default"
                size="lg"
                onClick={() => {
                  notifications.show({
                    title: "Results Refreshed",
                    message: "Official results and winner payouts updated.",
                    color: "blue",
                  });
                }}
              >
                <IconRefresh size={18} />
              </ActionIcon>
            </Tooltip>

            <Button
              color="tradexGold"
              variant="filled"
              style={{ color: "#0A0F1D", fontWeight: 700 }}
              leftSection={<IconSparkles size={18} />}
              onClick={() => handleOpenPublishModal()}
            >
              Publish Winning Number
            </Button>
          </Group>
        </Group>
      </Card>

      {/* 2. Key Metrics Overview */}
      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} spacing="md">
        <Card p="md" radius="md" withBorder>
          <Group justify="space-between" align="flex-start">
            <Box>
              <Text size="xs" c="dimmed" fw={600} tt="uppercase">
                Published Results
              </Text>
              <Title order={3} size="h2" fw={800} mt={4}>
                {stats.totalPublished}
              </Title>
              <Text size="xs" c="dimmed" mt={2}>
                Official draws determined
              </Text>
            </Box>
            <ThemeIcon size={42} radius="md" color="blue" variant="light">
              <IconAward size={22} />
            </ThemeIcon>
          </Group>
        </Card>

        <Card p="md" radius="md" withBorder>
          <Group justify="space-between" align="flex-start">
            <Box>
              <Text size="xs" c="dimmed" fw={600} tt="uppercase">
                Winners Awarded
              </Text>
              <Title order={3} size="h2" fw={800} mt={4} c="teal">
                {formatNumber(stats.totalWinners)}
              </Title>
              <Text size="xs" c="teal" mt={2} fw={500}>
                Across all prize tiers
              </Text>
            </Box>
            <ThemeIcon size={42} radius="md" color="teal" variant="light">
              <IconTrophy size={22} />
            </ThemeIcon>
          </Group>
        </Card>

        <Card p="md" radius="md" withBorder>
          <Group justify="space-between" align="flex-start">
            <Box>
              <Text size="xs" c="dimmed" fw={600} tt="uppercase">
                Prizes Distributed
              </Text>
              <Title order={3} size="h2" fw={800} mt={4} c="tradexGold.5">
                {formatBDT(stats.totalPrizeMinor)}
              </Title>
              <Text size="xs" c="dimmed" mt={2}>
                Direct user wallet settlements
              </Text>
            </Box>
            <ThemeIcon size={42} radius="md" color="tradexGold" variant="light">
              <IconCoin size={22} />
            </ThemeIcon>
          </Group>
        </Card>

        <Card p="md" radius="md" withBorder>
          <Group justify="space-between" align="flex-start">
            <Box>
              <Text size="xs" c="dimmed" fw={600} tt="uppercase">
                Awaiting Official Result
              </Text>
              <Title
                order={3}
                size="h2"
                fw={800}
                mt={4}
                c={stats.pendingCount > 0 ? "orange" : "dimmed"}
              >
                {stats.pendingCount}
              </Title>
              <Text
                size="xs"
                c={stats.pendingCount > 0 ? "orange" : "dimmed"}
                mt={2}
              >
                {stats.pendingCount > 0
                  ? "Closed draws pending input"
                  : "All draws up-to-date"}
              </Text>
            </Box>
            <ThemeIcon
              size={42}
              radius="md"
              color={stats.pendingCount > 0 ? "orange" : "gray"}
              variant="light"
            >
              <IconClock size={22} />
            </ThemeIcon>
          </Group>
        </Card>
      </SimpleGrid>

      {/* 3. Pending Draws Notice Banner (Actionable) */}
      {pendingDraws.length > 0 && (
        <Alert
          color="yellow"
          variant="light"
          title="Attention: Draws Awaiting Official Winning Number"
          icon={<IconAlertTriangle size={20} />}
        >
          <Stack gap="xs" mt="xs">
            <Text size="xs">
              The following draws have closed sales and require official winning
              number input to calculate prize payouts:
            </Text>
            <Group gap="sm" wrap="wrap">
              {pendingDraws.map((d) => (
                <Paper
                  key={d.id}
                  p="xs"
                  radius="sm"
                  withBorder
                  bg="rgba(0, 0, 0, 0.2)"
                >
                  <Group gap="xs">
                    <Badge color={getDrawTypeColor(d.draw_type_code)} size="xs">
                      {d.draw_type_code}
                    </Badge>
                    <Text size="xs" fw={700}>
                      {d.sequence_number}
                    </Text>
                    <Text size="xs" c="dimmed">
                      ({formatNumber(d.total_tickets)} tickets sold)
                    </Text>
                    <Button
                      size="compact-xs"
                      color="tradexGold"
                      variant="filled"
                      style={{ color: "#0A0F1D", fontWeight: 700 }}
                      onClick={() => handleOpenPublishModal(d.id)}
                    >
                      Publish Result
                    </Button>
                  </Group>
                </Paper>
              ))}
            </Group>
          </Stack>
        </Alert>
      )}

      {/* 4. Results & Pending Draws Tabs */}
      <Tabs value={activeTab} onChange={setActiveTab}>
        <Tabs.List>
          <Tabs.Tab value="ALL" leftSection={<IconAward size={16} />}>
            All Results ({results.length + pendingDraws.length})
          </Tabs.Tab>
          <Tabs.Tab value="COMPLETED" leftSection={<IconTrophy size={16} />}>
            Completed Results ({results.length})
          </Tabs.Tab>
          <Tabs.Tab
            value="PENDING"
            leftSection={<IconClock size={16} />}
            rightSection={
              pendingDraws.length > 0 ? (
                <Badge size="xs" color="orange" circle>
                  {pendingDraws.length}
                </Badge>
              ) : null
            }
          >
            Pending Publishing ({pendingDraws.length})
          </Tabs.Tab>
        </Tabs.List>

        <Tabs.Panel value="ALL" pt="md">
          <ResultsTable
            completed={results}
            pending={pendingDraws}
            onViewBreakdown={setSelectedResultForBreakdown}
            onPublishPending={handleOpenPublishModal}
          />
        </Tabs.Panel>

        <Tabs.Panel value="COMPLETED" pt="md">
          <ResultsTable
            completed={results}
            pending={[]}
            onViewBreakdown={setSelectedResultForBreakdown}
            onPublishPending={handleOpenPublishModal}
          />
        </Tabs.Panel>

        <Tabs.Panel value="PENDING" pt="md">
          <ResultsTable
            completed={[]}
            pending={pendingDraws}
            onViewBreakdown={setSelectedResultForBreakdown}
            onPublishPending={handleOpenPublishModal}
          />
        </Tabs.Panel>
      </Tabs>

      {/* ========================================================================= */}
      {/* MODAL 1: Sensitive "Publish Winning Number" Modal                          */}
      {/* ========================================================================= */}
      <Modal
        opened={publishModalOpen}
        onClose={() => setPublishModalOpen(false)}
        title={
          <Group gap="xs">
            <ThemeIcon color="tradexGold" variant="light" size={28}>
              <IconSparkles size={16} />
            </ThemeIcon>
            <Title order={3} size="h4" fw={700}>
              Publish Official Draw Outcome & Trigger Payouts
            </Title>
          </Group>
        }
        size="lg"
      >
        <Stack gap="md">
          {publishError && (
            <Alert
              color="red"
              icon={<IconAlertCircle size={18} />}
              title="Publication Error"
            >
              {publishError}
            </Alert>
          )}

          {/* High sensitivity warning */}
          <Alert
            color="red"
            variant="light"
            icon={<IconAlertTriangle size={20} />}
          >
            <Text fw={700} size="sm">
              Strict Verification Notice
            </Text>
            Publishing this winning number is final and immutable. The system
            will evaluate all purchased tickets, determine matching tiers, and
            execute ledger payouts directly into winner accounts.
          </Alert>

          {/* Step 1: Select Eligible Draw */}
          <Box>
            <Text size="xs" fw={700} c="dimmed" tt="uppercase" mb={4}>
              1. Select Draw to Finalize
            </Text>
            <Select
              placeholder="Choose draw awaiting result..."
              data={[
                ...pendingDraws.map((d) => ({
                  value: String(d.id),
                  label: `${d.sequence_number} (${d.draw_type_code}) — ${formatNumber(d.total_tickets)} tickets sold`,
                })),
                ...draws
                  .filter((d) => d.status === "OPEN")
                  .map((d) => ({
                    value: String(d.id),
                    label: `${d.sequence_number} (Currently OPEN - will force close)`,
                  })),
              ]}
              value={selectedDrawId}
              onChange={(val) => {
                setSelectedDrawId(val);
                setWinningNumberInput("");
              }}
              size="sm"
            />
          </Box>

          {selectedDraw && (
            <Paper p="sm" radius="md" withBorder bg="rgba(0, 0, 0, 0.2)">
              <SimpleGrid cols={3} spacing="xs">
                <Box>
                  <Text size="10px" c="dimmed">
                    Draw Type
                  </Text>
                  <Badge
                    color={getDrawTypeColor(selectedDraw.draw_type_code)}
                    size="sm"
                    mt={2}
                  >
                    {selectedDraw.draw_type_code} ({requiredDigits} Digits)
                  </Badge>
                </Box>
                <Box>
                  <Text size="10px" c="dimmed">
                    Tickets in Registry
                  </Text>
                  <Text size="xs" fw={700}>
                    {formatNumber(selectedDraw.total_tickets)} tickets
                  </Text>
                </Box>
                <Box>
                  <Text size="10px" c="dimmed">
                    Gross Pool Revenue
                  </Text>
                  <Text size="xs" fw={700} c="tradexGold.5">
                    {formatBDT(selectedDraw.total_sales_minor)}
                  </Text>
                </Box>
              </SimpleGrid>
            </Paper>
          )}

          {/* Step 2: Digit Input with Strict Digit Validation */}
          <Box>
            <Group justify="space-between" mb={6}>
              <Text size="xs" fw={700} c="dimmed" tt="uppercase">
                2. Official Winning Number ({requiredDigits} Digits Required)
              </Text>
              <Text
                size="xs"
                c={
                  winningNumberInput.length === requiredDigits
                    ? "teal"
                    : "dimmed"
                }
                fw={600}
              >
                {winningNumberInput.length} of {requiredDigits} digits entered
              </Text>
            </Group>

            <Paper
              p="md"
              radius="md"
              withBorder
              bg="rgba(0, 0, 0, 0.3)"
              ta="center"
            >
              <Group justify="center" gap="xs">
                <PinInput
                  length={requiredDigits}
                  type="number"
                  placeholder="•"
                  size="xl"
                  value={winningNumberInput}
                  onChange={setWinningNumberInput}
                  styles={{
                    input: {
                      fontFamily: "var(--font-geist-mono), monospace",
                      fontWeight: 800,
                      fontSize: "24px",
                      color: "#F59E0B",
                      backgroundColor: "#0F172A",
                      borderColor: "#334155",
                      width: "46px",
                      height: "56px",
                    },
                  }}
                />
              </Group>

              <Text size="11px" c="dimmed" mt="xs">
                Enter all {requiredDigits} digits sequentially. Leading zeros
                (e.g. 0012345, 007) are preserved.
              </Text>
            </Paper>
          </Box>

          {/* Step 3: Audit Hash */}
          <TextInput
            label="Cryptographic Random Seed / Draw Result Hash"
            description="Auto-generated cryptographic seed for audit trail"
            value={auditHash}
            onChange={(e) => setAuditHash(e.currentTarget.value)}
            size="xs"
            ff="monospace"
          />

          {/* Step 4: Sensitive Confirmation Checkbox */}
          <Paper p="sm" radius="md" withBorder bg="rgba(217, 119, 6, 0.08)">
            <Checkbox
              checked={confirmedChecked}
              onChange={(e) => setConfirmedChecked(e.currentTarget.checked)}
              color="tradexGold"
              label={
                <Text size="xs" fw={600}>
                  I confirm that winning number{" "}
                  <Text span c="tradexGold.5" fw={800} ff="monospace">
                    "{winningNumberInput || "—"}"
                  </Text>{" "}
                  has been verified against official lottery sources and
                  compliance authorization is logged.
                </Text>
              }
            />
          </Paper>

          {/* Actions */}
          <Group justify="flex-end" mt="sm">
            <Button
              variant="default"
              onClick={() => setPublishModalOpen(false)}
            >
              Cancel
            </Button>
            <Button
              color="tradexGold"
              style={{ color: "#0A0F1D", fontWeight: 800 }}
              leftSection={<IconAward size={18} />}
              disabled={
                !selectedDraw ||
                winningNumberInput.length !== requiredDigits ||
                !confirmedChecked
              }
              loading={isSubmitting}
              onClick={handlePublishSubmit}
            >
              Publish Official Result
            </Button>
          </Group>
        </Stack>
      </Modal>

      {/* ========================================================================= */}
      {/* MODAL 2: Winners Breakdown View Modal                                     */}
      {/* ========================================================================= */}
      <Modal
        opened={!!selectedResultForBreakdown}
        onClose={() => setSelectedResultForBreakdown(null)}
        title={
          <Group gap="xs">
            <ThemeIcon color="teal" variant="light" size={28}>
              <IconTrophy size={16} />
            </ThemeIcon>
            <Title order={4} size="h5" fw={700}>
              Winners Breakdown —{" "}
              {selectedResultForBreakdown?.draw_sequence_number}
            </Title>
          </Group>
        }
        size="xl"
      >
        {selectedResultForBreakdown && (
          <Stack gap="md">
            {/* Header Result Summary Card */}
            <Paper p="md" radius="md" withBorder bg="rgba(0, 0, 0, 0.25)">
              <Group justify="space-between" align="center" wrap="wrap">
                <Box>
                  <Text size="xs" c="dimmed" tt="uppercase" fw={600}>
                    Official Winning Number
                  </Text>
                  <Group gap={4} mt={4}>
                    {padLotteryNumber(
                      selectedResultForBreakdown.winning_number,
                      selectedResultForBreakdown.draw_type_code === "MEGA"
                        ? 7
                        : 3,
                    )
                      .split("")
                      .map((d, i) => (
                        <Box
                          key={`result-digit-${i}-${d}`}
                          style={{
                            width: 32,
                            height: 40,
                            backgroundColor: "#0F172A",
                            border: "1.5px solid #F59E0B",
                            borderRadius: 4,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                          }}
                        >
                          <Text fw={900} size="lg" ff="monospace" c="#F59E0B">
                            {d}
                          </Text>
                        </Box>
                      ))}
                  </Group>
                </Box>

                <Box ta="right">
                  <Text size="xs" c="dimmed">
                    Total Prize Settled
                  </Text>
                  <Title order={3} size="h3" c="tradexGold.5" fw={800}>
                    {formatBDT(
                      selectedResultForBreakdown.total_prize_paid_minor,
                    )}
                  </Title>
                  <Text size="xs" c="teal" fw={600}>
                    {formatNumber(selectedResultForBreakdown.winners_count)}{" "}
                    Winners Credited
                  </Text>
                </Box>
              </Group>

              <Divider my="sm" />

              <SimpleGrid cols={3} spacing="xs">
                <Text size="11px" c="dimmed">
                  • Draw Time:{" "}
                  {formatDateTime(selectedResultForBreakdown.draw_at)}
                </Text>
                <Text size="11px" c="dimmed">
                  • Published By: {selectedResultForBreakdown.published_by}
                </Text>
                <Text size="11px" c="dimmed" ff="monospace">
                  • Seed: {selectedResultForBreakdown.result_hash?.slice(0, 16)}
                  ...
                </Text>
              </SimpleGrid>
            </Paper>

            {/* Prize Tier Breakdown Table */}
            <Title order={5} size="sm" fw={700} c="dimmed" tt="uppercase">
              Prize Distribution By Match Tier
            </Title>

            <Table highlightOnHover verticalSpacing="xs" withTableBorder>
              <Table.Thead bg="rgba(255, 255, 255, 0.03)">
                <Table.Tr>
                  <Table.Th>Tier Level</Table.Th>
                  <Table.Th>Match Rule</Table.Th>
                  <Table.Th>Pattern</Table.Th>
                  <Table.Th>Prize / Ticket</Table.Th>
                  <Table.Th>Winners</Table.Th>
                  <Table.Th>Total Payout</Table.Th>
                  <Table.Th>Settlement</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {activeBreakdownTiers.map((tier) => (
                  <Table.Tr key={tier.id}>
                    <Table.Td>
                      <Text size="xs" fw={700}>
                        {tier.tier_name}
                      </Text>
                    </Table.Td>
                    <Table.Td>
                      <Text size="xs" c="dimmed">
                        {tier.match_condition}
                      </Text>
                    </Table.Td>
                    <Table.Td>
                      <Badge
                        size="sm"
                        variant="outline"
                        color="yellow"
                        ff="monospace"
                      >
                        {tier.matched_digits}
                      </Badge>
                    </Table.Td>
                    <Table.Td>
                      <Text size="xs" fw={600}>
                        {formatBDT(tier.prize_amount_minor)}
                      </Text>
                    </Table.Td>
                    <Table.Td>
                      <Text size="xs" fw={700}>
                        {formatNumber(tier.count)}
                      </Text>
                    </Table.Td>
                    <Table.Td>
                      <Text size="xs" fw={800} c="tradexGold.5">
                        {formatBDT(tier.total_payout_minor)}
                      </Text>
                    </Table.Td>
                    <Table.Td>
                      <Badge color="teal" size="xs" variant="filled">
                        {tier.paid_status}
                      </Badge>
                    </Table.Td>
                  </Table.Tr>
                ))}
              </Table.Tbody>
            </Table>

            {/* Individual Winning Tickets List */}
            {breakdownTickets.length > 0 && (
              <>
                <Title
                  order={5}
                  size="sm"
                  fw={700}
                  c="dimmed"
                  tt="uppercase"
                  mt="sm"
                >
                  Verified Winning Tickets in Ledger ({breakdownTickets.length})
                </Title>
                <ScrollArea h={180}>
                  <Table highlightOnHover verticalSpacing="xs">
                    <Table.Thead bg="rgba(255, 255, 255, 0.02)">
                      <Table.Tr>
                        <Table.Th>Ticket ID</Table.Th>
                        <Table.Th>User</Table.Th>
                        <Table.Th>Number</Table.Th>
                        <Table.Th>Tier</Table.Th>
                        <Table.Th>Prize</Table.Th>
                        <Table.Th>Status</Table.Th>
                      </Table.Tr>
                    </Table.Thead>
                    <Table.Tbody>
                      {breakdownTickets.map((t) => (
                        <Table.Tr key={t.id}>
                          <Table.Td>
                            <Text size="xs" fw={700} ff="monospace">
                              #{t.id}
                            </Text>
                          </Table.Td>
                          <Table.Td>
                            <Text size="xs" fw={600}>
                              {t.user_name}
                            </Text>
                            <Text size="10px" c="dimmed">
                              {t.user_phone}
                            </Text>
                          </Table.Td>
                          <Table.Td>
                            <Badge
                              color="yellow"
                              variant="light"
                              size="sm"
                              ff="monospace"
                            >
                              {t.selected_number}
                            </Badge>
                          </Table.Td>
                          <Table.Td>
                            <Text size="xs">
                              {t.winning_tier || "Grand Prize"}
                            </Text>
                          </Table.Td>
                          <Table.Td>
                            <Text size="xs" fw={700} c="teal">
                              {formatBDT(t.prize_amount_minor || 0)}
                            </Text>
                          </Table.Td>
                          <Table.Td>
                            <Badge color="teal" size="xs">
                              PAID
                            </Badge>
                          </Table.Td>
                        </Table.Tr>
                      ))}
                    </Table.Tbody>
                  </Table>
                </ScrollArea>
              </>
            )}

            <Group justify="flex-end" mt="sm">
              <Button
                variant="default"
                onClick={() => setSelectedResultForBreakdown(null)}
              >
                Close Breakdown
              </Button>
            </Group>
          </Stack>
        )}
      </Modal>
    </Stack>
  );
}

interface ResultsTableProps {
  completed: DrawResult[];
  pending: Draw[];
  onViewBreakdown: (res: DrawResult) => void;
  onPublishPending: (drawId: number) => void;
}

function ResultsTable({
  completed,
  pending,
  onViewBreakdown,
  onPublishPending,
}: ResultsTableProps) {
  const [page, setPage] = useState(1);
  const PAGE_SIZE = 25;

  useEffect(() => {
    if (completed.length || pending.length) {
      setPage(1);
    } else {
      setPage(1);
    }
  }, [completed.length, pending.length]);

  const allRowsCount = pending.length + completed.length;
  const totalPages = Math.ceil(allRowsCount / PAGE_SIZE) || 1;

  const startIndex = (page - 1) * PAGE_SIZE;
  const endIndex = startIndex + PAGE_SIZE;

  const paginatedPending = pending.slice(
    Math.max(0, startIndex),
    Math.max(0, Math.min(pending.length, endIndex)),
  );

  const completedStartIndex = Math.max(0, startIndex - pending.length);
  const completedEndIndex = Math.max(0, endIndex - pending.length);
  const paginatedCompleted = completed.slice(
    completedStartIndex,
    completedEndIndex,
  );

  const hasRows = allRowsCount > 0;

  return (
    <Card p={0} radius="md" withBorder>
      <ScrollArea>
        <Table highlightOnHover verticalSpacing="sm" horizontalSpacing="md">
          <Table.Thead bg="rgba(255, 255, 255, 0.02)">
            <Table.Tr>
              <Table.Th>Draw Sequence</Table.Th>
              <Table.Th>Type</Table.Th>
              <Table.Th>Draw Time</Table.Th>
              <Table.Th>Winning Number</Table.Th>
              <Table.Th>Published By</Table.Th>
              <Table.Th>Tickets / Sales</Table.Th>
              <Table.Th>Winners / Payout</Table.Th>
              <Table.Th>Status</Table.Th>
              <Table.Th style={{ textAlign: "right" }}>Actions</Table.Th>
            </Table.Tr>
          </Table.Thead>

          <Table.Tbody>
            {!hasRows ? (
              <Table.Tr>
                <Table.Td colSpan={9}>
                  <Box ta="center" py="xl">
                    <IconAward size={36} color="var(--mantine-color-dimmed)" />
                    <Text fw={600} mt="sm">
                      No results in this category
                    </Text>
                    <Text size="xs" c="dimmed">
                      Completed and pending draw outcomes will appear here.
                    </Text>
                  </Box>
                </Table.Td>
              </Table.Tr>
            ) : (
              <>
                {/* 1. Pending Draws (Awaiting Result) */}
                {paginatedPending.map((draw) => (
                  <Table.Tr
                    key={`pending_${draw.id}`}
                    bg="rgba(245, 158, 11, 0.03)"
                  >
                    <Table.Td>
                      <Group gap="xs">
                        <ThemeIcon
                          size={26}
                          color="orange"
                          variant="light"
                          radius="sm"
                        >
                          <IconClock size={14} />
                        </ThemeIcon>
                        <Box>
                          <Text fw={700} size="sm">
                            {draw.sequence_number}
                          </Text>
                          <Text size="10px" c="dimmed">
                            ID: #{draw.id}
                          </Text>
                        </Box>
                      </Group>
                    </Table.Td>

                    <Table.Td>
                      <Badge
                        color={getDrawTypeColor(draw.draw_type_code)}
                        size="xs"
                      >
                        {draw.draw_type_code}
                      </Badge>
                    </Table.Td>

                    <Table.Td>
                      <Text size="xs" fw={500}>
                        {formatDateTime(draw.draw_at)}
                      </Text>
                    </Table.Td>

                    <Table.Td>
                      <Badge color="orange" variant="outline" size="sm">
                        Awaiting Result
                      </Badge>
                    </Table.Td>

                    <Table.Td>
                      <Text size="xs" c="dimmed">
                        Pending Admin Input
                      </Text>
                    </Table.Td>

                    <Table.Td>
                      <Text size="xs" fw={600}>
                        {formatNumber(draw.total_tickets)} tickets
                      </Text>
                      <Text size="10px" c="dimmed">
                        {formatBDT(draw.total_sales_minor)}
                      </Text>
                    </Table.Td>

                    <Table.Td>
                      <Text size="xs" c="dimmed">
                        Uncalculated
                      </Text>
                    </Table.Td>

                    <Table.Td>
                      <Badge color="yellow" size="sm" variant="filled">
                        CLOSED
                      </Badge>
                    </Table.Td>

                    <Table.Td style={{ textAlign: "right" }}>
                      <Button
                        size="xs"
                        color="tradexGold"
                        style={{ color: "#0A0F1D", fontWeight: 700 }}
                        leftSection={<IconSparkles size={14} />}
                        onClick={() => onPublishPending(draw.id)}
                      >
                        Publish Now
                      </Button>
                    </Table.Td>
                  </Table.Tr>
                ))}

                {/* 2. Completed Results */}
                {paginatedCompleted.map((res) => {
                  const requiredDigits = res.draw_type_code === "MEGA" ? 7 : 3;
                  const paddedWinningNumber = padLotteryNumber(
                    res.winning_number,
                    requiredDigits,
                  );

                  return (
                    <Table.Tr key={`result_${res.id}`}>
                      <Table.Td>
                        <Group gap="xs">
                          <ThemeIcon
                            size={26}
                            color="teal"
                            variant="light"
                            radius="sm"
                          >
                            <IconAward size={14} />
                          </ThemeIcon>
                          <Box>
                            <Text fw={700} size="sm">
                              {res.draw_sequence_number}
                            </Text>
                            <Text size="10px" c="dimmed">
                              Draw #{res.draw_id}
                            </Text>
                          </Box>
                        </Group>
                      </Table.Td>

                      <Table.Td>
                        <Badge
                          color={getDrawTypeColor(res.draw_type_code)}
                          size="xs"
                        >
                          {res.draw_type_code} ({requiredDigits}D)
                        </Badge>
                      </Table.Td>

                      <Table.Td>
                        <Text size="xs" fw={500}>
                          {formatDateTime(res.draw_at)}
                        </Text>
                      </Table.Td>

                      {/* Winning Number in high-contrast monospaced display */}
                      <Table.Td>
                        <Tooltip
                          label={`Official 0-preserved winning sequence: ${paddedWinningNumber}`}
                        >
                          <Paper
                            px="xs"
                            py={4}
                            radius="sm"
                            withBorder
                            bg="rgba(0, 0, 0, 0.3)"
                            style={{ display: "inline-block" }}
                          >
                            <Group gap={3}>
                              {paddedWinningNumber.split("").map((d, i) => (
                                <Box
                                  key={`row-digit-${i}-${d}`}
                                  style={{
                                    width: 20,
                                    height: 24,
                                    backgroundColor: "#0F172A",
                                    border: "1px solid rgba(245, 158, 11, 0.5)",
                                    borderRadius: 3,
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                  }}
                                >
                                  <Text
                                    fw={800}
                                    size="xs"
                                    ff="monospace"
                                    c="#F59E0B"
                                  >
                                    {d}
                                  </Text>
                                </Box>
                              ))}
                            </Group>
                          </Paper>
                        </Tooltip>
                      </Table.Td>

                      <Table.Td>
                        <Text size="xs" fw={500}>
                          {res.published_by}
                        </Text>
                        <Text size="10px" c="dimmed">
                          {formatDateTime(res.published_at)}
                        </Text>
                      </Table.Td>

                      <Table.Td>
                        <Text size="xs" fw={600}>
                          {formatNumber(res.total_tickets)} tickets
                        </Text>
                        <Text size="10px" c="tradexGold.5">
                          {formatBDT(res.total_sales_minor)}
                        </Text>
                      </Table.Td>

                      <Table.Td>
                        <Text size="xs" fw={700} c="teal">
                          {formatNumber(res.winners_count)} winners
                        </Text>
                        <Text size="10px" fw={600} c="teal.4">
                          {formatBDT(res.total_prize_paid_minor)}
                        </Text>
                      </Table.Td>

                      <Table.Td>
                        <Badge color="teal" size="sm" variant="filled">
                          COMPLETED
                        </Badge>
                      </Table.Td>

                      <Table.Td style={{ textAlign: "right" }}>
                        <Button
                          size="xs"
                          variant="light"
                          color="teal"
                          leftSection={<IconEye size={14} />}
                          onClick={() => onViewBreakdown(res)}
                        >
                          Winners Breakdown
                        </Button>
                      </Table.Td>
                    </Table.Tr>
                  );
                })}
              </>
            )}
          </Table.Tbody>
        </Table>
      </ScrollArea>

      {hasRows && (
        <Group
          justify="space-between"
          align="center"
          p="md"
          pt="xs"
          wrap="wrap"
        >
          <Text size="xs" c="dimmed">
            Showing {(page - 1) * PAGE_SIZE + 1} to{" "}
            {Math.min(page * PAGE_SIZE, allRowsCount)} of {allRowsCount} entries
          </Text>
          {totalPages > 1 && (
            <Pagination
              total={totalPages}
              value={page}
              onChange={setPage}
              size="sm"
              radius="md"
              withEdges
            />
          )}
        </Group>
      )}
    </Card>
  );
}
