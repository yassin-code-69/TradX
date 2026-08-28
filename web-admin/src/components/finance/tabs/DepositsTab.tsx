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
import {
  IconCheck,
  IconCopy,
  IconEye,
  IconSearch,
  IconX,
} from "@tabler/icons-react";
import { useEffect, useMemo, useState } from "react";
import { formatDateTime, getStatusColor } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";
import type { DepositItem } from "@/types";
import { ApproveDepositModal } from "../ApproveDepositModal";
import { DepositReceiptModal } from "../DepositReceiptModal";
import { RejectDepositModal } from "../RejectDepositModal";

const PAGE_SIZE = 25;

export function DepositsTab() {
  const { deposits } = useAdminStore();

  // Search and filter states
  const [depositSearch, setDepositSearch] = useState("");
  const [depositStatusFilter, setDepositStatusFilter] = useState<string>("ALL");
  const [depositMethodFilter, setDepositMethodFilter] = useState<string>("ALL");
  const [page, setPage] = useState(1);

  // Modals state
  const [selectedReceiptDeposit, setSelectedReceiptDeposit] =
    useState<DepositItem | null>(null);
  const [selectedApproveDeposit, setSelectedApproveDeposit] =
    useState<DepositItem | null>(null);
  const [selectedRejectDeposit, setSelectedRejectDeposit] =
    useState<DepositItem | null>(null);

  // Filtered Deposits
  const filteredDeposits = useMemo(() => {
    return deposits.filter((dep) => {
      const matchesSearch =
        dep.providerTransactionId
          .toLowerCase()
          .includes(depositSearch.toLowerCase()) ||
        dep.username.toLowerCase().includes(depositSearch.toLowerCase()) ||
        dep.userFullName.toLowerCase().includes(depositSearch.toLowerCase()) ||
        dep.senderAccount.includes(depositSearch);

      const matchesStatus =
        depositStatusFilter === "ALL" || dep.status === depositStatusFilter;

      const matchesMethod =
        depositMethodFilter === "ALL" ||
        dep.paymentMethod === depositMethodFilter;

      return matchesSearch && matchesStatus && matchesMethod;
    });
  }, [deposits, depositSearch, depositStatusFilter, depositMethodFilter]);

  // Reset page when filters change
  useEffect(() => {
    if (depositSearch || depositStatusFilter || depositMethodFilter) {
      setPage(1);
    } else {
      setPage(1);
    }
  }, [depositSearch, depositStatusFilter, depositMethodFilter]);

  const totalPages = Math.ceil(filteredDeposits.length / PAGE_SIZE) || 1;
  const paginatedDeposits = useMemo(() => {
    const startIndex = (page - 1) * PAGE_SIZE;
    return filteredDeposits.slice(startIndex, startIndex + PAGE_SIZE);
  }, [filteredDeposits, page]);

  return (
    <>
      <Card p="md" radius="md" withBorder bg="dark.8">
        <Stack gap="md">
          {/* Filter Controls */}
          <Group justify="space-between" wrap="wrap">
            <TextInput
              placeholder="Search by TrxID, User, Phone, Sender..."
              leftSection={<IconSearch size={16} />}
              value={depositSearch}
              onChange={(e) => setDepositSearch(e.target.value)}
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
                value={depositStatusFilter}
                onChange={(val) => setDepositStatusFilter(val || "ALL")}
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
                value={depositMethodFilter}
                onChange={(val) => setDepositMethodFilter(val || "ALL")}
                size="sm"
                style={{ width: 150 }}
              />
            </Group>
          </Group>

          {/* Deposits Table */}
          <Table.ScrollContainer minWidth={900}>
            <Table verticalSpacing="sm">
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>Request ID</Table.Th>
                  <Table.Th>User Account</Table.Th>
                  <Table.Th>Method</Table.Th>
                  <Table.Th>Sender Account</Table.Th>
                  <Table.Th>Transaction ID (TrxID)</Table.Th>
                  <Table.Th>Amount</Table.Th>
                  <Table.Th>Submitted At</Table.Th>
                  <Table.Th>Status</Table.Th>
                  <Table.Th style={{ textAlign: "right" }}>Actions</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {paginatedDeposits.length === 0 ? (
                  <Table.Tr>
                    <Table.Td colSpan={9} ta="center" py="xl">
                      <Text size="sm" c="dimmed">
                        No deposit requests found matching the current filters.
                      </Text>
                    </Table.Td>
                  </Table.Tr>
                ) : (
                  paginatedDeposits.map((dep) => (
                    <Table.Tr key={dep.id}>
                      <Table.Td>
                        <Text size="xs" ff="monospace" fw={600} c="dimmed">
                          #{dep.id}
                        </Text>
                      </Table.Td>
                      <Table.Td>
                        <Text size="sm" fw={600}>
                          {dep.userFullName}
                        </Text>
                        <Text size="xs" c="dimmed">
                          @{dep.username}
                        </Text>
                      </Table.Td>
                      <Table.Td>
                        <Badge
                          color={
                            dep.paymentMethod === "bKash"
                              ? "pink"
                              : dep.paymentMethod === "Nagad"
                                ? "orange"
                                : dep.paymentMethod === "Rocket"
                                  ? "grape"
                                  : "blue"
                          }
                          size="sm"
                        >
                          {dep.paymentMethod}
                        </Badge>
                      </Table.Td>
                      <Table.Td>
                        <Group gap={4}>
                          <Text size="sm" ff="monospace">
                            {dep.senderAccount}
                          </Text>
                          <CopyButton value={dep.senderAccount} timeout={2000}>
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
                        <Group gap={4}>
                          <Badge color="dark.4" ff="monospace" size="sm">
                            {dep.providerTransactionId}
                          </Badge>
                          <CopyButton
                            value={dep.providerTransactionId}
                            timeout={2000}
                          >
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
                        <Text size="sm" fw={800} c="emerald.4">
                          {dep.formattedAmount}
                        </Text>
                      </Table.Td>
                      <Table.Td>
                        <Text size="xs" c="dimmed">
                          {formatDateTime(dep.submittedAt)}
                        </Text>
                      </Table.Td>
                      <Table.Td>
                        <Badge color={getStatusColor(dep.status)} size="sm">
                          {dep.status}
                        </Badge>
                      </Table.Td>
                      <Table.Td>
                        <Group justify="flex-end" gap={6}>
                          <Tooltip label="View Proof / Receipt">
                            <ActionIcon
                              size="sm"
                              variant="light"
                              color="gray"
                              onClick={() => setSelectedReceiptDeposit(dep)}
                            >
                              <IconEye size={14} />
                            </ActionIcon>
                          </Tooltip>

                          {dep.status === "PENDING" && (
                            <>
                              <Tooltip label="Reject Deposit">
                                <ActionIcon
                                  size="sm"
                                  variant="light"
                                  color="red"
                                  onClick={() => setSelectedRejectDeposit(dep)}
                                >
                                  <IconX size={14} />
                                </ActionIcon>
                              </Tooltip>
                              <Button
                                size="xs"
                                color="teal"
                                onClick={() => setSelectedApproveDeposit(dep)}
                              >
                                Approve
                              </Button>
                            </>
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
          {filteredDeposits.length > 0 && (
            <Group justify="space-between" align="center" mt="xs" wrap="wrap">
              <Text size="xs" c="dimmed">
                Showing {(page - 1) * PAGE_SIZE + 1} to{" "}
                {Math.min(page * PAGE_SIZE, filteredDeposits.length)} of{" "}
                {filteredDeposits.length} entries
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
      <DepositReceiptModal
        opened={!!selectedReceiptDeposit}
        onClose={() => setSelectedReceiptDeposit(null)}
        deposit={selectedReceiptDeposit}
        onApprove={(dep) => setSelectedApproveDeposit(dep)}
        onReject={(dep) => setSelectedRejectDeposit(dep)}
      />

      <ApproveDepositModal
        opened={!!selectedApproveDeposit}
        onClose={() => setSelectedApproveDeposit(null)}
        deposit={selectedApproveDeposit}
      />

      <RejectDepositModal
        opened={!!selectedRejectDeposit}
        onClose={() => setSelectedRejectDeposit(null)}
        deposit={selectedRejectDeposit}
      />
    </>
  );
}
