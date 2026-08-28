"use client";

import {
  ActionIcon,
  Alert,
  Badge,
  Box,
  Button,
  Card,
  Divider,
  Group,
  Menu,
  Modal,
  NumberInput,
  Pagination,
  Paper,
  ScrollArea,
  SegmentedControl,
  Select,
  SimpleGrid,
  Stack,
  Table,
  Text,
  TextInput,
  ThemeIcon,
  Title,
  Tooltip,
} from "@mantine/core";
import { DateTimePicker } from "@mantine/dates";
import { notifications } from "@mantine/notifications";
import {
  IconAlertCircle,
  IconAlertTriangle,
  IconCalendarEvent,
  IconCheck,
  IconChevronDown,
  IconClock,
  IconCoin,
  IconDice,
  IconEye,
  IconLayoutGrid,
  IconList,
  IconLock,
  IconLockOpen,
  IconPlayerPlay,
  IconPlus,
  IconRefresh,
  IconSearch,
  IconSparkles,
  IconTrophy,
  IconX,
} from "@tabler/icons-react";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import { useCreateDraw, useUpdateDrawStatus } from "@/lib/api";
import {
  formatBDT,
  formatDateTime,
  formatNumber,
  formatTimeOnly,
  formatTimeRemaining,
  getDrawStatusColor,
  getDrawTypeColor,
} from "@/lib/formatters";
import { useLotteryStore } from "@/lib/store";
import type { Draw, DrawStatus, DrawTypeCode } from "@/types/lottery";

