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
  Modal,
  NumberInput,
  Pagination,
  Paper,
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
  UnstyledButton,
} from "@mantine/core";
import { DateTimePicker } from "@mantine/dates";
import "@mantine/dates/styles.css";
import { useDebouncedValue } from "@mantine/hooks";
import { notifications } from "@mantine/notifications";
import {
  IconAlertCircle,
  IconAlertTriangle,
  IconCalendarEvent,
  IconCheck,
  IconDice,
  IconEye,
  IconLayoutGrid,
  IconList,
  IconLock,
  IconPlayerPlay,
  IconPlus,
  IconRefresh,
  IconSearch,
  IconSparkles,
  IconTrophy,
  IconX,
} from "@tabler/icons-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type React from "react";
import { useCallback, useMemo, useState } from "react";
import { EmptyState } from "@/components/common/EmptyState";
import { LiveCountdown } from "@/components/common/LiveCountdown";
import { useCreateDraw, useUpdateDrawStatus } from "@/lib/api";
import {
  formatBDT,
  formatDateTime,
  formatNumber,
  formatTimeOnly,
  getDrawStatusColor,
  getDrawTypeColor,
} from "@/lib/formatters";
import { useLotteryStore } from "@/lib/store";
import type { Draw, DrawStatus, DrawTypeCode } from "@/types/lottery";

const PAGE_SIZE = 25;

const DRAW_NAV_LINKS = [
  { label: "All Draws", href: "/draws", icon: IconTrophy, filter: "ALL" },
  {
    label: "Mega Draw",
    href: "/draws/mega",
    icon: IconSparkles,
    filter: "MEGA",
  },
  {
    label: "Daily Draw",
    href: "/draws/daily",
    icon: IconCalendarEvent,
    filter: "DAILY",
  },
  {
    label: "Hourly Draw",
    href: "/draws/hourly",
    icon: IconDice,
    filter: "HOURLY",
  },
  {
    label: "Numbers Matrix",
    href: "/draws/numbers",
    icon: IconList,
    filter: "ALL",
  },
];

interface DrawsViewProps {
  initialType?: "ALL" | "MEGA" | "DAILY" | "HOURLY";
}

