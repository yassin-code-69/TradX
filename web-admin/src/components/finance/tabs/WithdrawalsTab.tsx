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
import { IconCheck, IconCopy, IconSearch, IconX } from "@tabler/icons-react";
import { useEffect, useMemo, useState } from "react";
import { formatDateTime, getStatusColor } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";
import type { WithdrawalItem } from "@/types";
import { ApproveWithdrawalModal } from "../ApproveWithdrawalModal";
import { RejectWithdrawalModal } from "../RejectWithdrawalModal";

const PAGE_SIZE = 25;

export function WithdrawalsTab() {
  const { withdrawals } = useAdminStore();

  // Search and filter states
  const [withdrawalSearch, setWithdrawalSearch] = useState("");
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

  // Filtered Withdrawals
  const filteredWithdrawals = useMemo(() => {
    return withdrawals.filter((w) => {
      const matchesSearch =
        w.username.toLowerCase().includes(withdrawalSearch.toLowerCase()) ||
        w.userFullName.toLowerCase().includes(withdrawalSearch.toLowerCase()) ||
        w.receiverAccount.includes(withdrawalSearch) ||
        w.id.toLowerCase().includes(withdrawalSearch.toLowerCase());

      const matchesStatus =
        withdrawalStatusFilter === "ALL" || w.status === withdrawalStatusFilter;

      const matchesMethod =
        withdrawalMethodFilter === "ALL" ||
        w.paymentMethod === withdrawalMethodFilter;

      return matchesSearch && matchesStatus && matchesMethod;
    });
  }, [
    withdrawals,
    withdrawalSearch,
    withdrawalStatusFilter,
    withdrawalMethodFilter,
  ]);

  // Reset page when filters change
  useEffect(() => {
    if (withdrawalSearch || withdrawalStatusFilter || withdrawalMethodFilter) {
      setPage(1);
    } else {
      setPage(1);
    }
  }, [withdrawalSearch, withdrawalStatusFilter, withdrawalMethodFilter]);

  const totalPages = Math.ceil(filteredWithdrawals.length / PAGE_SIZE) || 1;
  const paginatedWithdrawals = useMemo(() => {
    const startIndex = (page - 1) * PAGE_SIZE;
    return filteredWithdrawals.slice(startIndex, startIndex + PAGE_SIZE);
  }, [filteredWithdrawals, page]);

  return (
    <>
      <Card p="md" radius="md" withBorder bg="dark.8">
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
                    <Table.Tr key={w.id}>
                      <Table.Td>
                        <Text size="xs" ff="monospace" fw={600} c="dimmed">
                          #{w.id}
                        </Text>
                      </Table.Td>
                      <Table.Td>
                        <Text size="sm" fw={600}>
                          {w.userFullName}
                        </Text>
                        <Text size="xs" c="dimmed">
                          @{w.username}
                        </Text>
                      </Table.Td>
                      <Table.Td>
                        <Badge color="blue" size="sm">
                          {w.paymentMethod}
                        </Badge>
                      </Table.Td>
                      <Table.Td>
                        <Group gap={4}>
                          <Text size="sm" ff="monospace" fw={600} c="cyan.4">
                            {w.receiverAccount}
                          </Text>
                          <CopyButton value={w.receiverAccount} timeout={2000}>
                            {({ copied, copy }) => (
                              <Tooltip
                                label={copied ? "Copied" : "Copy"}
                                withArrow
                              >
                                <ActionIcon
                                  color={copied ? "teal" : "gray"}
                                  variant="subtle"
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
                      </Table.Td>
                      <Table.Td>
                        <Text size="sm">{w.formattedAmount}</Text>
                      </Table.Td>
                      <Table.Td>
                        <Text size="xs" c="dimmed">
                          {w.formattedFee}
                        </Text>
                      </Table.Td>
                      <Table.Td>
                        <Text size="sm" fw={800} c="emerald.4">
                          {w.formattedNetAmount}
                        </Text>
                      </Table.Td>
                      <Table.Td>
                        <Text size="xs" c="dimmed">
                          {formatDateTime(w.requestedAt)}
                        </Text>
                      </Table.Td>
                      <Table.Td>
                        <Badge color={getStatusColor(w.status)} size="sm">
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
                                  onClick={() => setSelectedRejectWithdrawal(w)}
                                >
                                  <IconX size={14} />
                                </ActionIcon>
                              </Tooltip>
                              <Button
                                size="xs"
                                color="teal"
                                onClick={() => setSelectedApproveWithdrawal(w)}
                              >
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
                  ))
                )}
              </Table.Tbody>
            </Table>
          </Table.ScrollContainer>

          {/* Pagination Controls */}
          {filteredWithdrawals.length > 0 && (
            <Group justify="space-between" align="center" mt="xs" wrap="wrap">
              <Text size="xs" c="dimmed">
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
      <ApproveWithdrawalModal
        opened={!!selectedApproveWithdrawal}
        onClose={() => setSelectedApproveWithdrawal(null)}
        withdrawal={selectedApproveWithdrawal}
      />

      <RejectWithdrawalModal
        opened={!!selectedRejectWithdrawal}
        onClose={() => setSelectedRejectWithdrawal(null)}
        withdrawal={selectedRejectWithdrawal}
      />
    </>
  );
}
