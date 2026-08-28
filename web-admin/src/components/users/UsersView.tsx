"use client";

import {
  ActionIcon,
  Avatar,
  Badge,
  Button,
  Card,
  CopyButton,
  Group,
  Menu,
  Pagination,
  Paper,
  Select,
  SimpleGrid,
  Stack,
  Table,
  Text,
  TextInput,
  Title,
  Tooltip,
} from "@mantine/core";
import { notifications } from "@mantine/notifications";
import {
  IconCheck,
  IconCopy,
  IconDotsVertical,
  IconDownload,
  IconEye,
  IconLock,
  IconLockOpen,
  IconScale,
  IconSearch,
  IconUserCheck,
  IconUserExclamation,
  IconUserOff,
  IconUsers,
} from "@tabler/icons-react";
import { useEffect, useMemo, useState } from "react";
import { AdminAdjustBalanceModal } from "@/components/finance/AdminAdjustBalanceModal";
import { formatBDT, formatDateTime, getStatusColor } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";
import type { UserItem, UserStatus } from "@/types";
import { UserDetailsModal } from "./UserDetailsModal";

export function UsersView() {
  const { users, toggleUserStatus } = useAdminStore();

  // Filters
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("ALL");
  const [kycFilter, setKycFilter] = useState<string>("ALL");
  const [roleFilter, setRoleFilter] = useState<string>("ALL");

  // Modals state
  const [selectedUserDetails, setSelectedUserDetails] =
    useState<UserItem | null>(null);
  const [adjustBalanceUserId, setAdjustBalanceUserId] = useState<string | null>(
    null,
  );

  // Filtered users
  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      const q = search.toLowerCase();
      const matchesSearch =
        u.fullName.toLowerCase().includes(q) ||
        u.username.toLowerCase().includes(q) ||
        u.phone.toLowerCase().includes(q) ||
        u.email.toLowerCase().includes(q) ||
        u.publicId.toLowerCase().includes(q);

      const matchesStatus = statusFilter === "ALL" || u.status === statusFilter;
      const matchesKyc = kycFilter === "ALL" || u.kycStatus === kycFilter;
      const matchesRole = roleFilter === "ALL" || u.role === roleFilter;

      return matchesSearch && matchesStatus && matchesKyc && matchesRole;
    });
  }, [users, search, statusFilter, kycFilter, roleFilter]);

  const [page, setPage] = useState(1);
  const PAGE_SIZE = 25;

  // Reset page when filters change
  useEffect(() => {
    if (search || statusFilter || kycFilter || roleFilter) {
      setPage(1);
    } else {
      setPage(1);
    }
  }, [search, statusFilter, kycFilter, roleFilter]);

  const totalPages = Math.ceil(filteredUsers.length / PAGE_SIZE) || 1;
  const paginatedUsers = useMemo(() => {
    const startIndex = (page - 1) * PAGE_SIZE;
    return filteredUsers.slice(startIndex, startIndex + PAGE_SIZE);
  }, [filteredUsers, page]);

  const activeCount = users.filter((u) => u.status === "ACTIVE").length;
  const suspendedBlockedCount = users.filter(
    (u) => u.status !== "ACTIVE",
  ).length;
  const verifiedKycCount = users.filter(
    (u) => u.kycStatus === "VERIFIED",
  ).length;

  const handleToggleBlock = (user: UserItem) => {
    const nextStatus: UserStatus =
      user.status === "BLOCKED" ? "ACTIVE" : "BLOCKED";
    toggleUserStatus(user.id, nextStatus);
    notifications.show({
      title:
        nextStatus === "BLOCKED"
          ? "User Account Blocked"
          : "User Account Restored",
      message: `${user.fullName} (@${user.username}) is now ${nextStatus}.`,
      color: nextStatus === "BLOCKED" ? "red" : "teal",
      icon:
        nextStatus === "BLOCKED" ? (
          <IconLock size={18} />
        ) : (
          <IconLockOpen size={18} />
        ),
    });
  };

  return (
    <Stack gap="lg">
      {/* Header */}
      <Group justify="space-between" align="flex-end">
        <Stack gap={2}>
          <Group gap="xs">
            <Text size="xs" c="dimmed" tt="uppercase" fw={700}>
              TRADEX Admin
            </Text>
            <Text size="xs" c="dimmed">
              /
            </Text>
            <Text size="xs" c="yellow.4" fw={700}>
              User Accounts
            </Text>
          </Group>
          <Title order={2} fw={800} c="white">
            User Management
          </Title>
          <Text size="sm" c="dimmed">
            Manage TRADEX player accounts, identity verification, balance state,
            and access controls.
          </Text>
        </Stack>

        <Group gap="sm">
          <Button
            variant="default"
            size="sm"
            leftSection={<IconDownload size={16} />}
            onClick={() => {
              notifications.show({
                title: "Export Started",
                message: "Exporting user directory snapshot to CSV...",
                color: "blue",
              });
            }}
          >
            Export CSV
          </Button>
        </Group>
      </Group>

      {/* Metrics Row */}
      <SimpleGrid cols={{ base: 1, sm: 2, md: 4 }} spacing="md">
        <Paper p="md" radius="md" withBorder bg="dark.8">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Total Accounts
            </Text>
            <IconUsers size={18} color="#94a3b8" />
          </Group>
          <Text size="xl" fw={800} c="white" mt="xs">
            {users.length}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            Registered on TRADEX
          </Text>
        </Paper>

        <Paper p="md" radius="md" withBorder bg="dark.8">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Active Accounts
            </Text>
            <IconUserCheck size={18} color="#20c997" />
          </Group>
          <Text size="xl" fw={800} c="emerald.4" mt="xs">
            {activeCount}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            Fully eligible to play draws
          </Text>
        </Paper>

        <Paper p="md" radius="md" withBorder bg="dark.8">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Suspended / Blocked
            </Text>
            <IconUserOff size={18} color="#ff8787" />
          </Group>
          <Text size="xl" fw={800} c="red.4" mt="xs">
            {suspendedBlockedCount}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            Security restricted
          </Text>
        </Paper>

        <Paper p="md" radius="md" withBorder bg="dark.8">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Verified KYC
            </Text>
            <IconUserExclamation size={18} color="#fad045" />
          </Group>
          <Text size="xl" fw={800} c="yellow.4" mt="xs">
            {verifiedKycCount}
          </Text>
          <Text size="xs" c="dimmed" mt={4}>
            Identity documents approved
          </Text>
        </Paper>
      </SimpleGrid>

      {/* Main Table Card */}
      <Card p="md" radius="md" withBorder bg="dark.8">
        <Stack gap="md">
          {/* Filters Bar */}
          <Group justify="space-between" wrap="wrap">
            <TextInput
              placeholder="Search by Name, Username, Phone, Email, Public ID..."
              leftSection={<IconSearch size={16} />}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ width: 340 }}
              size="sm"
            />

            <Group gap="sm">
              <Select
                placeholder="Account Status"
                data={[
                  { value: "ALL", label: "All Statuses" },
                  { value: "ACTIVE", label: "ACTIVE" },
                  { value: "SUSPENDED", label: "SUSPENDED" },
                  { value: "BLOCKED", label: "BLOCKED" },
                ]}
                value={statusFilter}
                onChange={(val) => setStatusFilter(val || "ALL")}
                size="sm"
                style={{ width: 140 }}
              />

              <Select
                placeholder="KYC Status"
                data={[
                  { value: "ALL", label: "All KYC" },
                  { value: "VERIFIED", label: "VERIFIED" },
                  { value: "PENDING", label: "PENDING" },
                  { value: "REJECTED", label: "REJECTED" },
                  { value: "NOT_SUBMITTED", label: "NOT_SUBMITTED" },
                ]}
                value={kycFilter}
                onChange={(val) => setKycFilter(val || "ALL")}
                size="sm"
                style={{ width: 150 }}
              />

              <Select
                placeholder="Role"
                data={[
                  { value: "ALL", label: "All Roles" },
                  { value: "USER", label: "USER" },
                  { value: "AGENT", label: "AGENT" },
                ]}
                value={roleFilter}
                onChange={(val) => setRoleFilter(val || "ALL")}
                size="sm"
                style={{ width: 120 }}
              />
            </Group>
          </Group>

          {/* User Table */}
          <Table.ScrollContainer minWidth={950}>
            <Table verticalSpacing="sm">
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>User Profile</Table.Th>
                  <Table.Th>Contact Info</Table.Th>
                  <Table.Th>Wallet Balance</Table.Th>
                  <Table.Th>KYC Status</Table.Th>
                  <Table.Th>Account Status</Table.Th>
                  <Table.Th>Joined Date</Table.Th>
                  <Table.Th style={{ textAlign: "right" }}>Actions</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {paginatedUsers.length === 0 ? (
                  <Table.Tr>
                    <Table.Td colSpan={7} ta="center" py="xl">
                      <Text size="sm" c="dimmed">
                        No users match the search criteria.
                      </Text>
                    </Table.Td>
                  </Table.Tr>
                ) : (
                  paginatedUsers.map((user) => (
                    <Table.Tr key={user.id}>
                      {/* User Cell */}
                      <Table.Td>
                        <Group gap="sm" wrap="nowrap">
                          <Avatar
                            src={user.avatarUrl}
                            radius="xl"
                            size="md"
                            color="tradexNavy"
                          >
                            {user.fullName.slice(0, 2).toUpperCase()}
                          </Avatar>
                          <Stack gap={1}>
                            <Group gap={6}>
                              <Text size="sm" fw={700}>
                                {user.fullName}
                              </Text>
                              {user.role === "AGENT" && (
                                <Badge color="grape" size="xs" variant="filled">
                                  AGENT
                                </Badge>
                              )}
                            </Group>
                            <Text size="xs" c="dimmed">
                              @{user.username}
                            </Text>
                            <Group gap={4}>
                              <Text size="10px" c="dimmed" ff="monospace">
                                {user.publicId.slice(0, 12)}...
                              </Text>
                              <CopyButton value={user.publicId} timeout={2000}>
                                {({ copied, copy }) => (
                                  <Tooltip
                                    label={copied ? "Copied" : "Copy ID"}
                                    withArrow
                                  >
                                    <ActionIcon
                                      color={copied ? "teal" : "gray"}
                                      variant="subtle"
                                      size="xs"
                                      onClick={copy}
                                    >
                                      {copied ? (
                                        <IconCheck size={10} />
                                      ) : (
                                        <IconCopy size={10} />
                                      )}
                                    </ActionIcon>
                                  </Tooltip>
                                )}
                              </CopyButton>
                            </Group>
                          </Stack>
                        </Group>
                      </Table.Td>

                      {/* Contact */}
                      <Table.Td>
                        <Stack gap={1}>
                          <Text size="xs" fw={600} ff="monospace">
                            {user.phone}
                          </Text>
                          <Text size="xs" c="dimmed">
                            {user.email}
                          </Text>
                        </Stack>
                      </Table.Td>

                      {/* Wallet Balance */}
                      <Table.Td>
                        <Stack gap={1}>
                          <Group gap={4}>
                            <Text size="xs" c="dimmed">
                              Avail:
                            </Text>
                            <Text size="sm" fw={700} c="emerald.4">
                              {formatBDT(user.availableBalanceMinor)}
                            </Text>
                          </Group>
                          {user.lockedBalanceMinor > 0 && (
                            <Group gap={4}>
                              <Text size="10px" c="dimmed">
                                Locked:
                              </Text>
                              <Text size="xs" fw={600} c="yellow.4">
                                {formatBDT(user.lockedBalanceMinor)}
                              </Text>
                            </Group>
                          )}
                        </Stack>
                      </Table.Td>

                      {/* KYC Status */}
                      <Table.Td>
                        <Badge
                          color={getStatusColor(user.kycStatus)}
                          size="sm"
                          variant="light"
                        >
                          {user.kycStatus}
                        </Badge>
                      </Table.Td>

                      {/* Account Status */}
                      <Table.Td>
                        <Badge
                          color={getStatusColor(user.status)}
                          size="sm"
                          variant="filled"
                        >
                          {user.status}
                        </Badge>
                      </Table.Td>

                      {/* Joined Date */}
                      <Table.Td>
                        <Text size="xs" c="dimmed">
                          {formatDateTime(user.createdAt).split(",")[0]}
                        </Text>
                      </Table.Td>

                      {/* Actions Menu */}
                      <Table.Td>
                        <Group justify="flex-end" gap="xs">
                          <Button
                            variant="light"
                            size="xs"
                            leftSection={<IconEye size={14} />}
                            onClick={() => setSelectedUserDetails(user)}
                          >
                            Details
                          </Button>

                          <Menu shadow="md" width={180} position="bottom-end">
                            <Menu.Target>
                              <ActionIcon variant="subtle" color="gray">
                                <IconDotsVertical size={16} />
                              </ActionIcon>
                            </Menu.Target>

                            <Menu.Dropdown bg="dark.8">
                              <Menu.Label>User Actions</Menu.Label>
                              <Menu.Item
                                leftSection={<IconEye size={14} />}
                                onClick={() => setSelectedUserDetails(user)}
                              >
                                View Details
                              </Menu.Item>
                              <Menu.Item
                                leftSection={
                                  <IconScale size={14} color="#fad045" />
                                }
                                onClick={() => setAdjustBalanceUserId(user.id)}
                              >
                                Adjust Balance
                              </Menu.Item>
                              <Menu.Divider />
                              {user.status === "BLOCKED" ? (
                                <Menu.Item
                                  color="teal"
                                  leftSection={<IconLockOpen size={14} />}
                                  onClick={() => handleToggleBlock(user)}
                                >
                                  Unblock User
                                </Menu.Item>
                              ) : (
                                <Menu.Item
                                  color="red"
                                  leftSection={<IconLock size={14} />}
                                  onClick={() => handleToggleBlock(user)}
                                >
                                  Block User
                                </Menu.Item>
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
          </Table.ScrollContainer>

          {filteredUsers.length > 0 && (
            <Group justify="space-between" align="center" mt="xs" wrap="wrap">
              <Text size="xs" c="dimmed">
                Showing {(page - 1) * PAGE_SIZE + 1} to{" "}
                {Math.min(page * PAGE_SIZE, filteredUsers.length)} of{" "}
                {filteredUsers.length} entries
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

      {/* User Details Modal */}
      <UserDetailsModal
        opened={!!selectedUserDetails}
        onClose={() => setSelectedUserDetails(null)}
        user={selectedUserDetails}
        onAdjustBalance={(u) => setAdjustBalanceUserId(u.id)}
      />

      {/* Balance Adjustment Modal prefilled with user */}
      <AdminAdjustBalanceModal
        opened={!!adjustBalanceUserId}
        onClose={() => setAdjustBalanceUserId(null)}
        preselectedUserId={adjustBalanceUserId}
      />
    </Stack>
  );
}