export function DrawsView({ initialType = "ALL" }: DrawsViewProps) {
  const pathname = usePathname();
  const createDrawMutation = useCreateDraw();
  const updateDrawStatusMutation = useUpdateDrawStatus();
  const { draws, addDraw, updateDrawStatus } = useLotteryStore();

  // Determine active filter from pathname or initialType
  const activeTypeFilter = useMemo(() => {
    if (pathname === "/draws/mega") return "MEGA";
    if (pathname === "/draws/daily") return "DAILY";
    if (pathname === "/draws/hourly") return "HOURLY";
    return initialType;
  }, [pathname, initialType]);

  const [statusFilter, setStatusFilter] = useState<string>("ALL");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [debouncedSearchQuery] = useDebouncedValue(searchQuery, 250);
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

  const handleCreateDraw = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (!newSequenceNumber.trim()) {
      setFormError("Draw sequence number is required");
      return;
    }

    const drawInput = {
      draw_type_code: newDrawType,
      sequence_number: newSequenceNumber.trim(),
      ticket_price_minor: Number(newTicketPriceBDT) * 100,
      sale_open_at: newSaleOpenAt?.toISOString() || new Date().toISOString(),
      sale_close_at:
        newSaleCloseAt?.toISOString() ||
        new Date(Date.now() + 86400000).toISOString(),
      draw_at:
        newDrawAt?.toISOString() ||
        new Date(Date.now() + 90000000).toISOString(),
      status: newInitialStatus,
    };

    try {
      await createDrawMutation.mutateAsync(drawInput);
      const created = addDraw(drawInput);

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

  const handleOpenDraw = useCallback(
    async (draw: Draw) => {
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
    },
    [updateDrawStatusMutation, updateDrawStatus],
  );

  const confirmCloseDraw = useCallback(async () => {
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
  }, [selectedDrawForClose, updateDrawStatusMutation, updateDrawStatus]);

  const confirmCancelDraw = useCallback(async () => {
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
  }, [selectedDrawForCancel, updateDrawStatusMutation, updateDrawStatus]);

  const filteredDraws = useMemo(() => {
    const q = debouncedSearchQuery.toLowerCase().trim();
    return draws.filter((draw) => {
      if (
        activeTypeFilter !== "ALL" &&
        draw.draw_type_code !== activeTypeFilter
      )
        return false;
      if (statusFilter !== "ALL" && draw.status !== statusFilter) return false;
      if (q) {
        const matchSeq = draw.sequence_number.toLowerCase().includes(q);
        const matchId = String(draw.id).includes(q);
        const matchName = draw.draw_type_name.toLowerCase().includes(q);
        if (!matchSeq && !matchId && !matchName) return false;
      }
      return true;
    });
  }, [draws, activeTypeFilter, statusFilter, debouncedSearchQuery]);

  const [page, setPage] = useState(1);
  const totalPages = Math.ceil(filteredDraws.length / PAGE_SIZE) || 1;
  const currentPage = Math.min(page, totalPages);

  const paginatedDraws = useMemo(() => {
    const startIndex = (currentPage - 1) * PAGE_SIZE;
    return filteredDraws.slice(startIndex, startIndex + PAGE_SIZE);
  }, [filteredDraws, currentPage]);

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

    return {
      openCount: openDraws.length,
      totalTickets,
      totalSalesMinor,
      activeMega,
      activeDaily,
    };
  }, [draws]);

  const handleSelectDetails = useCallback((d: Draw) => {
    setSelectedDrawForDetails(d);
  }, []);

  const handleSelectClose = useCallback((d: Draw) => {
    setSelectedDrawForClose(d);
  }, []);

  const handleSelectCancel = useCallback((d: Draw) => {
    setSelectedDrawForCancel(d);
  }, []);

  return (
    <Stack gap="lg">
      {/* 1. Header Card */}
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
                <IconTrophy size={20} stroke={2} />
              </ThemeIcon>
              <Box>
                <Title order={2} fw={800} c="var(--mantine-color-text)">
                  Draw Operations & Lifecycle
                </Title>
                <Text size="xs" c="dimmed" fw={600}>
                  Schedule, activate, monitor ticket sales, and close draws
                  across Mega, Daily, and Hourly pools.
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
                  message: "Draw schedule synchronized.",
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
              leftSection={<IconPlus size={16} />}
              onClick={() => setCreateModalOpen(true)}
            >
              Schedule New Draw
            </Button>
          </Group>
        </Group>

        {/* High-level KPIs */}
        <SimpleGrid cols={{ base: 1, sm: 2, md: 4 }} spacing="md" mt="lg">
          <Paper p="sm" radius="md" withBorder bg="var(--surface-card)">
            <Group justify="space-between" mb={2}>
              <Text size="xs" c="dimmed" fw={700} tt="uppercase">
                Active Open Draws
              </Text>
              <Badge color="teal" size="sm" variant="filled">
                Live Now
              </Badge>
            </Group>
            <Text size="xl" fw={800} c="teal.4" className="font-tabular">
              {stats.openCount} Pools
            </Text>
            <Text size="11px" c="dimmed" mt={2}>
              Accepting ticket purchases
            </Text>
          </Paper>

          <Paper p="sm" radius="md" withBorder bg="var(--surface-card)">
            <Group justify="space-between" mb={2}>
              <Text size="xs" c="dimmed" fw={700} tt="uppercase">
                Total Tickets Sold
              </Text>
              <Badge color="blue" size="sm" variant="light">
                Across Active
              </Badge>
            </Group>
            <Text size="xl" fw={800} c="blue.4" className="font-tabular">
              {formatNumber(stats.totalTickets)}
            </Text>
            <Text size="11px" c="dimmed" mt={2}>
              Platform-wide sales volume
            </Text>
          </Paper>

          <Paper p="sm" radius="md" withBorder bg="var(--surface-card)">
            <Group justify="space-between" mb={2}>
              <Text size="xs" c="dimmed" fw={700} tt="uppercase">
                Total Sales Revenue
              </Text>
              <Badge color="tradexGold" size="sm" variant="light">
                Gross Pool
              </Badge>
            </Group>
            <Text
              size="xl"
              fw={800}
              c="var(--color-gold-400)"
              className="font-tabular"
            >
              {formatBDT(stats.totalSalesMinor)}
            </Text>
            <Text size="11px" c="dimmed" mt={2}>
              Active ticket turnover
            </Text>
          </Paper>

          <Paper p="sm" radius="md" withBorder bg="var(--surface-card)">
            <Group justify="space-between" mb={2}>
              <Text size="xs" c="dimmed" fw={700} tt="uppercase">
                Next Closing Draw
              </Text>
              <Badge color="orange" size="sm" variant="light">
                Countdown
              </Badge>
            </Group>
            {stats.activeMega ? (
              <Box mt={2}>
                <Text size="sm" fw={700} c="orange.4" truncate>
                  {stats.activeMega.sequence_number}
                </Text>
                <LiveCountdown targetDate={stats.activeMega.sale_close_at} />
              </Box>
            ) : (
              <Text size="xs" c="dimmed" mt={8}>
                No upcoming closes
              </Text>
            )}
          </Paper>
        </SimpleGrid>

        {/* Clean Path-Based Navigation Buttons (Zero ?x=y Query Routes) */}
        <Group gap="xs" wrap="wrap" mt="lg">
          {DRAW_NAV_LINKS.map((link) => {
            const active =
              link.href === "/draws"
                ? pathname === "/draws"
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

      {/* 2. Filters & View Controls Bar */}
      <Card
        p="md"
        radius="lg"
        withBorder
        bg="var(--surface-card, var(--mantine-color-default))"
      >
        <Group justify="space-between" wrap="wrap" gap="md">
          <Group gap="md" wrap="wrap" flex={1}>
            <TextInput
              placeholder="Search draw sequence, ID..."
              leftSection={<IconSearch size={16} />}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.currentTarget.value)}
              w={{ base: "100%", sm: 260 }}
              size="sm"
            />

            <Select
              placeholder="Filter by Status"
              value={statusFilter}
              onChange={(val) => setStatusFilter(val || "ALL")}
              data={[
                { value: "ALL", label: "All Statuses" },
                { value: "OPEN", label: "🟢 Open / Selling" },
                { value: "SCHEDULED", label: "📅 Scheduled" },
                { value: "CLOSED", label: "🔒 Closed" },
                { value: "PROCESSING", label: "⚙️ Processing" },
                { value: "COMPLETED", label: "🏆 Completed" },
                { value: "CANCELLED", label: "❌ Cancelled" },
              ]}
              w={{ base: "100%", sm: 200 }}
              size="sm"
            />
          </Group>

          <SegmentedControl
            value={viewMode}
            onChange={(val) => setViewMode(val as "table" | "cards")}
            data={[
              {
                value: "table",
                label: (
                  <Group gap={4}>
                    <IconList size={15} />
                    <Text size="xs">Table View</Text>
                  </Group>
                ),
              },
              {
                value: "cards",
                label: (
                  <Group gap={4}>
                    <IconLayoutGrid size={15} />
                    <Text size="xs">Grid Cards</Text>
                  </Group>
                ),
              },
            ]}
            size="xs"
            radius="md"
          />
        </Group>
      </Card>

      {/* 3. Main Data Container: Table or Cards */}
      {paginatedDraws.length === 0 ? (
        <EmptyState
          icon={IconTrophy}
          title="No Draws Match Current Filters"
          description="Try selecting a different draw type or resetting the search query."
          actionLabel="Clear Filters"
          onAction={() => {
            setStatusFilter("ALL");
            setSearchQuery("");
          }}
        />
      ) : viewMode === "table" ? (
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
                  <Table.Th>Draw Type & ID</Table.Th>
                  <Table.Th>Sequence #</Table.Th>
                  <Table.Th>Status</Table.Th>
                  <Table.Th>Price / Ticket</Table.Th>
                  <Table.Th>Tickets Sold</Table.Th>
                  <Table.Th>Gross Revenue</Table.Th>
                  <Table.Th>Sale Closes In</Table.Th>
                  <Table.Th>Draw Scheduled At</Table.Th>
                  <Table.Th ta="right">Actions</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {paginatedDraws.map((draw) => (
                  <Table.Tr key={draw.id}>
                    <Table.Td>
                      <Group gap="xs">
                        <Badge
                          color={getDrawTypeColor(draw.draw_type_code)}
                          variant="light"
                          size="sm"
                        >
                          {draw.draw_type_code}
                        </Badge>
                        <Text size="xs" c="dimmed" className="font-tabular">
                          #{draw.id}
                        </Text>
                      </Group>
                    </Table.Td>

                    <Table.Td>
                      <Text size="sm" fw={700} className="font-tabular">
                        {draw.sequence_number}
                      </Text>
                      <Text size="11px" c="dimmed">
                        {draw.draw_type_name}
                      </Text>
                    </Table.Td>

                    <Table.Td>
                      <Badge
                        color={getDrawStatusColor(draw.status)}
                        variant="dot"
                        size="md"
                      >
                        {draw.status}
                      </Badge>
                    </Table.Td>

                    <Table.Td>
                      <Text size="sm" fw={600} className="font-tabular">
                        {formatBDT(draw.ticket_price_minor)}
                      </Text>
                    </Table.Td>

                    <Table.Td>
                      <Text size="sm" fw={700} className="font-tabular">
                        {formatNumber(draw.total_tickets || 0)}
                      </Text>
                    </Table.Td>

                    <Table.Td>
                      <Text
                        size="sm"
                        fw={700}
                        c="var(--color-gold-400)"
                        className="font-tabular"
                      >
                        {formatBDT(draw.total_sales_minor || 0)}
                      </Text>
                    </Table.Td>

                    <Table.Td>
                      {draw.status === "OPEN" ? (
                        <LiveCountdown targetDate={draw.sale_close_at} />
                      ) : (
                        <Text size="xs" c="dimmed">
                          {formatDateTime(draw.sale_close_at)}
                        </Text>
                      )}
                    </Table.Td>

                    <Table.Td>
                      <Text size="xs" c="dimmed">
                        {formatDateTime(draw.draw_at)}
                      </Text>
                    </Table.Td>

                    <Table.Td ta="right">
                      <Group gap="xs" justify="flex-end">
                        <Tooltip label="View Full Details">
                          <ActionIcon
                            variant="light"
                            color="blue"
                            size="sm"
                            onClick={() => handleSelectDetails(draw)}
                          >
                            <IconEye size={15} />
                          </ActionIcon>
                        </Tooltip>

                        {draw.status === "SCHEDULED" && (
                          <Tooltip label="Open Ticket Sales">
                            <ActionIcon
                              variant="filled"
                              color="teal"
                              size="sm"
                              onClick={() => handleOpenDraw(draw)}
                            >
                              <IconPlayerPlay size={15} />
                            </ActionIcon>
                          </Tooltip>
                        )}

                        {draw.status === "OPEN" && (
                          <Tooltip label="Halt & Close Sales">
                            <ActionIcon
                              variant="filled"
                              color="yellow"
                              size="sm"
                              onClick={() => handleSelectClose(draw)}
                            >
                              <IconLock size={15} />
                            </ActionIcon>
                          </Tooltip>
                        )}

                        {draw.status !== "COMPLETED" &&
                          draw.status !== "CANCELLED" && (
                            <Tooltip label="Cancel Draw & Refund">
                              <ActionIcon
                                variant="subtle"
                                color="red"
                                size="sm"
                                onClick={() => handleSelectCancel(draw)}
                              >
                                <IconX size={15} />
                              </ActionIcon>
                            </Tooltip>
                          )}
                      </Group>
                    </Table.Td>
                  </Table.Tr>
                ))}
              </Table.Tbody>
            </Table>
          </Table.ScrollContainer>

          {totalPages > 1 && (
            <Group justify="space-between" p="md">
              <Text size="xs" c="dimmed">
                Showing {paginatedDraws.length} of {filteredDraws.length} draws
              </Text>
              <Pagination
                total={totalPages}
                value={currentPage}
                onChange={setPage}
                size="sm"
                color="tradexGold"
              />
            </Group>
          )}
        </Card>
      ) : (
        <SimpleGrid cols={{ base: 1, sm: 2, lg: 3 }} spacing="md">
          {paginatedDraws.map((draw) => (
            <Card
              key={draw.id}
              p="md"
              radius="lg"
              withBorder
              bg="var(--surface-card)"
              className="glass-card-hover"
            >
              <Group justify="space-between" mb="xs">
                <Badge
                  color={getDrawTypeColor(draw.draw_type_code)}
                  variant="filled"
                  size="md"
                >
                  {draw.draw_type_code} DRAW
                </Badge>
                <Badge
                  color={getDrawStatusColor(draw.status)}
                  variant="dot"
                  size="sm"
                >
                  {draw.status}
                </Badge>
              </Group>

              <Title order={4} fw={800} mb={4} className="font-tabular">
                #{draw.sequence_number}
              </Title>
              <Text size="xs" c="dimmed" mb="md">
                {draw.draw_type_name} • ID: {draw.id}
              </Text>

              <Divider my="xs" />

              <SimpleGrid cols={2} spacing="xs" mb="md">
                <Box>
                  <Text size="11px" c="dimmed">
                    Ticket Price
                  </Text>
                  <Text size="sm" fw={700} className="font-tabular">
                    {formatBDT(draw.ticket_price_minor)}
                  </Text>
                </Box>
                <Box>
                  <Text size="11px" c="dimmed">
                    Tickets Sold
                  </Text>
                  <Text size="sm" fw={700} className="font-tabular">
                    {formatNumber(draw.total_tickets || 0)}
                  </Text>
                </Box>
                <Box>
                  <Text size="11px" c="dimmed">
                    Total Pool
                  </Text>
                  <Text
                    size="sm"
                    fw={700}
                    c="var(--color-gold-400)"
                    className="font-tabular"
                  >
                    {formatBDT(draw.total_sales_minor || 0)}
                  </Text>
                </Box>
                <Box>
                  <Text size="11px" c="dimmed">
                    Draw Execution
                  </Text>
                  <Text size="xs" fw={600}>
                    {formatTimeOnly(draw.draw_at)}
                  </Text>
                </Box>
              </SimpleGrid>

              {draw.status === "OPEN" && (
                <Paper
                  p="xs"
                  radius="md"
                  withBorder
                  bg="var(--surface-card)"
                  mb="md"
                >
                  <Text size="10px" c="dimmed" fw={700} tt="uppercase" mb={2}>
                    Sales Closes In
                  </Text>
                  <LiveCountdown targetDate={draw.sale_close_at} />
                </Paper>
              )}

              <Group justify="space-between" mt="auto">
                <Button
                  variant="light"
                  size="xs"
                  leftSection={<IconEye size={14} />}
                  onClick={() => handleSelectDetails(draw)}
                >
                  Inspect
                </Button>

                {draw.status === "SCHEDULED" && (
                  <Button
                    color="teal"
                    size="xs"
                    leftSection={<IconPlayerPlay size={14} />}
                    onClick={() => handleOpenDraw(draw)}
                  >
                    Open Sales
                  </Button>
                )}

                {draw.status === "OPEN" && (
                  <Button
                    color="yellow"
                    size="xs"
                    leftSection={<IconLock size={14} />}
                    onClick={() => handleSelectClose(draw)}
                  >
                    Close Sales
                  </Button>
                )}
              </Group>
            </Card>
          ))}
        </SimpleGrid>
      )}

      {/* 4. Details Modal */}
      {selectedDrawForDetails && (
        <Modal
          opened={!!selectedDrawForDetails}
          onClose={() => setSelectedDrawForDetails(null)}
          title={
            <Group gap="xs">
              <IconTrophy size={20} color="var(--color-gold-400)" />
              <Title order={4} fw={800}>
                Draw Details: #{selectedDrawForDetails.sequence_number}
              </Title>
            </Group>
          }
          size="lg"
          radius="md"
        >
          <Stack gap="md">
            <SimpleGrid cols={2} spacing="md">
              <Paper p="sm" radius="md" withBorder>
                <Text size="xs" c="dimmed">
                  Draw ID
                </Text>
                <Text size="sm" fw={700} className="font-tabular">
                  {selectedDrawForDetails.id}
                </Text>
              </Paper>
              <Paper p="sm" radius="md" withBorder>
                <Text size="xs" c="dimmed">
                  Type
                </Text>
                <Badge
                  color={getDrawTypeColor(
                    selectedDrawForDetails.draw_type_code,
                  )}
                  size="sm"
                >
                  {selectedDrawForDetails.draw_type_code}
                </Badge>
              </Paper>
              <Paper p="sm" radius="md" withBorder>
                <Text size="xs" c="dimmed">
                  Status
                </Text>
                <Badge
                  color={getDrawStatusColor(selectedDrawForDetails.status)}
                  size="sm"
                >
                  {selectedDrawForDetails.status}
                </Badge>
              </Paper>
              <Paper p="sm" radius="md" withBorder>
                <Text size="xs" c="dimmed">
                  Ticket Price
                </Text>
                <Text size="sm" fw={700} className="font-tabular">
                  {formatBDT(selectedDrawForDetails.ticket_price_minor)}
                </Text>
              </Paper>
            </SimpleGrid>

            <Paper p="sm" radius="md" withBorder>
              <Text size="xs" c="dimmed" mb={4}>
                Timeline & Milestones
              </Text>
              <Stack gap={4}>
                <Group justify="space-between">
                  <Text size="xs">Sale Open:</Text>
                  <Text size="xs" fw={600}>
                    {formatDateTime(selectedDrawForDetails.sale_open_at)}
                  </Text>
                </Group>
                <Group justify="space-between">
                  <Text size="xs">Sale Close:</Text>
                  <Text size="xs" fw={600}>
                    {formatDateTime(selectedDrawForDetails.sale_close_at)}
                  </Text>
                </Group>
                <Group justify="space-between">
                  <Text size="xs">Scheduled Draw:</Text>
                  <Text size="xs" fw={600}>
                    {formatDateTime(selectedDrawForDetails.draw_at)}
                  </Text>
                </Group>
              </Stack>
            </Paper>
          </Stack>
        </Modal>
      )}

      {/* 5. Create Draw Modal */}
      <Modal
        opened={createModalOpen}
        onClose={() => setCreateModalOpen(false)}
        title={
          <Group gap="xs">
            <IconPlus size={20} color="var(--color-gold-400)" />
            <Title order={4} fw={800}>
              Schedule New Draw
            </Title>
          </Group>
        }
        size="lg"
        radius="md"
      >
        <form onSubmit={handleCreateDraw}>
          <Stack gap="md">
            {formError && (
              <Alert
                icon={<IconAlertTriangle size={16} />}
                title="Creation Error"
                color="red"
                variant="light"
              >
                {formError}
              </Alert>
            )}

            <Select
              label="Draw Pool Type"
              required
              value={newDrawType}
              onChange={handleTypeChange}
              data={[
                {
                  value: "MEGA",
                  label: "🌟 Mega Draw (7-digit, 100K ৳ jackpot)",
                },
                {
                  value: "DAILY",
                  label: "📅 Daily Draw (7-digit, 10K ৳ prize)",
                },
                {
                  value: "HOURLY",
                  label: "⚡ Hourly Draw (7-digit, 1K ৳ rapid)",
                },
              ]}
            />

            <TextInput
              label="Draw Sequence Code / Identifier"
              required
              value={newSequenceNumber}
              onChange={(e) => setNewSequenceNumber(e.currentTarget.value)}
              placeholder="e.g. MEGA-2026-086"
            />

            <NumberInput
              label="Ticket Price (BDT ৳)"
              required
              min={1}
              value={newTicketPriceBDT}
              onChange={setNewTicketPriceBDT}
            />

            <DateTimePicker
              label="Sales Open Timestamp"
              required
              value={newSaleOpenAt ? newSaleOpenAt.toISOString() : null}
              onChange={(val) => setNewSaleOpenAt(val ? new Date(val) : null)}
            />

            <DateTimePicker
              label="Sales Close Timestamp"
              required
              value={newSaleCloseAt ? newSaleCloseAt.toISOString() : null}
              onChange={(val) => setNewSaleCloseAt(val ? new Date(val) : null)}
            />

            <DateTimePicker
              label="Draw Execution Timestamp"
              required
              value={newDrawAt ? newDrawAt.toISOString() : null}
              onChange={(val) => setNewDrawAt(val ? new Date(val) : null)}
            />

            <Select
              label="Initial Status"
              value={newInitialStatus}
              onChange={(v) =>
                setNewInitialStatus((v as DrawStatus) || "SCHEDULED")
              }
              data={[
                {
                  value: "SCHEDULED",
                  label: "📅 SCHEDULED (Wait for open time)",
                },
                { value: "OPEN", label: "🟢 OPEN (Immediate live sales)" },
              ]}
            />

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
                c="#070B14"
                fw={700}
                loading={createDrawMutation.isPending}
              >
                Create Draw
              </Button>
            </Group>
          </Stack>
        </form>
      </Modal>

      {/* 6. Close Modal Confirmation */}
      {selectedDrawForClose && (
        <Modal
          opened={!!selectedDrawForClose}
          onClose={() => setSelectedDrawForClose(null)}
          title={<Title order={4}>Confirm Draw Sales Closure</Title>}
          radius="md"
        >
          <Stack gap="md">
            <Text size="sm">
              Are you sure you want to close ticket sales for{" "}
              <strong>#{selectedDrawForClose.sequence_number}</strong>?
            </Text>
            <Group justify="flex-end">
              <Button
                variant="default"
                onClick={() => setSelectedDrawForClose(null)}
              >
                Cancel
              </Button>
              <Button
                color="yellow"
                onClick={confirmCloseDraw}
                loading={updateDrawStatusMutation.isPending}
              >
                Confirm Close Sales
              </Button>
            </Group>
          </Stack>
        </Modal>
      )}

      {/* 7. Cancel Modal Confirmation */}
      {selectedDrawForCancel && (
        <Modal
          opened={!!selectedDrawForCancel}
          onClose={() => setSelectedDrawForCancel(null)}
          title={<Title order={4}>Confirm Draw Cancellation</Title>}
          radius="md"
        >
          <Stack gap="md">
            <Text size="sm">
              Cancelling{" "}
              <strong>#{selectedDrawForCancel.sequence_number}</strong> will
              halt operations and flag tickets for automatic refunds.
            </Text>
            <Group justify="flex-end">
              <Button
                variant="default"
                onClick={() => setSelectedDrawForCancel(null)}
              >
                Go Back
              </Button>
              <Button
                color="red"
                onClick={confirmCancelDraw}
                loading={updateDrawStatusMutation.isPending}
              >
                Cancel Draw
              </Button>
            </Group>
          </Stack>
        </Modal>
      )}
    </Stack>
  );
}

export default DrawsView;
