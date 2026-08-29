"use client";

import {
  Badge,
  Card,
  Group,
  Pagination,
  Select,
  Stack,
  Table,
  Text,
  TextInput,
} from "@mantine/core";
import { useDebouncedValue } from "@mantine/hooks";
import { IconSearch } from "@tabler/icons-react";
import React, { useDeferredValue, useMemo, useState } from "react";
import { formatDateTime, getStatusColor } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";
import type { LedgerTransactionItem } from "@/types";

const PAGE_SIZE = 25;

export function LedgerTab() {
  const ledgerTransactions = useAdminStore((s) => s.ledgerTransactions);

  // Search and filter states with deferred value
  const [ledgerSearch, setLedgerSearch] = useState("");
  const deferredSearch = useDeferredValue(ledgerSearch);
  const [debouncedSearch] = useDebouncedValue(deferredSearch, 200);
  const [ledgerTypeFilter, setLedgerTypeFilter] = useState<string>("ALL");
  const [page, setPage] = useState(1);

  // Filtered Ledger with debounced query
  const filteredLedger = useMemo(() => {
    const q = debouncedSearch.toLowerCase().trim();
    return ledgerTransactions.filter((tx) => {
      if (q) {
        const matchesSearch =
          tx.username.toLowerCase().includes(q) ||
          tx.userFullName.toLowerCase().includes(q) ||
          tx.id.toLowerCase().includes(q) ||
          tx.note?.toLowerCase().includes(q);
        if (!matchesSearch) return false;
      }

      if (ledgerTypeFilter !== "ALL" && tx.transactionType !== ledgerTypeFilter)
        return false;

      return true;
    });
  }, [ledgerTransactions, debouncedSearch, ledgerTypeFilter]);

  const totalPages = Math.ceil(filteredLedger.length / PAGE_SIZE) || 1;
  const currentPage = Math.min(page, totalPages);

  const paginatedLedger = useMemo(() => {
    const startIndex = (currentPage - 1) * PAGE_SIZE;
    return filteredLedger.slice(startIndex, startIndex + PAGE_SIZE);
  }, [filteredLedger, currentPage]);

  return (
    <Card p="md" radius="lg" withBorder>
      <Stack gap="md">
        <Group justify="space-between" wrap="wrap">
          <TextInput
            placeholder="Search Trx ID, User, Ref..."
            leftSection={<IconSearch size={16} />}
            value={ledgerSearch}
            onChange={(e) => setLedgerSearch(e.target.value)}
            style={{ width: 320 }}
            size="sm"
          />

          <Select
            placeholder="Transaction Type"
            data={[
              { value: "ALL", label: "All Transaction Types" },
              { value: "DEPOSIT", label: "DEPOSIT" },
              { value: "WITHDRAWAL", label: "WITHDRAWAL" },
              { value: "TICKET_PURCHASE", label: "TICKET_PURCHASE" },
              { value: "WINNING", label: "WINNING" },
              { value: "USER_TRANSFER", label: "USER_TRANSFER" },
              { value: "ADMIN_ADJUSTMENT", label: "ADMIN_ADJUSTMENT" },
            ]}
            value={ledgerTypeFilter}
            onChange={(val) => setLedgerTypeFilter(val || "ALL")}
            size="sm"
            style={{ width: 220 }}
          />
        </Group>

        <Table.ScrollContainer minWidth={900}>
          <Table verticalSpacing="sm">
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Ledger ID</Table.Th>
                <Table.Th>Type</Table.Th>
                <Table.Th>User</Table.Th>
                <Table.Th>Direction</Table.Th>
                <Table.Th>Amount Minor</Table.Th>
                <Table.Th>Amount BDT</Table.Th>
                <Table.Th>Reference</Table.Th>
                <Table.Th>Status</Table.Th>
                <Table.Th>Timestamp</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {paginatedLedger.length === 0 ? (
                <Table.Tr>
                  <Table.Td colSpan={9} ta="center" py="xl">
                    <Text size="sm" c="dimmed">
                      No ledger journal entries found.
                    </Text>
                  </Table.Td>
                </Table.Tr>
              ) : (
                paginatedLedger.map((tx) => (
                  <LedgerTableRow key={tx.id} transaction={tx} />
                ))
              )}
            </Table.Tbody>
          </Table>
        </Table.ScrollContainer>

        {/* Pagination Controls */}
        {filteredLedger.length > 0 && (
          <Group justify="space-between" align="center" mt="xs" wrap="wrap">
            <Text size="xs" c="dimmed" fw={500}>
              Showing {(page - 1) * PAGE_SIZE + 1} to{" "}
              {Math.min(page * PAGE_SIZE, filteredLedger.length)} of{" "}
              {filteredLedger.length} entries
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
    </Card>
  );
}

// ==================== MEMOIZED LEDGER TABLE ROW ====================

interface LedgerTableRowProps {
  transaction: LedgerTransactionItem;
}

const LedgerTableRow = React.memo(function LedgerTableRow({
  transaction: tx,
}: LedgerTableRowProps) {
  return (
    <Table.Tr key={tx.id}>
      <Table.Td>
        <Text size="xs" ff="monospace" fw={600} c="dimmed">
          {tx.id}
        </Text>
      </Table.Td>
      <Table.Td>
        <Badge
          color={getTransactionTypeColor(tx.transactionType)}
          size="sm"
          variant="light"
        >
          {tx.transactionType}
        </Badge>
      </Table.Td>
      <Table.Td>
        <Text size="sm" fw={700}>
          {tx.userFullName}
        </Text>
        <Text size="xs" c="dimmed">
          @{tx.username}
        </Text>
      </Table.Td>
      <Table.Td>
        <Badge
          color={tx.direction === "CREDIT" ? "teal" : "red"}
          size="xs"
          variant="filled"
        >
          {tx.direction}
        </Badge>
      </Table.Td>
      <Table.Td>
        <Text size="xs" ff="monospace" c="dimmed" className="font-tabular">
          {tx.amountMinor.toLocaleString()} poisha
        </Text>
      </Table.Td>
      <Table.Td>
        <Text
          size="sm"
          fw={800}
          className="font-tabular"
          c={tx.direction === "CREDIT" ? "emerald.4" : "red.4"}
        >
          {tx.direction === "CREDIT" ? "+" : "-"} {tx.formattedAmount}
        </Text>
      </Table.Td>
      <Table.Td>
        <Text size="xs" ff="monospace" c="dimmed">
          {tx.referenceType}: {tx.referenceId}
        </Text>
      </Table.Td>
      <Table.Td>
        <Badge color={getStatusColor(tx.status)} size="xs" variant="filled">
          {tx.status}
        </Badge>
      </Table.Td>
      <Table.Td>
        <Text size="xs" c="dimmed" className="font-tabular">
          {formatDateTime(tx.createdAt)}
        </Text>
      </Table.Td>
    </Table.Tr>
  );
});

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
