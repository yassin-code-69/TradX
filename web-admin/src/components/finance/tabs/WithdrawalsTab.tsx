"use client";

import {
  ActionIcon,
  Badge,
  Button,
  Card,
  CopyButton,
  Group,
  Pagination,
  Select,
  Stack,
  Table,
  Text,
  TextInput,
  Tooltip,
} from "@mantine/core";
import { useDebouncedValue } from "@mantine/hooks";
import { IconCheck, IconCopy, IconSearch, IconX } from "@tabler/icons-react";
import React, { useCallback, useDeferredValue, useMemo, useState } from "react";
import { formatDateTime, getStatusColor } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";
import type { WithdrawalItem } from "@/types";
import { ApproveWithdrawalModal } from "../ApproveWithdrawalModal";
import { RejectWithdrawalModal } from "../RejectWithdrawalModal";

const PAGE_SIZE = 25;

export function WithdrawalsTab() {
  const withdrawals = useAdminStore((s) => s.withdrawals);

  // Search and filter states with concurrent deferred value
  const [withdrawalSearch, setWithdrawalSearch] = useState("");
  const deferredSearch = useDeferredValue(withdrawalSearch);
  const [debouncedSearch] = useDebouncedValue(deferredSearch, 200);
  const [withdrawalStatusFilter, setWithdrawalStatusFilter] =
    useState<string>("ALL");
  const [withdrawalMethodFilter, setWithdrawalMethodFilter] =
    useState<string>("ALL");
  const [page, setPage] = useState(1);

  // Modals state
  const [selectedApproveWithdrawal, setSelectedApproveWithdrawal] =
    useState<WithdrawalItem | null>(null);
  const [selectedRejectWithdrawal, setSelectedRejectWithdrawal] =
    useState<WithdrawalItem | null>(null);

  // Filtered Withdrawals with debounced query
  const filteredWithdrawals = useMemo(() => {
    const q = debouncedSearch.toLowerCase().trim();
    return withdrawals.filter((w) => {
      if (q) {
        const matchesSearch =
          w.username.toLowerCase().includes(q) ||
          w.userFullName.toLowerCase().includes(q) ||
          w.receiverAccount.includes(q) ||
          w.id.toLowerCase().includes(q);
        if (!matchesSearch) return false;
      }

      if (
        withdrawalStatusFilter !== "ALL" &&
        w.status !== withdrawalStatusFilter
      )
        return false;

      if (
        withdrawalMethodFilter !== "ALL" &&
        w.paymentMethod !== withdrawalMethodFilter
      )
        return false;

      return true;
    });
  }, [
    withdrawals,
    debouncedSearch,
    withdrawalStatusFilter,
    withdrawalMethodFilter,
  ]);

  const totalPages = Math.ceil(filteredWithdrawals.length / PAGE_SIZE) || 1;
  const currentPage = Math.min(page, totalPages);

  const paginatedWithdrawals = useMemo(() => {
    const startIndex = (currentPage - 1) * PAGE_SIZE;
    return filteredWithdrawals.slice(startIndex, startIndex + PAGE_SIZE);
  }, [filteredWithdrawals, currentPage]);

  const handleOpenApprove = useCallback((w: WithdrawalItem) => {
    setSelectedApproveWithdrawal(w);
  }, []);

  const handleOpenReject = useCallback((w: WithdrawalItem) => {
    setSelectedRejectWithdrawal(w);
  }, []);

  return (
    <>
      <Card p="md" radius="lg" withBorder>
        <Stack gap="md">
          {/* Filter Controls */}
          <Group justify="space-between" wrap="wrap">
            <TextInput
              placeholder="Search by User, Receiver Account, ID..."
              leftSection={<IconSearch size={16} />}
              value={withdrawalSearch}
              onChange={(e) => setWithdrawalSearch(e.target.value)}
              style={{ width: 320 }}
              size="sm"
            />

            <Group gap="sm">
              <Select
                placeholder="Status"
                data={[
                  { value: "ALL", label: "All Statuses" },
                  { value: "PENDING", label: "Pending Only" },
                  { value: "APPROVED", label: "Approved Only" },
                  { value: "REJECTED", label: "Rejected Only" },
                ]}
                value={withdrawalStatusFilter}
                onChange={(val) => setWithdrawalStatusFilter(val || "ALL")}
                size="sm"
                style={{ width: 150 }}
              />

              <Select
                placeholder="Method"
                data={[
                  { value: "ALL", label: "All Methods" },
                  { value: "bKash", label: "bKash" },
                  { value: "Nagad", label: "Nagad" },
                  { value: "Rocket", label: "Rocket" },
                  { value: "Bank Transfer", label: "Bank Transfer" },
                ]}
                value={withdrawalMethodFilter}
                onChange={(val) => setWithdrawalMethodFilter(val || "ALL")}
                size="sm"
                style={{ width: 150 }}
              />
            </Group>
          </Group>

          {/* Withdrawals Table */}
          <Table.ScrollContainer minWidth={950}>
            <Table verticalSpacing="sm">
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>Request ID</Table.Th>
                  <Table.Th>User Account</Table.Th>
                  <Table.Th>Method</Table.Th>
                  <Table.Th>Destination Account</Table.Th>
                  <Table.Th>Gross Amount</Table.Th>
                  <Table.Th>Fee</Table.Th>
                  <Table.Th>Net Payout</Table.Th>
                  <Table.Th>Requested At</Table.Th>
                  <Table.Th>Status</Table.Th>
                  <Table.Th style={{ textAlign: "right" }}>Actions</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {paginatedWithdrawals.length === 0 ? (
                  <Table.Tr>
                    <Table.Td colSpan={10} ta="center" py="xl">
                      <Text size="sm" c="dimmed">
                        No withdrawal requests found matching the current
                        filters.
                      </Text>
                    </Table.Td>
                  </Table.Tr>
                ) : (
                  paginatedWithdrawals.map((w) => (
                    <WithdrawalTableRow
                      key={w.id}
                      withdrawal={w}
                      onApprove={handleOpenApprove}
                      onReject={handleOpenReject}
                    />
                  ))
                )}
              </Table.Tbody>
            </Table>
          </Table.ScrollContainer>

          {/* Pagination Controls */}
          {filteredWithdrawals.length > 0 && (
            <Group justify="space-between" align="center" mt="xs" wrap="wrap">
              <Text size="xs" c="dimmed" fw={500}>
                Showing {(page - 1) * PAGE_SIZE + 1} to{" "}
                {Math.min(page * PAGE_SIZE, filteredWithdrawals.length)} of{" "}
                {filteredWithdrawals.length} entries
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

      {/* Modals */}
      {selectedApproveWithdrawal && (
        <ApproveWithdrawalModal
          opened={!!selectedApproveWithdrawal}
          onClose={() => setSelectedApproveWithdrawal(null)}
          withdrawal={selectedApproveWithdrawal}
        />
      )}

      {selectedRejectWithdrawal && (
        <RejectWithdrawalModal
          opened={!!selectedRejectWithdrawal}
          onClose={() => setSelectedRejectWithdrawal(null)}
          withdrawal={selectedRejectWithdrawal}
        />
      )}
    </>
  );
}

// ==================== MEMOIZED WITHDRAWAL TABLE ROW ====================

interface WithdrawalTableRowProps {
  withdrawal: WithdrawalItem;
  onApprove: (w: WithdrawalItem) => void;
  onReject: (w: WithdrawalItem) => void;
}

const WithdrawalTableRow = React.memo(function WithdrawalTableRow({
  withdrawal: w,
  onApprove,
  onReject,
}: WithdrawalTableRowProps) {
  return (
    <Table.Tr key={w.id}>
      <Table.Td>
        <Text size="xs" ff="monospace" fw={600} c="dimmed">
          #{w.id}
        </Text>
      </Table.Td>
      <Table.Td>
        <Text size="sm" fw={700}>
          {w.userFullName}
        </Text>
        <Text size="xs" c="dimmed">
          @{w.username}
        </Text>
      </Table.Td>
      <Table.Td>
        <Badge color="blue" size="sm" variant="light">
          {w.paymentMethod}
        </Badge>
      </Table.Td>
      <Table.Td>
        <Group gap={4}>
          <Text size="sm" ff="monospace" fw={700} c="cyan.4">
            {w.receiverAccount}
          </Text>
          <CopyButton value={w.receiverAccount} timeout={2000}>
            {({ copied, copy }) => (
              <Tooltip label={copied ? "Copied" : "Copy"} withArrow>
                <ActionIcon
                  color={copied ? "teal" : "gray"}
                  variant="subtle"
                  size="xs"
                  onClick={copy}
                >
                  {copied ? <IconCheck size={12} /> : <IconCopy size={12} />}
                </ActionIcon>
              </Tooltip>
            )}
          </CopyButton>
        </Group>
      </Table.Td>
      <Table.Td>
        <Text size="sm" className="font-tabular" fw={600}>
          {w.formattedAmount}
        </Text>
      </Table.Td>
      <Table.Td>
        <Text size="xs" c="dimmed" className="font-tabular">
          {w.formattedFee}
        </Text>
      </Table.Td>
      <Table.Td>
        <Text size="sm" fw={900} c="emerald.4" className="font-tabular">
          {w.formattedNetAmount}
        </Text>
      </Table.Td>
      <Table.Td>
        <Text size="xs" c="dimmed" className="font-tabular">
          {formatDateTime(w.requestedAt)}
        </Text>
      </Table.Td>
      <Table.Td>
        <Badge color={getStatusColor(w.status)} size="sm" variant="filled">
          {w.status}
        </Badge>
      </Table.Td>
      <Table.Td>
        <Group justify="flex-end" gap={6}>
          {w.status === "PENDING" ? (
            <>
              <Tooltip label="Reject & Return Funds">
                <ActionIcon
                  size="sm"
                  variant="light"
                  color="red"
                  onClick={() => onReject(w)}
                >
                  <IconX size={14} />
                </ActionIcon>
              </Tooltip>
              <Button size="xs" color="teal" onClick={() => onApprove(w)}>
                Approve
              </Button>
            </>
          ) : (
            <Text size="xs" c="dimmed">
              {w.status === "APPROVED"
                ? w.transactionReference || "Completed"
                : "Rejected"}
            </Text>
          )}
        </Group>
      </Table.Td>
    </Table.Tr>
  );
});
