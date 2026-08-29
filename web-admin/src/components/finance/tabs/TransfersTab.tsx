"use client";

import {
  Badge,
  Card,
  Group,
  Pagination,
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
import type { UserTransferItem } from "@/types";

const PAGE_SIZE = 25;

export function TransfersTab() {
  const transfers = useAdminStore((s) => s.transfers);

  // Search and filter state with deferred value
  const [transferSearch, setTransferSearch] = useState("");
  const deferredSearch = useDeferredValue(transferSearch);
  const [debouncedSearch] = useDebouncedValue(deferredSearch, 200);
  const [page, setPage] = useState(1);

  // Filtered Transfers with debounced query
  const filteredTransfers = useMemo(() => {
    const q = debouncedSearch.toLowerCase().trim();
    return transfers.filter((trf) => {
      if (q) {
        return (
          trf.senderUsername.toLowerCase().includes(q) ||
          trf.receiverUsername.toLowerCase().includes(q) ||
          trf.ledgerRef.toLowerCase().includes(q) ||
          trf.id.toLowerCase().includes(q)
        );
      }
      return true;
    });
  }, [transfers, debouncedSearch]);

  const totalPages = Math.ceil(filteredTransfers.length / PAGE_SIZE) || 1;
  const currentPage = Math.min(page, totalPages);

  const paginatedTransfers = useMemo(() => {
    const startIndex = (currentPage - 1) * PAGE_SIZE;
    return filteredTransfers.slice(startIndex, startIndex + PAGE_SIZE);
  }, [filteredTransfers, currentPage]);

  return (
    <Card p="md" radius="lg" withBorder>
      <Stack gap="md">
        <Group justify="space-between">
          <TextInput
            placeholder="Search sender, receiver, ledger ref..."
            leftSection={<IconSearch size={16} />}
            value={transferSearch}
            onChange={(e) => setTransferSearch(e.target.value)}
            style={{ width: 340 }}
            size="sm"
          />
          <Badge color="cyan" size="md" variant="light">
            P2P Internal Clearing
          </Badge>
        </Group>

        <Table.ScrollContainer minWidth={850}>
          <Table verticalSpacing="sm">
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Transfer ID</Table.Th>
                <Table.Th>Sender</Table.Th>
                <Table.Th>Receiver</Table.Th>
                <Table.Th>Amount</Table.Th>
                <Table.Th>Platform Fee</Table.Th>
                <Table.Th>Ledger Reference</Table.Th>
                <Table.Th>Status</Table.Th>
                <Table.Th>Timestamp</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {paginatedTransfers.length === 0 ? (
                <Table.Tr>
                  <Table.Td colSpan={8} ta="center" py="xl">
                    <Text size="sm" c="dimmed">
                      No internal transfers match your search.
                    </Text>
                  </Table.Td>
                </Table.Tr>
              ) : (
                paginatedTransfers.map((trf) => (
                  <TransferTableRow key={trf.id} transfer={trf} />
                ))
              )}
            </Table.Tbody>
          </Table>
        </Table.ScrollContainer>

        {/* Pagination Controls */}
        {filteredTransfers.length > 0 && (
          <Group justify="space-between" align="center" mt="xs" wrap="wrap">
            <Text size="xs" c="dimmed" fw={500}>
              Showing {(page - 1) * PAGE_SIZE + 1} to{" "}
              {Math.min(page * PAGE_SIZE, filteredTransfers.length)} of{" "}
              {filteredTransfers.length} entries
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

// ==================== MEMOIZED TRANSFER TABLE ROW ====================

interface TransferTableRowProps {
  transfer: UserTransferItem;
}

const TransferTableRow = React.memo(function TransferTableRow({
  transfer: trf,
}: TransferTableRowProps) {
  return (
    <Table.Tr key={trf.id}>
      <Table.Td>
        <Text size="xs" ff="monospace" fw={600} c="dimmed">
          #{trf.id}
        </Text>
      </Table.Td>
      <Table.Td>
        <Text size="sm" fw={700}>
          {trf.senderFullName}
        </Text>
        <Text size="xs" c="dimmed">
          @{trf.senderUsername}
        </Text>
      </Table.Td>
      <Table.Td>
        <Text size="sm" fw={700}>
          {trf.receiverFullName}
        </Text>
        <Text size="xs" c="dimmed">
          @{trf.receiverUsername}
        </Text>
      </Table.Td>
      <Table.Td>
        <Text size="sm" fw={800} className="font-tabular">
          {trf.formattedAmount}
        </Text>
      </Table.Td>
      <Table.Td>
        <Text size="xs" c="dimmed" className="font-tabular">
          {trf.formattedFee}
        </Text>
      </Table.Td>
      <Table.Td>
        <Badge ff="monospace" size="sm" variant="light" color="cyan">
          {trf.ledgerRef}
        </Badge>
      </Table.Td>
      <Table.Td>
        <Badge color={getStatusColor(trf.status)} size="xs" variant="filled">
          {trf.status}
        </Badge>
      </Table.Td>
      <Table.Td>
        <Text size="xs" c="dimmed" className="font-tabular">
          {formatDateTime(trf.createdAt)}
        </Text>
      </Table.Td>
    </Table.Tr>
  );
});
