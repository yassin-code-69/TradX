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
import { IconSearch } from "@tabler/icons-react";
import { useEffect, useMemo, useState } from "react";
import { formatDateTime, getStatusColor } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";

const PAGE_SIZE = 25;

export function TransfersTab() {
  const { transfers } = useAdminStore();

  // Search and filter state
  const [transferSearch, setTransferSearch] = useState("");
  const [page, setPage] = useState(1);

  // Filtered Transfers
  const filteredTransfers = useMemo(() => {
    return transfers.filter((trf) => {
      return (
        trf.senderUsername
          .toLowerCase()
          .includes(transferSearch.toLowerCase()) ||
        trf.receiverUsername
          .toLowerCase()
          .includes(transferSearch.toLowerCase()) ||
        trf.ledgerRef.toLowerCase().includes(transferSearch.toLowerCase()) ||
        trf.id.toLowerCase().includes(transferSearch.toLowerCase())
      );
    });
  }, [transfers, transferSearch]);

  // Reset page when search changes
  useEffect(() => {
    if (transferSearch) {
      setPage(1);
    } else {
      setPage(1);
    }
  }, [transferSearch]);

  const totalPages = Math.ceil(filteredTransfers.length / PAGE_SIZE) || 1;
  const paginatedTransfers = useMemo(() => {
    const startIndex = (page - 1) * PAGE_SIZE;
    return filteredTransfers.slice(startIndex, startIndex + PAGE_SIZE);
  }, [filteredTransfers, page]);

  return (
    <Card p="md" radius="md" withBorder bg="dark.8">
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
          <Badge color="cyan" size="md">
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
                  <Table.Tr key={trf.id}>
                    <Table.Td>
                      <Text size="xs" ff="monospace" fw={600} c="dimmed">
                        #{trf.id}
                      </Text>
                    </Table.Td>
                    <Table.Td>
                      <Text size="sm" fw={600}>
                        {trf.senderFullName}
                      </Text>
                      <Text size="xs" c="dimmed">
                        @{trf.senderUsername}
                      </Text>
                    </Table.Td>
                    <Table.Td>
                      <Text size="sm" fw={600}>
                        {trf.receiverFullName}
                      </Text>
                      <Text size="xs" c="dimmed">
                        @{trf.receiverUsername}
                      </Text>
                    </Table.Td>
                    <Table.Td>
                      <Text size="sm" fw={700} c="white">
                        {trf.formattedAmount}
                      </Text>
                    </Table.Td>
                    <Table.Td>
                      <Text size="xs" c="dimmed">
                        {trf.formattedFee}
                      </Text>
                    </Table.Td>
                    <Table.Td>
                      <Badge color="dark.4" ff="monospace" size="sm">
                        {trf.ledgerRef}
                      </Badge>
                    </Table.Td>
                    <Table.Td>
                      <Badge color={getStatusColor(trf.status)} size="xs">
                        {trf.status}
                      </Badge>
                    </Table.Td>
                    <Table.Td>
                      <Text size="xs" c="dimmed">
                        {formatDateTime(trf.createdAt)}
                      </Text>
                    </Table.Td>
                  </Table.Tr>
                ))
              )}
            </Table.Tbody>
          </Table>
        </Table.ScrollContainer>

        {/* Pagination Controls */}
        {filteredTransfers.length > 0 && (
          <Group justify="space-between" align="center" mt="xs" wrap="wrap">
            <Text size="xs" c="dimmed">
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