export default function DrawsPage() {
  const createDrawMutation = useCreateDraw();
  const updateDrawStatusMutation = useUpdateDrawStatus();
  const { draws, addDraw, updateDrawStatus } = useLotteryStore();

  // Filter States
  const [typeFilter, setTypeFilter] = useState<string>("ALL");
  const [statusFilter, setStatusFilter] = useState<string>("ALL");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [viewMode, setViewMode] = useState<"table" | "cards">("table");

  // Modal States
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [selectedDrawForDetails, setSelectedDrawForDetails] =
    useState<Draw | null>(null);
  const [selectedDrawForClose, setSelectedDrawForClose] = useState<Draw | null>(
    null,
  );
  const [selectedDrawForCancel, setSelectedDrawForCancel] =
    useState<Draw | null>(null);

  // Form State for "Create Draw"
  const [newDrawType, setNewDrawType] = useState<DrawTypeCode>("MEGA");
  const [newSequenceNumber, setNewSequenceNumber] = useState("MEGA-2026-086");
  const [newTicketPriceBDT, setNewTicketPriceBDT] = useState<number | string>(
    50,
  );
  const [newSaleOpenAt, setNewSaleOpenAt] = useState<Date | null>(new Date());
  const [newSaleCloseAt, setNewSaleCloseAt] = useState<Date | null>(
    new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
  );
  const [newDrawAt, setNewDrawAt] = useState<Date | null>(
    new Date(Date.now() + 7 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
  );
  const [newInitialStatus, setNewInitialStatus] =
    useState<DrawStatus>("SCHEDULED");
  const [formError, setFormError] = useState<string | null>(null);

  // Handle draw type change in Create Modal
  const handleTypeChange = (val: string | null) => {
    if (!val) return;
    const type = val as DrawTypeCode;
    setNewDrawType(type);

    const now = new Date();
    if (type === "MEGA") {
      setNewSequenceNumber(`MEGA-2026-0${Math.floor(Math.random() * 20 + 85)}`);
      setNewTicketPriceBDT(50);
      setNewSaleOpenAt(now);
      setNewSaleCloseAt(new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000));
      setNewDrawAt(
        new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      );
    } else if (type === "DAILY") {
      setNewSequenceNumber(
        `DAILY-2026-${Math.floor(Math.random() * 50 + 245)}`,
      );
      setNewTicketPriceBDT(20);
      setNewSaleOpenAt(now);
      const closeDaily = new Date(now);
      closeDaily.setHours(19, 30, 0, 0);
      const drawDaily = new Date(now);
      drawDaily.setHours(20, 0, 0, 0);
      setNewSaleCloseAt(closeDaily);
      setNewDrawAt(drawDaily);
    } else {
      setNewSequenceNumber(
        `HOURLY-20260828-${Math.floor(Math.random() * 4 + 20)}`,
      );
      setNewTicketPriceBDT(10);
      setNewSaleOpenAt(now);
      setNewSaleCloseAt(new Date(now.getTime() + 50 * 60 * 1000));
      setNewDrawAt(new Date(now.getTime() + 60 * 60 * 1000));
    }
  };

  // Submit Create Draw
  const handleCreateDraw = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (!newSequenceNumber.trim()) {
      setFormError("Sequence number is required.");
      return;
    }
    const priceNum = Number(newTicketPriceBDT);
    if (Number.isNaN(priceNum) || priceNum <= 0) {
      setFormError("Ticket price must be greater than 0 BDT.");
      return;
    }
    if (!newSaleOpenAt || !newSaleCloseAt || !newDrawAt) {
      setFormError(
        "All schedule dates (Sale Open, Sale Close, Draw Time) are required.",
      );
      return;
    }
    if (newSaleOpenAt.getTime() >= newSaleCloseAt.getTime()) {
      setFormError("Sale Opening time must be earlier than Sale Closing time.");
      return;
    }
    if (newSaleCloseAt.getTime() > newDrawAt.getTime()) {
      setFormError("Draw time cannot be earlier than Sale Closing time.");
      return;
    }

    try {
      await createDrawMutation.mutateAsync({
        draw_type_code: newDrawType,
        sequence_number: newSequenceNumber.trim().toUpperCase(),
        ticket_price_minor: Math.round(priceNum * 100),
        sale_open_at: newSaleOpenAt.toISOString(),
        sale_close_at: newSaleCloseAt.toISOString(),
        draw_at: newDrawAt.toISOString(),
        status: newInitialStatus,
      });

      const created = addDraw({
        draw_type_code: newDrawType,
        sequence_number: newSequenceNumber.trim().toUpperCase(),
        ticket_price_minor: Math.round(priceNum * 100),
        sale_open_at: newSaleOpenAt.toISOString(),
        sale_close_at: newSaleCloseAt.toISOString(),
        draw_at: newDrawAt.toISOString(),
        status: newInitialStatus,
      });

      notifications.show({
        title: "Draw Created Successfully",
        message: `${created.draw_type_code} draw #${created.sequence_number} is now ${created.status}.`,
        color: "teal",
        icon: <IconCheck size={18} />,
      });

      setCreateModalOpen(false);
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : "Failed to create draw";
      setFormError(message);
    }
  };

  // Status transitions
  const handleOpenDraw = async (draw: Draw) => {
    try {
      await updateDrawStatusMutation.mutateAsync({
        drawId: draw.id,
        status: "OPEN",
      });
      updateDrawStatus(draw.id, "OPEN");
      notifications.show({
        title: "Draw Sales Opened",
        message: `Tickets are now on sale for ${draw.sequence_number}.`,
        color: "teal",
        icon: <IconCheck size={18} />,
      });
    } catch (err: unknown) {
      notifications.show({
        title: "Failed to Open Draw",
        message: err instanceof Error ? err.message : "Status update failed",
        color: "red",
        icon: <IconAlertCircle size={18} />,
      });
    }
  };

  const confirmCloseDraw = async () => {
    if (!selectedDrawForClose) return;
    try {
      await updateDrawStatusMutation.mutateAsync({
        drawId: selectedDrawForClose.id,
        status: "CLOSED",
      });
      updateDrawStatus(selectedDrawForClose.id, "CLOSED");
      notifications.show({
        title: "Draw Closed",
        message: `Sales halted for ${selectedDrawForClose.sequence_number}. Ready for result publication.`,
        color: "yellow",
        icon: <IconLock size={18} />,
      });
      setSelectedDrawForClose(null);
    } catch (err: unknown) {
      notifications.show({
        title: "Failed to Close Draw",
        message: err instanceof Error ? err.message : "Status update failed",
        color: "red",
        icon: <IconAlertCircle size={18} />,
      });
    }
  };

  const confirmCancelDraw = async () => {
    if (!selectedDrawForCancel) return;
    try {
      await updateDrawStatusMutation.mutateAsync({
        drawId: selectedDrawForCancel.id,
        status: "CANCELLED",
      });
      updateDrawStatus(selectedDrawForCancel.id, "CANCELLED");
      notifications.show({
        title: "Draw Cancelled",
        message: `${selectedDrawForCancel.sequence_number} was cancelled. Refund batch logged.`,
        color: "red",
        icon: <IconAlertCircle size={18} />,
      });
      setSelectedDrawForCancel(null);
    } catch (err: unknown) {
      notifications.show({
        title: "Failed to Cancel Draw",
        message: err instanceof Error ? err.message : "Status update failed",
        color: "red",
        icon: <IconAlertCircle size={18} />,
      });
    }
  };

  // Filtered draws
  const filteredDraws = useMemo(() => {
    return draws.filter((draw) => {
      if (typeFilter !== "ALL" && draw.draw_type_code !== typeFilter)
        return false;
      if (statusFilter !== "ALL" && draw.status !== statusFilter) return false;
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const matchSeq = draw.sequence_number.toLowerCase().includes(q);
        const matchId = String(draw.id).includes(q);
        const matchName = draw.draw_type_name.toLowerCase().includes(q);
        if (!matchSeq && !matchId && !matchName) return false;
      }
      return true;
    });
  }, [draws, typeFilter, statusFilter, searchQuery]);

  const [page, setPage] = useState(1);
  const PAGE_SIZE = 25;

  // Reset page when filters change
  useEffect(() => {
    if (searchQuery || statusFilter || typeFilter) {
      setPage(1);
    } else {
      setPage(1);
    }
  }, [searchQuery, statusFilter, typeFilter]);

  const totalPages = Math.ceil(filteredDraws.length / PAGE_SIZE) || 1;
  const paginatedDraws = useMemo(() => {
    const startIndex = (page - 1) * PAGE_SIZE;
    return filteredDraws.slice(startIndex, startIndex + PAGE_SIZE);
  }, [filteredDraws, page]);

  // High-level statistics
  const stats = useMemo(() => {
    const openDraws = draws.filter((d) => d.status === "OPEN");
    const totalTickets = draws.reduce(
      (acc, d) => acc + Number(d.total_tickets || 0),
      0,
    );
    const totalSalesMinor = draws.reduce(
      (acc, d) => acc + Number(d.total_sales_minor || 0),
      0,
    );

    const activeMega = draws.find(
      (d) => d.draw_type_code === "MEGA" && d.status === "OPEN",
    );
    const activeDaily = draws.find(
      (d) => d.draw_type_code === "DAILY" && d.status === "OPEN",
    );
    const activeHourly = draws.find(
      (d) => d.draw_type_code === "HOURLY" && d.status === "OPEN",
    );

    return {
      openCount: openDraws.length,
      totalTickets,
      totalSalesMinor,
      activeMega,
      activeDaily,
      activeHourly,
    };
  }, [draws]);

  return (
    <Stack gap="lg">
      {/* 1. Header with Breadcrumb, Title & Primary Action */}
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
                <IconTrophy
                  size={20}
                  color="var(--mantine-color-tradexGold-6)"
                />
              </ThemeIcon>
              <Box>
                <Title order={2} size="h3" fw={700}>
                  Draw Management
                </Title>
                <Text size="xs" c="dimmed">
                  Configure, schedule, monitor, and transition lottery draws
                  across Mega, Daily, and Hourly tiers.
                </Text>
              </Box>
            </Group>
          </Box>

          <Group gap="sm">
            <Tooltip label="Refresh draw list from ledger">
              <ActionIcon
                variant="default"
                size="lg"
                onClick={() => {
                  notifications.show({
                    title: "Draws Synchronized",
                    message: "Latest tickets and draw states retrieved.",
                    color: "blue",
                  });
                }}
              >
                <IconRefresh size={18} />
              </ActionIcon>
            </Tooltip>

            <Button
              leftSection={<IconPlus size={18} />}
              color="tradexGold"
              variant="filled"
              style={{ color: "#0A0F1D", fontWeight: 700 }}
              onClick={() => setCreateModalOpen(true)}
            >
              Create Draw
            </Button>
          </Group>
        </Group>
      </Card>

      {/* 2. Operational Metrics Overview */}
      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} spacing="md">
        {/* Metric 1: Active Draws */}
        <Card p="md" radius="md" withBorder>
          <Group justify="space-between" align="flex-start">
            <Box>
              <Text size="xs" c="dimmed" fw={600} tt="uppercase">
                Active Live Draws
              </Text>
              <Title order={3} size="h2" fw={800} mt={4}>
                {stats.openCount}
              </Title>
              <Text size="xs" c="teal" mt={2} fw={500}>
                ● Currently accepting ticket orders
              </Text>
            </Box>
            <ThemeIcon size={42} radius="md" color="teal" variant="light">
              <IconLockOpen size={22} />
            </ThemeIcon>
          </Group>
        </Card>

        {/* Metric 2: Active Mega Draw */}
        <Card p="md" radius="md" withBorder>
          <Group justify="space-between" align="flex-start">
            <Box>
              <Group gap={6}>
                <Badge size="xs" color="violet">
                  Mega 7-Digit
                </Badge>
                <Text size="xs" c="dimmed">
                  {stats.activeMega
                    ? stats.activeMega.sequence_number
                    : "None Open"}
                </Text>
              </Group>
              <Title order={3} size="h2" fw={800} mt={4}>
                {stats.activeMega
                  ? formatNumber(stats.activeMega.total_tickets)
                  : "0"}
              </Title>
              <Text size="xs" c="dimmed">
                {stats.activeMega
                  ? `Closes: ${formatTimeRemaining(stats.activeMega.sale_close_at)}`
                  : "Scheduled"}
              </Text>
            </Box>
            <ThemeIcon size={42} radius="md" color="violet" variant="light">
              <IconSparkles size={22} />
            </ThemeIcon>
          </Group>
        </Card>

        {/* Metric 3: Active Daily Draw */}
        <Card p="md" radius="md" withBorder>
          <Group justify="space-between" align="flex-start">
            <Box>
              <Group gap={6}>
                <Badge size="xs" color="blue">
                  Daily 3-Digit
                </Badge>
                <Text size="xs" c="dimmed">
                  {stats.activeDaily
                    ? stats.activeDaily.sequence_number
                    : "None Open"}
                </Text>
              </Group>
              <Title order={3} size="h2" fw={800} mt={4}>
                {stats.activeDaily
                  ? formatNumber(stats.activeDaily.total_tickets)
                  : "0"}
              </Title>
              <Text size="xs" c="dimmed">
                {stats.activeDaily
                  ? `Closes: ${formatTimeOnly(stats.activeDaily.sale_close_at)}`
                  : "Scheduled"}
              </Text>
            </Box>
            <ThemeIcon size={42} radius="md" color="blue" variant="light">
              <IconCalendarEvent size={22} />
            </ThemeIcon>
          </Group>
        </Card>

        {/* Metric 4: Total Gross Ticket Sales */}
        <Card p="md" radius="md" withBorder>
          <Group justify="space-between" align="flex-start">
            <Box>
              <Text size="xs" c="dimmed" fw={600} tt="uppercase">
                Gross Platform Sales
              </Text>
              <Title order={3} size="h2" fw={800} mt={4} c="tradexGold.5">
                {formatBDT(stats.totalSalesMinor, { compact: true })}
              </Title>
              <Text size="xs" c="dimmed">
                {formatNumber(stats.totalTickets)} total tickets across all
                draws
              </Text>
            </Box>
            <ThemeIcon size={42} radius="md" color="tradexGold" variant="light">
              <IconCoin size={22} />
            </ThemeIcon>
          </Group>
        </Card>
      </SimpleGrid>

      {/* 3. Filters Bar & View Controls */}
      <Card p="md" radius="md" withBorder>
        <Stack gap="sm">
          <Group justify="space-between" wrap="wrap">
            <Group gap="sm" style={{ flex: 1, minWidth: 280 }}>
              <TextInput
                placeholder="Search by Sequence (e.g. MEGA-2026) or ID..."
                leftSection={<IconSearch size={16} />}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.currentTarget.value)}
                style={{ flex: 1 }}
                size="sm"
              />

              <Select
                placeholder="Draw Type"
                data={[
                  { value: "ALL", label: "All Types (Mega, Daily, Hourly)" },
                  { value: "MEGA", label: "Mega 7-Digit" },
                  { value: "DAILY", label: "Daily 3-Digit" },
                  { value: "HOURLY", label: "Hourly 3-Digit" },
                ]}
                value={typeFilter}
                onChange={(val) => setTypeFilter(val || "ALL")}
                size="sm"
                w={200}
              />

              <Select
                placeholder="Draw Status"
                data={[
                  { value: "ALL", label: "All Statuses" },
                  { value: "OPEN", label: "OPEN" },
                  { value: "SCHEDULED", label: "SCHEDULED" },
                  { value: "CLOSED", label: "CLOSED" },
                  { value: "COMPLETED", label: "COMPLETED" },
                  { value: "CANCELLED", label: "CANCELLED" },
                ]}
                value={statusFilter}
                onChange={(val) => setStatusFilter(val || "ALL")}
                size="sm"
                w={170}
              />

              {(typeFilter !== "ALL" ||
                statusFilter !== "ALL" ||
                searchQuery) && (
                <Button
                  variant="subtle"
                  color="gray"
                  size="sm"
                  leftSection={<IconX size={14} />}
                  onClick={() => {
                    setTypeFilter("ALL");
                    setStatusFilter("ALL");
                    setSearchQuery("");
                  }}
                >
                  Clear
                </Button>
              )}
            </Group>

            <Group gap="xs">
              <Text size="xs" c="dimmed">
                Showing {filteredDraws.length} draws
              </Text>
              <SegmentedControl
                size="xs"
                value={viewMode}
                onChange={(val) => {
                  if (val === "table" || val === "cards") setViewMode(val);
                }}
                data={[
                  {
                    value: "table",
                    label: (
                      <Group gap={4}>
                        <IconList size={14} />
                        <span>Table</span>
                      </Group>
                    ),
                  },
                  {
                    value: "cards",
                    label: (
                      <Group gap={4}>
                        <IconLayoutGrid size={14} />
                        <span>Cards</span>
                      </Group>
                    ),
                  },
                ]}
              />
            </Group>
          </Group>
        </Stack>
      </Card>

      {/* 4. Main Content: Data Table or Cards View */}
      {viewMode === "table" ? (
        <Card p={0} radius="md" withBorder>
          <ScrollArea>
            <Table highlightOnHover verticalSpacing="sm" horizontalSpacing="md">
              <Table.Thead bg="rgba(255, 255, 255, 0.02)">
                <Table.Tr>
                  <Table.Th>Sequence & ID</Table.Th>
                  <Table.Th>Type</Table.Th>
                  <Table.Th>Status</Table.Th>
                  <Table.Th>Ticket Price</Table.Th>
                  <Table.Th>Tickets Sold</Table.Th>
                  <Table.Th>Total Sales</Table.Th>
                  <Table.Th>Schedule (Open / Close / Draw)</Table.Th>
                  <Table.Th style={{ textAlign: "right" }}>Actions</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {paginatedDraws.length === 0 ? (
                  <Table.Tr>
                    <Table.Td colSpan={8}>
                      <Box ta="center" py="xl">
                        <IconDice
                          size={36}
                          color="var(--mantine-color-dimmed)"
                        />
                        <Text fw={600} mt="sm">
                          No matching draws found
                        </Text>
                        <Text size="xs" c="dimmed">
                          Try adjusting your search filters or create a new
                          draw.
                        </Text>
                      </Box>
                    </Table.Td>
                  </Table.Tr>
                ) : (
                  paginatedDraws.map((draw) => (
                    <Table.Tr key={draw.id}>
                      {/* Sequence & ID */}
                      <Table.Td>
                        <Group gap="xs">
                          <ThemeIcon
                            size={28}
                            radius="sm"
                            color={getDrawTypeColor(draw.draw_type_code)}
                            variant="light"
                          >
                            <IconDice size={16} />
                          </ThemeIcon>
                          <Box>
                            <Text fw={700} size="sm">
                              {draw.sequence_number}
                            </Text>
                            <Text size="11px" c="dimmed" ff="monospace">
                              ID: #{draw.id}
                            </Text>
                          </Box>
                        </Group>
                      </Table.Td>

                      {/* Type Badge */}
                      <Table.Td>
                        <Badge
                          color={getDrawTypeColor(draw.draw_type_code)}
                          variant="light"
                          size="sm"
                        >
                          {draw.draw_type_code === "MEGA"
                            ? "Mega (7-Digit)"
                            : draw.draw_type_code === "DAILY"
                              ? "Daily (3-Digit)"
                              : "Hourly (3-Digit)"}
                        </Badge>
                      </Table.Td>

                      {/* Status Badge */}
                      <Table.Td>
                        <Badge
                          color={getDrawStatusColor(draw.status)}
                          variant="filled"
                          size="sm"
                        >
                          {draw.status}
                        </Badge>
                      </Table.Td>

                      {/* Ticket Price */}
                      <Table.Td>
                        <Text fw={600} size="sm">
                          {formatBDT(draw.ticket_price_minor)}
                        </Text>
                      </Table.Td>

                      {/* Tickets Sold */}
                      <Table.Td>
                        <Box>
                          <Text fw={700} size="sm">
                            {formatNumber(draw.total_tickets)}
                          </Text>
                          <Text size="10px" c="dimmed">
                            tickets
                          </Text>
                        </Box>
                      </Table.Td>

                      {/* Total Sales */}
                      <Table.Td>
                        <Text fw={700} size="sm" c="tradexGold.5">
                          {formatBDT(draw.total_sales_minor)}
                        </Text>
                      </Table.Td>

                      {/* Schedule Timeline */}
                      <Table.Td>
                        <Stack gap={2}>
                          <Text size="11px">
                            <Text span c="dimmed">
                              Closes:{" "}
                            </Text>
                            <Text span fw={600}>
                              {formatDateTime(draw.sale_close_at)}
                            </Text>
                          </Text>
                          <Text size="11px">
                            <Text span c="dimmed">
                              Draw:{" "}
                            </Text>
                            <Text span fw={500}>
                              {formatDateTime(draw.draw_at)}
                            </Text>
                          </Text>
                        </Stack>
                      </Table.Td>

                      {/* Action Menu */}
                      <Table.Td style={{ textAlign: "right" }}>
                        <Group gap={6} justify="flex-end">
                          <Tooltip label="View Draw Overview">
                            <ActionIcon
                              variant="subtle"
                              color="gray"
                              size="sm"
                              onClick={() => setSelectedDrawForDetails(draw)}
                            >
                              <IconEye size={16} />
                            </ActionIcon>
                          </Tooltip>

                          <Menu position="bottom-end" shadow="md" width={180}>
                            <Menu.Target>
                              <ActionIcon variant="default" size="sm">
                                <IconChevronDown size={14} />
                              </ActionIcon>
                            </Menu.Target>

                            <Menu.Dropdown>
                              <Menu.Label>Draw Operations</Menu.Label>
                              <Menu.Item
                                leftSection={<IconEye size={14} />}
                                onClick={() => setSelectedDrawForDetails(draw)}
                              >
                                View Details
                              </Menu.Item>

                              {(draw.status === "SCHEDULED" ||
                                draw.status === "CLOSED") && (
                                <Menu.Item
                                  leftSection={<IconPlayerPlay size={14} />}
                                  color="teal"
                                  onClick={() => handleOpenDraw(draw)}
                                >
                                  Open Sales
                                </Menu.Item>
                              )}

                              {draw.status === "OPEN" && (
                                <Menu.Item
                                  leftSection={<IconLock size={14} />}
                                  color="yellow"
                                  onClick={() => setSelectedDrawForClose(draw)}
                                >
                                  Close Sales
                                </Menu.Item>
                              )}

                              {draw.status !== "CANCELLED" &&
                                draw.status !== "COMPLETED" && (
                                  <>
                                    <Menu.Divider />
                                    <Menu.Item
                                      leftSection={
                                        <IconAlertTriangle size={14} />
                                      }
                                      color="red"
                                      onClick={() =>
                                        setSelectedDrawForCancel(draw)
                                      }
                                    >
                                      Cancel Draw
                                    </Menu.Item>
                                  </>
                                )}
                            </Menu.Dropdown>
                          </Menu>
                        </Group>
                      </Table.Td>
                    </Table.Tr>
                  ))
                )}
              </Table.Tbody>
            </Table>
          </ScrollArea>

          {filteredDraws.length > 0 && (
            <Group
              justify="space-between"
              align="center"
              p="md"
              pt="xs"
              wrap="wrap"
            >
              <Text size="xs" c="dimmed">
                Showing {(page - 1) * PAGE_SIZE + 1} to{" "}
                {Math.min(page * PAGE_SIZE, filteredDraws.length)} of{" "}
                {filteredDraws.length} entries
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
      ) : (
        /* Cards Grid View */
        <Stack gap="md">
          <SimpleGrid cols={{ base: 1, sm: 2, lg: 3 }} spacing="md">
            {paginatedDraws.map((draw) => {
              const isClosingSoon =
                draw.status === "OPEN" &&
                new Date(draw.sale_close_at).getTime() - Date.now() <
                  24 * 60 * 60 * 1000;

              return (
                <Card key={draw.id} p="md" radius="md" withBorder>
                  <Stack gap="sm">
                    <Group justify="space-between" align="flex-start">
                      <Box>
                        <Group gap={6}>
                          <Badge
                            color={getDrawTypeColor(draw.draw_type_code)}
                            size="xs"
                          >
                            {draw.draw_type_code} (
                            {draw.draw_type_code === "MEGA"
                              ? "7 Digits"
                              : "3 Digits"}
                            )
                          </Badge>
                          <Badge
                            color={getDrawStatusColor(draw.status)}
                            size="xs"
                          >
                            {draw.status}
                          </Badge>
                        </Group>
                        <Title order={4} size="h4" fw={700} mt={6}>
                          {draw.sequence_number}
                        </Title>
                      </Box>

                      <Tooltip label="View Details">
                        <ActionIcon
                          variant="subtle"
                          color="gray"
                          onClick={() => setSelectedDrawForDetails(draw)}
                        >
                          <IconEye size={18} />
                        </ActionIcon>
                      </Tooltip>
                    </Group>

                    {draw.status === "OPEN" && (
                      <Alert
                        variant="light"
                        color={isClosingSoon ? "orange" : "blue"}
                        p="xs"
                        icon={<IconClock size={16} />}
                      >
                        <Group justify="space-between">
                          <Text size="xs" fw={600}>
                            Sale closes in:
                          </Text>
                          <Text size="xs" fw={700} ff="monospace">
                            {formatTimeRemaining(draw.sale_close_at)}
                          </Text>
                        </Group>
                      </Alert>
                    )}

                    <Divider />

                    <SimpleGrid cols={2} spacing="xs">
                      <Paper p="xs" radius="sm" withBorder bg="rgba(0,0,0,0.1)">
                        <Text size="10px" c="dimmed" tt="uppercase">
                          Ticket Price
                        </Text>
                        <Text size="sm" fw={700}>
                          {formatBDT(draw.ticket_price_minor)}
                        </Text>
                      </Paper>

                      <Paper p="xs" radius="sm" withBorder bg="rgba(0,0,0,0.1)">
                        <Text size="10px" c="dimmed" tt="uppercase">
                          Tickets Sold
                        </Text>
                        <Text size="sm" fw={700}>
                          {formatNumber(draw.total_tickets)}
                        </Text>
                      </Paper>

                      <Paper
                        p="xs"
                        radius="sm"
                        withBorder
                        bg="rgba(0,0,0,0.1)"
                        style={{ gridColumn: "span 2" }}
                      >
                        <Group justify="space-between">
                          <Text size="10px" c="dimmed" tt="uppercase">
                            Total Revenue Generated
                          </Text>
                          <Text size="sm" fw={800} c="tradexGold.5">
                            {formatBDT(draw.total_sales_minor)}
                          </Text>
                        </Group>
                      </Paper>
                    </SimpleGrid>

                    <Stack gap={3}>
                      <Text size="11px" c="dimmed">
                        • Sale Opens: {formatDateTime(draw.sale_open_at)}
                      </Text>
                      <Text size="11px" c="dimmed">
                        • Sale Closes: {formatDateTime(draw.sale_close_at)}
                      </Text>
                      <Text size="11px" c="dimmed">
                        • Draw Scheduled: {formatDateTime(draw.draw_at)}
                      </Text>
                    </Stack>

                    <Divider />

                    <Group gap="xs" grow>
                      {draw.status === "OPEN" ? (
                        <Button
                          size="xs"
                          variant="light"
                          color="yellow"
                          leftSection={<IconLock size={14} />}
                          onClick={() => setSelectedDrawForClose(draw)}
                        >
                          Close Sales
                        </Button>
                      ) : draw.status === "SCHEDULED" ||
                        draw.status === "CLOSED" ? (
                        <Button
                          size="xs"
                          variant="light"
                          color="teal"
                          leftSection={<IconPlayerPlay size={14} />}
                          onClick={() => handleOpenDraw(draw)}
                        >
                          Open Sales
                        </Button>
                      ) : (
                        <Button size="xs" variant="default" disabled>
                          {draw.status}
                        </Button>
                      )}

                      {draw.status !== "CANCELLED" &&
                        draw.status !== "COMPLETED" && (
                          <Button
                            size="xs"
                            variant="subtle"
                            color="red"
                            onClick={() => setSelectedDrawForCancel(draw)}
                          >
                            Cancel
                          </Button>
                        )}
                    </Group>
                  </Stack>
                </Card>
              );
            })}
          </SimpleGrid>

          {filteredDraws.length > 0 && (
            <Group justify="space-between" align="center" mt="xs" wrap="wrap">
              <Text size="xs" c="dimmed">
                Showing {(page - 1) * PAGE_SIZE + 1} to{" "}
                {Math.min(page * PAGE_SIZE, filteredDraws.length)} of{" "}
                {filteredDraws.length} entries
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
        </Stack>
      )}

      {/* ========================================================================= */}
      {/* MODAL 1: Create Draw Modal                                                */}
      {/* ========================================================================= */}
      <Modal
        opened={createModalOpen}
        onClose={() => setCreateModalOpen(false)}
        title={
          <Group gap="xs">
            <ThemeIcon color="tradexGold" variant="light" size={28}>
              <IconPlus size={16} />
            </ThemeIcon>
            <Title order={3} size="h4" fw={700}>
              Create New Platform Draw
            </Title>
          </Group>
        }
        size="lg"
      >
        <form onSubmit={handleCreateDraw}>
          <Stack gap="md">
            {formError && (
              <Alert
                icon={<IconAlertCircle size={16} />}
                color="red"
                title="Validation Error"
              >
                {formError}
              </Alert>
            )}

            <SimpleGrid cols={{ base: 1, sm: 2 }} spacing="md">
              <Select
                label="Draw Type"
                description="Select lottery category"
                required
                data={[
                  { value: "MEGA", label: "Mega Draw (7-Digit Jackpot)" },
                  { value: "DAILY", label: "Daily Draw (3-Digit Fast)" },
                  { value: "HOURLY", label: "Hourly Draw (3-Digit Instant)" },
                ]}
                value={newDrawType}
                onChange={handleTypeChange}
              />

              <TextInput
                label="Sequence Number"
                description="Official unique code (e.g. MEGA-2026-085)"
                required
                value={newSequenceNumber}
                onChange={(e) => setNewSequenceNumber(e.currentTarget.value)}
              />
            </SimpleGrid>

            <SimpleGrid cols={{ base: 1, sm: 2 }} spacing="md">
              <NumberInput
                label="Ticket Price (BDT)"
                description="Nominal purchase price per entry"
                required
                min={1}
                prefix="৳ "
                value={newTicketPriceBDT}
                onChange={(val) => setNewTicketPriceBDT(val)}
              />

              <Select
                label="Initial Draw Status"
                description="Initial state upon record creation"
                required
                data={[
                  { value: "SCHEDULED", label: "SCHEDULED (Pending start)" },
                  { value: "OPEN", label: "OPEN (Start selling immediately)" },
                ]}
                value={newInitialStatus}
                onChange={(val) =>
                  setNewInitialStatus((val as DrawStatus) || "SCHEDULED")
                }
              />
            </SimpleGrid>

            <Divider label="Draw Lifecycle & Schedule" labelPosition="center" />

            <SimpleGrid cols={{ base: 1, sm: 3 }} spacing="sm">
              <DateTimePicker
                label="Sale Opening"
                description="Users can begin buying"
                required
                value={newSaleOpenAt}
                onChange={(val: string | Date | null) =>
                  setNewSaleOpenAt(
                    val
                      ? typeof val === "string"
                        ? new Date(val)
                        : val
                      : null,
                  )
                }
              />

              <DateTimePicker
                label="Sale Closing"
                description="Cutoff for ticket orders"
                required
                value={newSaleCloseAt}
                onChange={(val: string | Date | null) =>
                  setNewSaleCloseAt(
                    val
                      ? typeof val === "string"
                        ? new Date(val)
                        : val
                      : null,
                  )
                }
              />

              <DateTimePicker
                label="Draw Time"
                description="Winning number generation"
                required
                value={newDrawAt}
                onChange={(val: string | Date | null) =>
                  setNewDrawAt(
                    val
                      ? typeof val === "string"
                        ? new Date(val)
                        : val
                      : null,
                  )
                }
              />
            </SimpleGrid>

            {/* Live Parameter Confirmation Box */}
            <Paper p="sm" radius="md" withBorder bg="rgba(0, 0, 0, 0.2)">
              <Text size="xs" fw={700} c="tradexGold.5" mb={4}>
                Parameters Summary:
              </Text>
              <Group justify="space-between">
                <Text size="xs">
                  Type:{" "}
                  <Text span fw={600}>
                    {newDrawType} (
                    {newDrawType === "MEGA" ? "7 Digits" : "3 Digits"})
                  </Text>
                </Text>
                <Text size="xs">
                  Price:{" "}
                  <Text span fw={600}>
                    ৳{Number(newTicketPriceBDT) || 0}
                  </Text>
                </Text>
                <Text size="xs">
                  Status:{" "}
                  <Text span fw={600}>
                    {newInitialStatus}
                  </Text>
                </Text>
              </Group>
            </Paper>

            <Group justify="flex-end" mt="md">
              <Button
                variant="default"
                onClick={() => setCreateModalOpen(false)}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                color="tradexGold"
                style={{ color: "#0A0F1D", fontWeight: 700 }}
                leftSection={<IconCheck size={16} />}
              >
                Create & Register Draw
              </Button>
            </Group>
          </Stack>
        </form>
      </Modal>

      {/* ========================================================================= */}
      {/* MODAL 2: Close Draw Confirmation Modal                                    */}
      {/* ========================================================================= */}
      <Modal
        opened={!!selectedDrawForClose}
        onClose={() => setSelectedDrawForClose(null)}
        title={
          <Group gap="xs">
            <ThemeIcon color="yellow" variant="light">
              <IconLock size={16} />
            </ThemeIcon>
            <Title order={4} size="h5" fw={700}>
              Confirm Closing Draw Sales
            </Title>
          </Group>
        }
      >
        {selectedDrawForClose && (
          <Stack gap="md">
            <Alert color="yellow" icon={<IconAlertTriangle size={18} />}>
              Closing this draw will immediately halt user ticket purchases. The
              draw will advance to CLOSED status and await official winning
              number publication.
            </Alert>

            <Paper p="sm" radius="md" withBorder bg="rgba(0,0,0,0.15)">
              <Stack gap={6}>
                <Group justify="space-between">
                  <Text size="xs" c="dimmed">
                    Draw Sequence:
                  </Text>
                  <Text size="sm" fw={700}>
                    {selectedDrawForClose.sequence_number}
                  </Text>
                </Group>
                <Group justify="space-between">
                  <Text size="xs" c="dimmed">
                    Total Tickets Sold:
                  </Text>
                  <Text size="sm" fw={700}>
                    {formatNumber(selectedDrawForClose.total_tickets)}
                  </Text>
                </Group>
                <Group justify="space-between">
                  <Text size="xs" c="dimmed">
                    Gross Ticket Revenue:
                  </Text>
                  <Text size="sm" fw={700} c="tradexGold.5">
                    {formatBDT(selectedDrawForClose.total_sales_minor)}
                  </Text>
                </Group>
              </Stack>
            </Paper>

            <Group justify="flex-end">
              <Button
                variant="default"
                onClick={() => setSelectedDrawForClose(null)}
              >
                Dismiss
              </Button>
              <Button color="yellow" onClick={confirmCloseDraw}>
                Halt Sales & Close Draw
              </Button>
            </Group>
          </Stack>
        )}
      </Modal>

      {/* ========================================================================= */}
      {/* MODAL 3: Cancel Draw Confirmation Modal                                   */}
      {/* ========================================================================= */}
      <Modal
        opened={!!selectedDrawForCancel}
        onClose={() => setSelectedDrawForCancel(null)}
        title={
          <Group gap="xs">
            <ThemeIcon color="red" variant="light">
              <IconAlertCircle size={16} />
            </ThemeIcon>
            <Title order={4} size="h5" fw={700} c="red">
              Confirm Draw Cancellation & Refund
            </Title>
          </Group>
        }
      >
        {selectedDrawForCancel && (
          <Stack gap="md">
            <Alert color="red" icon={<IconAlertCircle size={18} />}>
              <Text fw={700} size="sm">
                High-Sensitivity Financial Operation
              </Text>
              Cancelling {selectedDrawForCancel.sequence_number} will mark all{" "}
              {formatNumber(selectedDrawForCancel.total_tickets)} existing
              tickets as REFUNDED. Refund orders will automatically reverse
              funds back into user wallets via ledger entries.
            </Alert>

            <Paper p="sm" radius="md" withBorder>
              <Stack gap={6}>
                <Group justify="space-between">
                  <Text size="xs" c="dimmed">
                    Draw:
                  </Text>
                  <Text size="sm" fw={700}>
                    {selectedDrawForCancel.sequence_number} (ID: #
                    {selectedDrawForCancel.id})
                  </Text>
                </Group>
                <Group justify="space-between">
                  <Text size="xs" c="dimmed">
                    Tickets to Refund:
                  </Text>
                  <Text size="sm" fw={700}>
                    {formatNumber(selectedDrawForCancel.total_tickets)}
                  </Text>
                </Group>
                <Group justify="space-between">
                  <Text size="xs" c="dimmed">
                    Total Refund Liability:
                  </Text>
                  <Text size="sm" fw={700} c="red">
                    {formatBDT(selectedDrawForCancel.total_sales_minor)}
                  </Text>
                </Group>
              </Stack>
            </Paper>

            <Group justify="flex-end">
              <Button
                variant="default"
                onClick={() => setSelectedDrawForCancel(null)}
              >
                Abort
              </Button>
              <Button color="red" onClick={confirmCancelDraw}>
                Authorize Cancellation & Refunds
              </Button>
            </Group>
          </Stack>
        )}
      </Modal>

      {/* ========================================================================= */}
      {/* MODAL 4: Draw Details Overview Modal                                      */}
      {/* ========================================================================= */}
      <Modal
        opened={!!selectedDrawForDetails}
        onClose={() => setSelectedDrawForDetails(null)}
        title={
          <Group gap="xs">
            <ThemeIcon
              color={getDrawTypeColor(
                selectedDrawForDetails?.draw_type_code || "MEGA",
              )}
            >
              <IconTrophy size={16} />
            </ThemeIcon>
            <Title order={4} size="h5" fw={700}>
              Draw Specification — {selectedDrawForDetails?.sequence_number}
            </Title>
          </Group>
        }
        size="lg"
      >
        {selectedDrawForDetails && (
          <Stack gap="md">
            <SimpleGrid cols={2} spacing="md">
              <Paper p="sm" radius="md" withBorder>
                <Text size="xs" c="dimmed">
                  Status
                </Text>
                <Badge
                  color={getDrawStatusColor(selectedDrawForDetails.status)}
                  size="lg"
                  mt={4}
                >
                  {selectedDrawForDetails.status}
                </Badge>
              </Paper>

              <Paper p="sm" radius="md" withBorder>
                <Text size="xs" c="dimmed">
                  Ticket Price
                </Text>
                <Title order={3} size="h4" mt={4}>
                  {formatBDT(selectedDrawForDetails.ticket_price_minor)}
                </Title>
              </Paper>

              <Paper p="sm" radius="md" withBorder>
                <Text size="xs" c="dimmed">
                  Total Tickets Sold
                </Text>
                <Title order={3} size="h4" mt={4}>
                  {formatNumber(selectedDrawForDetails.total_tickets)}
                </Title>
              </Paper>

              <Paper p="sm" radius="md" withBorder>
                <Text size="xs" c="dimmed">
                  Gross Pool Revenue
                </Text>
                <Title order={3} size="h4" mt={4} c="tradexGold.5">
                  {formatBDT(selectedDrawForDetails.total_sales_minor)}
                </Title>
              </Paper>
            </SimpleGrid>

            <Paper p="md" radius="md" withBorder>
              <Title order={5} size="xs" c="dimmed" tt="uppercase" mb="sm">
                Schedule Timetable
              </Title>
              <Stack gap="xs">
                <Group justify="space-between">
                  <Text size="xs">Sale Opening Date & Time:</Text>
                  <Text size="xs" fw={600}>
                    {formatDateTime(selectedDrawForDetails.sale_open_at)}
                  </Text>
                </Group>
                <Group justify="space-between">
                  <Text size="xs">Sale Closing Cutoff:</Text>
                  <Text size="xs" fw={600}>
                    {formatDateTime(selectedDrawForDetails.sale_close_at)}
                  </Text>
                </Group>
                <Group justify="space-between">
                  <Text size="xs">Official Draw Execution:</Text>
                  <Text size="xs" fw={600}>
                    {formatDateTime(selectedDrawForDetails.draw_at)}
                  </Text>
                </Group>
              </Stack>
            </Paper>

            <Group justify="flex-end">
              <Button
                variant="default"
                onClick={() => setSelectedDrawForDetails(null)}
              >
                Close
              </Button>
            </Group>
          </Stack>
        )}
      </Modal>
    </Stack>
  );
}
