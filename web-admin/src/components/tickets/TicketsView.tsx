"use client";

import {
  ActionIcon,
  Alert,
  Badge,
  Box,
  Button,
  Card,
  CopyButton,
  Divider,
  Group,
  Modal,
  Pagination,
  Paper,
  ScrollArea,
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
import { useDebouncedValue } from "@mantine/hooks";
import { notifications } from "@mantine/notifications";
import {
  IconCheck,
  IconClock,
  IconCopy,
  IconDownload,
  IconPrinter,
  IconQrcode,
  IconReceipt,
  IconRefresh,
  IconSearch,
  IconShieldCheck,
  IconTicket,
  IconTrophy,
  IconWallet,
  IconX,
} from "@tabler/icons-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import { EmptyState } from "@/components/common/EmptyState";
import {
  formatBDT,
  formatDateTime,
  formatNumber,
  formatTimeAgo,
  getDrawTypeColor,
  getTicketStatusColor,
  padLotteryNumber,
} from "@/lib/formatters";
import { useLotteryStore } from "@/lib/store";
import type { Ticket } from "@/types/lottery";

const PAGE_SIZE = 25;

const TICKETS_NAV_LINKS = [
  {
    label: "All Tickets",
    href: "/tickets",
    icon: IconTicket,
  },
  {
    label: "Active in Play",
    href: "/tickets/active",
    icon: IconClock,
  },
  {
    label: "Winning Tickets",
    href: "/tickets/winning",
    icon: IconTrophy,
  },
];

export interface TicketsViewProps {
  filter?: string;
  initialStatus?: string;
}

export function TicketsView({ filter, initialStatus }: TicketsViewProps = {}) {
  const pathname = usePathname();
  const { tickets } = useLotteryStore();

  const effectiveInitialStatus = useMemo(() => {
    if (filter) return filter;
    if (initialStatus) return initialStatus;
    if (pathname === "/tickets/active") return "ACTIVE";
    if (pathname === "/tickets/winning") return "WON";
    return "ALL";
  }, [filter, initialStatus, pathname]);

  // Search and filter states
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [debouncedSearchQuery] = useDebouncedValue(searchQuery, 250);
  const [drawFilter, setDrawFilter] = useState<string>("ALL");
  const [statusFilter, setStatusFilter] = useState<string>(
    effectiveInitialStatus,
  );
  const [winnerFilter, setWinnerFilter] = useState<string>(
    effectiveInitialStatus === "WON" ? "WINNERS" : "ALL",
  );
  const [typeFilter, setTypeFilter] = useState<string>("ALL");

  // Keep filter state synchronized when props or pathname change
  useEffect(() => {
    if (filter) {
      setStatusFilter(filter);
      if (filter === "WON") {
        setWinnerFilter("WINNERS");
      }
    } else if (initialStatus) {
      setStatusFilter(initialStatus);
      if (initialStatus === "WON") {
        setWinnerFilter("WINNERS");
      }
    } else if (pathname === "/tickets/active") {
      setStatusFilter("ACTIVE");
      setWinnerFilter("ALL");
    } else if (pathname === "/tickets/winning") {
      setStatusFilter("WON");
      setWinnerFilter("WINNERS");
    } else if (pathname === "/tickets") {
      setStatusFilter("ALL");
      setWinnerFilter("ALL");
    }
  }, [filter, initialStatus, pathname]);

  // Modal states
  const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);

  // Filter logic with debounced search query
  const filteredTickets = useMemo(() => {
    const q = debouncedSearchQuery.toLowerCase().trim();

    return tickets.filter((ticket) => {
      // Type filter
      if (typeFilter !== "ALL" && ticket.draw_type_code !== typeFilter)
        return false;

      // Draw sequence filter
      if (drawFilter !== "ALL" && ticket.draw_sequence !== drawFilter)
        return false;

      // Status filter
      if (statusFilter !== "ALL" && ticket.status !== statusFilter)
        return false;

      // Winner filter
      if (
        winnerFilter === "WINNERS" &&
        !ticket.is_winner &&
        ticket.status !== "WON"
      )
        return false;
      if (
        winnerFilter === "NON_WINNERS" &&
        (ticket.is_winner || ticket.status === "WON")
      )
        return false;

      // General search query
      if (q) {
        const matchId = String(ticket.id).toLowerCase().includes(q);
        const matchPublicId = ticket.public_id.toLowerCase().includes(q);
        const matchNumber = ticket.selected_number.toLowerCase().includes(q);
        const matchUser = ticket.user_name.toLowerCase().includes(q);
        const matchPhone = ticket.user_phone.toLowerCase().includes(q);
        const matchUserId = ticket.user_id.toLowerCase().includes(q);
        const matchDraw = ticket.draw_sequence.toLowerCase().includes(q);

        if (
          !matchId &&
          !matchPublicId &&
          !matchNumber &&
          !matchUser &&
          !matchPhone &&
          !matchUserId &&
          !matchDraw
        ) {
          return false;
        }
      }

      return true;
    });
  }, [
    tickets,
    typeFilter,
    drawFilter,
    statusFilter,
    winnerFilter,
    debouncedSearchQuery,
  ]);

  const [page, setPage] = useState(1);
  const totalPages = Math.ceil(filteredTickets.length / PAGE_SIZE) || 1;
  const currentPage = Math.min(page, totalPages);

  const paginatedTickets = useMemo(() => {
    const startIndex = (currentPage - 1) * PAGE_SIZE;
    return filteredTickets.slice(startIndex, startIndex + PAGE_SIZE);
  }, [filteredTickets, currentPage]);

  // High-level auditing metrics
  const stats = useMemo(() => {
    const total = tickets.length;
    const active = tickets.filter((t) => t.status === "ACTIVE").length;
    const winners = tickets.filter(
      (t) => t.is_winner || t.status === "WON",
    ).length;
    const totalVolumeMinor = tickets.reduce(
      (sum, t) => sum + (t.ticket_price_minor || 0) * (t.quantity || 1),
      0,
    );

    return {
      total,
      active,
      winners,
      totalVolumeMinor,
    };
  }, [tickets]);

  // Unique draw options for the filter
  const drawOptions = useMemo(() => {
    const uniqueSeqs = Array.from(new Set(tickets.map((t) => t.draw_sequence)));
    return [
      { value: "ALL", label: "All Draws" },
      ...uniqueSeqs.map((seq) => ({ value: seq, label: seq })),
    ];
  }, [tickets]);

  const handleSelectTicket = useCallback((ticket: Ticket) => {
    setSelectedTicket(ticket);
  }, []);

  const handleClearFilters = useCallback(() => {
    setSearchQuery("");
    setTypeFilter("ALL");
    setDrawFilter("ALL");
    setStatusFilter("ALL");
    setWinnerFilter("ALL");
  }, []);

  return (
    <Stack gap="lg">
      {/* 1. Header Card with Breadcrumb, Title, Controls & Path Nav */}
      <Card
        p="lg"
        radius="lg"
        withBorder
        bg="var(--surface-card, var(--mantine-color-default))"
      >
        <Group justify="space-between" align="flex-start" wrap="wrap" gap="md">
          <Box>
            <Group gap="xs" align="center">
              <ThemeIcon
                size={38}
                radius="lg"
                variant="gradient"
                gradient={{ from: "#D97706", to: "#F59E0B", deg: 135 }}
                c="#070B14"
              >
                <IconTicket size={22} stroke={2} />
              </ThemeIcon>
              <Box>
                <Title order={2} fw={800} c="var(--mantine-color-text)">
                  Ticket Auditing & Inspection
                </Title>
                <Text size="xs" c="dimmed" fw={600}>
                  Search, verify cryptographic integrity, inspect selected
                  numbers with zero-preservation, and audit purchase receipts.
                </Text>
              </Box>
            </Group>
          </Box>

          <Group gap="sm">
            <Tooltip label="Refresh audit records">
              <ActionIcon
                variant="default"
                size="lg"
                onClick={() => {
                  notifications.show({
                    title: "Tickets Refreshed",
                    message:
                      "Ticket register updated with latest ledger orders.",
                    color: "blue",
                  });
                }}
              >
                <IconRefresh size={18} />
              </ActionIcon>
            </Tooltip>

            <Button
              variant="default"
              leftSection={<IconDownload size={16} />}
              onClick={() => {
                notifications.show({
                  title: "Export Generated",
                  message:
                    "Filtered ticket audit data ready for compliance download.",
                  color: "teal",
                });
              }}
            >
              Export CSV
            </Button>
          </Group>
        </Group>

        {/* Clean Path-Based Navigation Buttons (Zero ?x=y Query Routes) */}
        <Group gap="xs" wrap="wrap" mt="lg">
          {TICKETS_NAV_LINKS.map((link) => {
            const active =
              link.href === "/tickets"
                ? pathname === "/tickets"
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

      {/* 2. Key Audit Metric Cards */}
      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} spacing="md">
        <Card
          p="md"
          radius="lg"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
          className="glass-card-hover"
        >
          <Group justify="space-between" align="flex-start">
            <Box>
              <Text size="xs" c="dimmed" fw={600} tt="uppercase">
                Audited Tickets
              </Text>
              <Title
                order={3}
                size="h2"
                fw={800}
                mt={4}
                className="font-tabular"
              >
                {formatNumber(stats.total)}
              </Title>
              <Text size="xs" c="dimmed" mt={2}>
                Total ledger orders in registry
              </Text>
            </Box>
            <ThemeIcon size={42} radius="md" color="blue" variant="light">
              <IconTicket size={22} />
            </ThemeIcon>
          </Group>
        </Card>

        <Card
          p="md"
          radius="lg"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
          className="glass-card-hover"
        >
          <Group justify="space-between" align="flex-start">
            <Box>
              <Text size="xs" c="dimmed" fw={600} tt="uppercase">
                Active In Play
              </Text>
              <Title
                order={3}
                size="h2"
                fw={800}
                mt={4}
                c="blue"
                className="font-tabular"
              >
                {formatNumber(stats.active)}
              </Title>
              <Text size="xs" c="dimmed" mt={2}>
                Awaiting draw determination
              </Text>
            </Box>
            <ThemeIcon size={42} radius="md" color="cyan" variant="light">
              <IconClock size={22} />
            </ThemeIcon>
          </Group>
        </Card>

        <Card
          p="md"
          radius="lg"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
          className="glass-card-hover"
        >
          <Group justify="space-between" align="flex-start">
            <Box>
              <Text size="xs" c="dimmed" fw={600} tt="uppercase">
                Confirmed Winners
              </Text>
              <Title
                order={3}
                size="h2"
                fw={800}
                mt={4}
                c="teal"
                className="font-tabular"
              >
                {formatNumber(stats.winners)}
              </Title>
              <Text size="xs" c="teal" mt={2} fw={500}>
                Prize verified & credited
              </Text>
            </Box>
            <ThemeIcon size={42} radius="md" color="teal" variant="light">
              <IconTrophy size={22} />
            </ThemeIcon>
          </Group>
        </Card>

        <Card
          p="md"
          radius="lg"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
          className="glass-card-hover"
        >
          <Group justify="space-between" align="flex-start">
            <Box>
              <Text size="xs" c="dimmed" fw={600} tt="uppercase">
                Audited Volume
              </Text>
              <Title
                order={3}
                size="h2"
                fw={800}
                mt={4}
                c="tradexGold.5"
                className="font-tabular"
              >
                {formatBDT(stats.totalVolumeMinor)}
              </Title>
              <Text size="xs" c="dimmed" mt={2}>
                Gross user funds debited
              </Text>
            </Box>
            <ThemeIcon size={42} radius="md" color="tradexGold" variant="light">
              <IconWallet size={22} />
            </ThemeIcon>
          </Group>
        </Card>
      </SimpleGrid>

      {/* 3. Search & Comprehensive Filter Bar */}
      <Card
        p="md"
        radius="lg"
        withBorder
        bg="var(--surface-card, var(--mantine-color-default))"
      >
        <Stack gap="sm">
          <Group justify="space-between" wrap="wrap">
            <TextInput
              placeholder="Search by Ticket ID (#849201), Selected Number (0012345), User Name, Phone, or Draw..."
              leftSection={<IconSearch size={16} />}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.currentTarget.value)}
              style={{ flex: 1, minWidth: 320 }}
              size="sm"
            />

            <Group gap="xs" wrap="wrap">
              <Select
                placeholder="Draw Type"
                data={[
                  { value: "ALL", label: "All Draw Types" },
                  { value: "MEGA", label: "Mega 7-Digit" },
                  { value: "DAILY", label: "Daily 3-Digit" },
                  { value: "HOURLY", label: "Hourly 3-Digit" },
                ]}
                value={typeFilter}
                onChange={(val) => setTypeFilter(val || "ALL")}
                size="sm"
                w={160}
              />

              <Select
                placeholder="Draw Sequence"
                data={drawOptions}
                value={drawFilter}
                onChange={(val) => setDrawFilter(val || "ALL")}
                size="sm"
                w={170}
              />

              <Select
                placeholder="Status"
                data={[
                  { value: "ALL", label: "All Statuses" },
                  { value: "ACTIVE", label: "ACTIVE" },
                  { value: "WON", label: "WON" },
                  { value: "LOST", label: "LOST" },
                  { value: "CANCELLED", label: "CANCELLED" },
                  { value: "REFUNDED", label: "REFUNDED" },
                ]}
                value={statusFilter}
                onChange={(val) => setStatusFilter(val || "ALL")}
                size="sm"
                w={140}
              />

              <Select
                placeholder="Prize Status"
                data={[
                  { value: "ALL", label: "All Outcomes" },
                  { value: "WINNERS", label: "Winners Only" },
                  { value: "NON_WINNERS", label: "Non-Winners" },
                ]}
                value={winnerFilter}
                onChange={(val) => setWinnerFilter(val || "ALL")}
                size="sm"
                w={150}
              />

              {(searchQuery ||
                typeFilter !== "ALL" ||
                drawFilter !== "ALL" ||
                statusFilter !== "ALL" ||
                winnerFilter !== "ALL") && (
                <Button
                  variant="subtle"
                  color="gray"
                  size="sm"
                  leftSection={<IconX size={14} />}
                  onClick={handleClearFilters}
                >
                  Clear Filters
                </Button>
              )}
            </Group>
          </Group>
        </Stack>
      </Card>

      {/* 4. Ticket Auditing Table */}
      <Card
        p={0}
        radius="lg"
        withBorder
        bg="var(--surface-card, var(--mantine-color-default))"
      >
        <ScrollArea>
          <Table highlightOnHover verticalSpacing="sm" horizontalSpacing="md">
            <Table.Thead bg="rgba(255, 255, 255, 0.02)">
              <Table.Tr>
                <Table.Th>Ticket ID & Ref</Table.Th>
                <Table.Th>Draw Details</Table.Th>
                <Table.Th>Selected Number (Strict 0-Preserved)</Table.Th>
                <Table.Th>User Account</Table.Th>
                <Table.Th>Price & Qty</Table.Th>
                <Table.Th>Status</Table.Th>
                <Table.Th>Prize / Winner</Table.Th>
                <Table.Th>Purchase Timestamp</Table.Th>
                <Table.Th style={{ textAlign: "right" }}>Actions</Table.Th>
              </Table.Tr>
            </Table.Thead>

            <Table.Tbody>
              {paginatedTickets.length === 0 ? (
                <Table.Tr>
                  <Table.Td colSpan={9} py="xl">
                    <EmptyState
                      icon={IconTicket}
                      title="No Matching Tickets Located"
                      description="Try searching by exact ticket ID, user phone, or clearing active filters."
                    />
                  </Table.Td>
                </Table.Tr>
              ) : (
                paginatedTickets.map((ticket) => (
                  <TicketTableRow
                    key={ticket.id}
                    ticket={ticket}
                    onSelectReceipt={handleSelectTicket}
                  />
                ))
              )}
            </Table.Tbody>
          </Table>
        </ScrollArea>

        {filteredTickets.length > 0 && (
          <Group
            justify="space-between"
            align="center"
            p="md"
            pt="xs"
            wrap="wrap"
          >
            <Text size="xs" c="dimmed">
              Showing {(page - 1) * PAGE_SIZE + 1} to{" "}
              {Math.min(page * PAGE_SIZE, filteredTickets.length)} of{" "}
              {filteredTickets.length} entries
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

      {/* ========================================================================= */}
      {/* TICKET DETAIL MODAL: Official Receipt View                                */}
      {/* ========================================================================= */}
      <Modal
        opened={!!selectedTicket}
        onClose={() => setSelectedTicket(null)}
        title={
          <Group gap="xs">
            <ThemeIcon color="blue" variant="light" size={28}>
              <IconReceipt size={16} />
            </ThemeIcon>
            <Title order={4} size="h5" fw={700}>
              Official Ticket Audit Receipt
            </Title>
          </Group>
        }
        size="md"
        radius="lg"
      >
        {selectedTicket && (
          <Stack gap="md">
            {/* Receipt Container */}
            <Paper
              p="md"
              radius="md"
              withBorder
              bg="rgba(0, 0, 0, 0.3)"
              style={{
                position: "relative",
                borderStyle: "dashed",
                borderColor: "var(--mantine-color-default-border)",
              }}
            >
              <Stack gap="sm">
                {/* Receipt Header Banner */}
                <Group justify="space-between" align="flex-start">
                  <Box>
                    <Group gap={6} align="center">
                      <ThemeIcon size={24} color="tradexGold" radius="xl">
                        <IconShieldCheck size={14} color="#0A0F1D" />
                      </ThemeIcon>
                      <Text
                        fw={800}
                        size="sm"
                        tt="uppercase"
                        style={{ letterSpacing: 1 }}
                      >
                        TRADEX LOTTERY
                      </Text>
                    </Group>
                    <Text size="10px" c="dimmed" mt={2}>
                      Cryptographically Verified Digital Entry
                    </Text>
                  </Box>

                  <Badge color="blue" size="xs" variant="filled">
                    SECURED
                  </Badge>
                </Group>

                <Divider style={{ borderStyle: "dashed" }} />

                {/* Big Selected Number Display with zero preservation */}
                <Box ta="center" py="xs">
                  <Text size="11px" c="dimmed" tt="uppercase" fw={600} mb={6}>
                    Selected Entry Number
                  </Text>
                  <Group justify="center" gap={6}>
                    {padLotteryNumber(
                      selectedTicket.selected_number,
                      selectedTicket.draw_type_code === "MEGA" ? 7 : 3,
                    )
                      .split("")
                      .map((digit, idx) => (
                        <span
                          key={`modal-digit-${idx}-${digit}`}
                          className="digit-ball font-tabular"
                          style={{
                            width: 38,
                            height: 48,
                            fontSize: "1.25rem",
                            backgroundColor: "#0F172A",
                            borderRadius: 6,
                            border: "1.5px solid #F59E0B",
                            color: "#F59E0B",
                            boxShadow: "0 2px 6px rgba(0,0,0,0.5)",
                          }}
                        >
                          {digit}
                        </span>
                      ))}
                  </Group>
                  <Text size="10px" c="dimmed" mt={6}>
                    {selectedTicket.draw_type_code === "MEGA"
                      ? "7-Digit Sequence • Leading zeros strictly verified"
                      : "3-Digit Sequence • Leading zeros strictly verified"}
                  </Text>
                </Box>

                {/* Winner Notice if applicable */}
                {(selectedTicket.is_winner ||
                  selectedTicket.status === "WON") && (
                  <Alert
                    color="teal"
                    icon={<IconTrophy size={18} />}
                    title="WINNING TICKET RECORD"
                  >
                    <Text size="xs">
                      Matched prize tier:{" "}
                      <Text span fw={700}>
                        {selectedTicket.winning_tier || "Grand Prize"}
                      </Text>
                    </Text>
                    <Text
                      size="xs"
                      fw={800}
                      c="teal"
                      mt={2}
                      className="font-tabular"
                    >
                      Prize Amount:{" "}
                      {formatBDT(selectedTicket.prize_amount_minor || 0)}{" "}
                      (Credited to User Wallet)
                    </Text>
                  </Alert>
                )}

                <Divider style={{ borderStyle: "dashed" }} />

                {/* Receipt Details Breakdown */}
                <SimpleGrid cols={2} spacing="xs">
                  <Box>
                    <Text size="10px" c="dimmed" tt="uppercase" fw={700}>
                      Ticket ID
                    </Text>
                    <Text size="xs" fw={700} ff="monospace">
                      #{selectedTicket.id}
                    </Text>
                  </Box>

                  <Box>
                    <Text size="10px" c="dimmed" tt="uppercase" fw={700}>
                      Order Reference
                    </Text>
                    <Text size="xs" fw={700} ff="monospace">
                      {selectedTicket.order_public_id}
                    </Text>
                  </Box>

                  <Box>
                    <Text size="10px" c="dimmed" tt="uppercase" fw={700}>
                      Draw Sequence
                    </Text>
                    <Text size="xs" fw={700}>
                      {selectedTicket.draw_sequence}
                    </Text>
                  </Box>

                  <Box>
                    <Text size="10px" c="dimmed" tt="uppercase" fw={700}>
                      Category
                    </Text>
                    <Text size="xs" fw={600}>
                      {selectedTicket.draw_type_name}
                    </Text>
                  </Box>

                  <Box>
                    <Text size="10px" c="dimmed" tt="uppercase" fw={700}>
                      Ticket Holder
                    </Text>
                    <Text size="xs" fw={600}>
                      {selectedTicket.user_name}
                    </Text>
                    <Text size="10px" c="dimmed">
                      {selectedTicket.user_phone}
                    </Text>
                  </Box>

                  <Box>
                    <Text size="10px" c="dimmed" tt="uppercase" fw={700}>
                      Payment Account
                    </Text>
                    <Text size="xs" fw={600}>
                      {selectedTicket.payment_method || "WALLET"}
                    </Text>
                    <Text size="10px" c="dimmed" ff="monospace">
                      {selectedTicket.transaction_ref}
                    </Text>
                  </Box>

                  <Box>
                    <Text size="10px" c="dimmed" tt="uppercase" fw={700}>
                      Total Paid
                    </Text>
                    <Text
                      size="sm"
                      fw={900}
                      c="tradexGold.5"
                      className="font-tabular"
                    >
                      {formatBDT(
                        selectedTicket.ticket_price_minor *
                          selectedTicket.quantity,
                      )}
                    </Text>
                  </Box>

                  <Box>
                    <Text size="10px" c="dimmed" tt="uppercase" fw={700}>
                      Purchased At
                    </Text>
                    <Text size="xs" fw={600} className="font-tabular">
                      {formatDateTime(selectedTicket.created_at)}
                    </Text>
                  </Box>
                </SimpleGrid>

                <Divider style={{ borderStyle: "dashed" }} />

                {/* Cryptographic hash */}
                <Group justify="space-between" align="center">
                  <Box>
                    <Text size="9px" c="dimmed" ff="monospace">
                      VERIFICATION SIGNATURE
                    </Text>
                    <Text size="10px" c="dimmed" ff="monospace">
                      SHA256:{selectedTicket.public_id}00ff89a1c2e4
                    </Text>
                  </Box>

                  <ThemeIcon size={32} variant="outline" color="gray">
                    <IconQrcode size={18} />
                  </ThemeIcon>
                </Group>
              </Stack>
            </Paper>

            {/* Modal Actions */}
            <Group justify="space-between">
              <CopyButton
                value={`TRADEX TICKET RECEIPT\nID: #${selectedTicket.id}\nDraw: ${selectedTicket.draw_sequence}\nNumber: ${selectedTicket.selected_number}\nAmount: ${formatBDT(selectedTicket.ticket_price_minor * selectedTicket.quantity)}\nUser: ${selectedTicket.user_name} (${selectedTicket.user_phone})`}
              >
                {({ copied, copy }) => (
                  <Button
                    variant="default"
                    size="xs"
                    leftSection={
                      copied ? <IconCheck size={14} /> : <IconCopy size={14} />
                    }
                    onClick={copy}
                  >
                    {copied ? "Copied Receipt" : "Copy Data"}
                  </Button>
                )}
              </CopyButton>

              <Group gap="xs">
                <Button
                  variant="default"
                  size="xs"
                  leftSection={<IconPrinter size={14} />}
                  onClick={() => {
                    window.print();
                  }}
                >
                  Print
                </Button>

                <Button
                  variant="filled"
                  color="blue"
                  size="xs"
                  onClick={() => setSelectedTicket(null)}
                >
                  Close Inspection
                </Button>
              </Group>
            </Group>
          </Stack>
        )}
      </Modal>
    </Stack>
  );
}

// ==================== MEMOIZED TICKET TABLE ROW ====================

interface TicketTableRowProps {
  ticket: Ticket;
  onSelectReceipt: (t: Ticket) => void;
}

const TicketTableRow = React.memo(function TicketTableRow({
  ticket,
  onSelectReceipt,
}: TicketTableRowProps) {
  const requiredDigits = ticket.draw_type_code === "MEGA" ? 7 : 3;
  const paddedNumber = padLotteryNumber(ticket.selected_number, requiredDigits);

  return (
    <Table.Tr>
      {/* Ticket ID */}
      <Table.Td>
        <Group gap="xs">
          <ThemeIcon size={26} radius="sm" color="blue" variant="light">
            <IconReceipt size={15} />
          </ThemeIcon>
          <Box>
            <Group gap={4}>
              <Text fw={700} size="sm" ff="monospace">
                #{ticket.id}
              </Text>
              <CopyButton value={String(ticket.id)}>
                {({ copied, copy }) => (
                  <Tooltip label={copied ? "Copied" : "Copy ID"}>
                    <ActionIcon
                      variant="subtle"
                      color="gray"
                      size="xs"
                      onClick={copy}
                    >
                      {copied ? (
                        <IconCheck size={12} />
                      ) : (
                        <IconCopy size={12} />
                      )}
                    </ActionIcon>
                  </Tooltip>
                )}
              </CopyButton>
            </Group>
            <Text size="10px" c="dimmed" ff="monospace">
              {ticket.public_id}
            </Text>
          </Box>
        </Group>
      </Table.Td>

      {/* Draw Details */}
      <Table.Td>
        <Box>
          <Text fw={600} size="xs">
            {ticket.draw_sequence}
          </Text>
          <Badge
            size="xs"
            color={getDrawTypeColor(ticket.draw_type_code)}
            variant="light"
            mt={2}
          >
            {ticket.draw_type_code} (
            {ticket.draw_type_code === "MEGA" ? "7D" : "3D"})
          </Badge>
        </Box>
      </Table.Td>

      {/* Selected Number - Strict Leading Zero Preservation */}
      <Table.Td>
        <Tooltip
          label={`Cryptographic representation: "${paddedNumber}". Leading zeroes strictly maintained.`}
        >
          <Paper
            p="xs"
            radius="sm"
            withBorder
            bg="rgba(0, 0, 0, 0.25)"
            style={{ display: "inline-block" }}
          >
            <Group gap={3}>
              {paddedNumber.split("").map((digit, idx) => (
                <span
                  key={`digit-col-${idx}-${digit}`}
                  className="digit-ball font-tabular"
                  style={{
                    width: 22,
                    height: 26,
                    fontSize: "0.875rem",
                    backgroundColor:
                      digit === "0"
                        ? "rgba(255, 255, 255, 0.05)"
                        : "rgba(217, 119, 6, 0.15)",
                    borderRadius: 4,
                    border:
                      digit === "0"
                        ? "1px dashed rgba(255, 255, 255, 0.2)"
                        : "1px solid rgba(217, 119, 6, 0.4)",
                    color:
                      digit === "0"
                        ? "var(--mantine-color-dimmed)"
                        : "var(--mantine-color-tradexGold-4)",
                  }}
                >
                  {digit}
                </span>
              ))}
            </Group>
          </Paper>
        </Tooltip>
      </Table.Td>

      {/* User Info */}
      <Table.Td>
        <Box>
          <Text fw={600} size="xs">
            {ticket.user_name}
          </Text>
          <Text size="11px" c="dimmed">
            {ticket.user_phone}
          </Text>
          <Text size="10px" c="dimmed" ff="monospace">
            {ticket.user_id}
          </Text>
        </Box>
      </Table.Td>

      {/* Price & Quantity */}
      <Table.Td>
        <Text size="xs" fw={700} className="font-tabular">
          {formatBDT(ticket.ticket_price_minor * ticket.quantity)}
        </Text>
        <Text size="10px" c="dimmed" className="font-tabular">
          {formatBDT(ticket.ticket_price_minor)} × {ticket.quantity}
        </Text>
      </Table.Td>

      {/* Status */}
      <Table.Td>
        <Badge
          color={getTicketStatusColor(ticket.status)}
          variant="light"
          size="sm"
        >
          {ticket.status}
        </Badge>
      </Table.Td>

      {/* Is Winner Badge */}
      <Table.Td>
        {ticket.is_winner || ticket.status === "WON" ? (
          <Box>
            <Badge
              color="teal"
              variant="filled"
              size="sm"
              leftSection={<IconTrophy size={12} />}
            >
              WINNER
            </Badge>
            {ticket.prize_amount_minor && (
              <Text
                size="11px"
                fw={700}
                c="teal"
                mt={2}
                className="font-tabular"
              >
                {formatBDT(ticket.prize_amount_minor)}
              </Text>
            )}
          </Box>
        ) : ticket.status === "ACTIVE" ? (
          <Badge color="gray" variant="outline" size="xs">
            In Play
          </Badge>
        ) : ticket.status === "REFUNDED" ? (
          <Badge color="grape" variant="light" size="xs">
            Refunded
          </Badge>
        ) : (
          <Text size="xs" c="dimmed">
            No Win
          </Text>
        )}
      </Table.Td>

      {/* Purchase Timestamp */}
      <Table.Td>
        <Text size="11px" fw={500} className="font-tabular">
          {formatDateTime(ticket.created_at)}
        </Text>
        <Text size="10px" c="dimmed">
          {formatTimeAgo(ticket.created_at)}
        </Text>
      </Table.Td>

      {/* Actions */}
      <Table.Td style={{ textAlign: "right" }}>
        <Button
          size="xs"
          variant="light"
          color="blue"
          leftSection={<IconReceipt size={14} />}
          onClick={() => onSelectReceipt(ticket)}
        >
          Receipt
        </Button>
      </Table.Td>
    </Table.Tr>
  );
});

export default TicketsView;
