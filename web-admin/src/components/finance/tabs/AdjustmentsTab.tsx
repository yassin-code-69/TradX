"use client";

import {
  Badge,
  Button,
  Card,
  Group,
  Pagination,
  Paper,
  Stack,
  Table,
  Text,
  Title,
} from "@mantine/core";
import { IconScale } from "@tabler/icons-react";
import React, { useMemo, useState } from "react";
import { formatDateTime } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";
import type { LedgerTransactionItem } from "@/types";

const PAGE_SIZE = 25;

interface AdjustmentsTabProps {
  onOpenAdjustmentModal: () => void;
}

export function AdjustmentsTab({ onOpenAdjustmentModal }: AdjustmentsTabProps) {
  const ledgerTransactions = useAdminStore((s) => s.ledgerTransactions);
  const [page, setPage] = useState(1);

  // Past admin adjustments list
  const adminAdjustments = useMemo(() => {
    return ledgerTransactions.filter(
      (tx) => tx.transactionType === "ADMIN_ADJUSTMENT",
    );
  }, [ledgerTransactions]);

  const totalPages = Math.ceil(adminAdjustments.length / PAGE_SIZE) || 1;
  const paginatedAdjustments = useMemo(() => {
    const startIndex = (page - 1) * PAGE_SIZE;
    return adminAdjustments.slice(startIndex, startIndex + PAGE_SIZE);
  }, [adminAdjustments, page]);

  return (
    <Stack gap="md">
      <Paper p="lg" radius="lg" withBorder>
        <Group justify="space-between" align="center">
          <Stack gap="xs">
            <Title order={4} fw={800}>
              Administrative Wallet Balance Mutations
            </Title>
            <Text size="sm" c="dimmed">
              Double-entry bookkeeping compliant adjustments with strict reason
              validation, projected balance preview, and permanent audit
              tracking.
            </Text>
          </Stack>

          <Button
            color="tradexGold"
            className="btn-shimmer"
            style={{ color: "#070B14", fontWeight: 800 }}
            size="md"
            leftSection={<IconScale size={18} />}
            onClick={onOpenAdjustmentModal}
          >
            Create Balance Adjustment
          </Button>
        </Group>
      </Paper>

      <Card p="md" radius="lg" withBorder>
        <Title order={5} mb="sm" fw={800}>
          Adjustment Audit History
        </Title>
        <Table.ScrollContainer minWidth={700}>
          <Table verticalSpacing="sm">
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Audit ID</Table.Th>
                <Table.Th>User Account</Table.Th>
                <Table.Th>Type</Table.Th>
                <Table.Th>Amount</Table.Th>
                <Table.Th>Reason & Note</Table.Th>
                <Table.Th>Timestamp</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {paginatedAdjustments.length === 0 ? (
                <Table.Tr>
                  <Table.Td colSpan={6} ta="center" py="lg">
                    <Text size="sm" c="dimmed">
                      No manual adjustments recorded yet.
                    </Text>
                  </Table.Td>
                </Table.Tr>
              ) : (
                paginatedAdjustments.map((adj) => (
                  <AdjustmentTableRow key={adj.id} adjustment={adj} />
                ))
              )}
            </Table.Tbody>
          </Table>
        </Table.ScrollContainer>

        {/* Pagination Controls */}
        {adminAdjustments.length > 0 && (
          <Group justify="space-between" align="center" mt="xs" wrap="wrap">
            <Text size="xs" c="dimmed" fw={500}>
              Showing {(page - 1) * PAGE_SIZE + 1} to{" "}
              {Math.min(page * PAGE_SIZE, adminAdjustments.length)} of{" "}
              {adminAdjustments.length} entries
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
    </Stack>
  );
}

// ==================== MEMOIZED ADJUSTMENT TABLE ROW ====================

interface AdjustmentTableRowProps {
  adjustment: LedgerTransactionItem;
}

const AdjustmentTableRow = React.memo(function AdjustmentTableRow({
  adjustment: adj,
}: AdjustmentTableRowProps) {
  return (
    <Table.Tr key={adj.id}>
      <Table.Td>
        <Text size="xs" ff="monospace" c="dimmed">
          {adj.id}
        </Text>
      </Table.Td>
      <Table.Td>
        <Text size="sm" fw={700}>
          {adj.userFullName}
        </Text>
        <Text size="xs" c="dimmed">
          @{adj.username}
        </Text>
      </Table.Td>
      <Table.Td>
        <Badge
          color={adj.direction === "CREDIT" ? "teal" : "red"}
          size="xs"
          variant="filled"
        >
          {adj.direction}
        </Badge>
      </Table.Td>
      <Table.Td>
        <Text
          size="sm"
          fw={800}
          className="font-tabular"
          c={adj.direction === "CREDIT" ? "emerald.4" : "red.4"}
        >
          {adj.direction === "CREDIT" ? "+" : "-"} {adj.formattedAmount}
        </Text>
      </Table.Td>
      <Table.Td>
        <Text size="xs">{adj.note || "-"}</Text>
      </Table.Td>
      <Table.Td>
        <Text size="xs" c="dimmed" className="font-tabular">
          {formatDateTime(adj.createdAt)}
        </Text>
      </Table.Td>
    </Table.Tr>
  );
});
