"use client";

import {
  ActionIcon,
  Avatar,
  Badge,
  Box,
  Button,
  Card,
  CopyButton,
  Group,
  Menu,
  Pagination,
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
import dynamic from "next/dynamic";
import Link from "next/link";
import { usePathname } from "next/navigation";
import React, {
  useCallback,
  useDeferredValue,
  useEffect,
  useMemo,
  useState,
} from "react";
import { formatBDT, formatDateTime, getStatusColor } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";
import type { UserItem, UserStatus } from "@/types";

const UserDetailsModal = dynamic(
  () => import("./UserDetailsModal").then((mod) => mod.UserDetailsModal),
  { ssr: false },
);

const AdminAdjustBalanceModal = dynamic(
  () =>
    import("@/components/finance/AdminAdjustBalanceModal").then(
      (mod) => mod.AdminAdjustBalanceModal,
    ),
  { ssr: false },
);

const PAGE_SIZE = 25;

const USERS_NAV_LINKS = [
  {
    label: "All Users",
    href: "/users",
    icon: IconUsers,
  },
  {
    label: "Active Accounts",
    href: "/users/active",
    icon: IconUserCheck,
  },
  {
    label: "Suspended & Blocked",
    href: "/users/blocked",
    icon: IconUserOff,
  },
];

export interface UsersViewProps {
  filter?: string;
  initialStatus?: string;
}

export function UsersView({ filter, initialStatus }: UsersViewProps = {}) {
  const pathname = usePathname();
  const users = useAdminStore((s) => s.users);
  const toggleUserStatus = useAdminStore((s) => s.toggleUserStatus);

  const effectiveInitialStatus = useMemo(() => {
    if (filter) return filter;
    if (initialStatus) return initialStatus;
    if (pathname === "/users/active") return "ACTIVE";
    if (pathname === "/users/blocked") return "BLOCKED";
    return "ALL";
  }, [filter, initialStatus, pathname]);

  // Filters with deferred value for concurrent search transitions
  const [search, setSearch] = useState("");
  const deferredSearch = useDeferredValue(search);
  const [debouncedSearch] = useDebouncedValue(deferredSearch, 200);
  const [statusFilter, setStatusFilter] = useState<string>(
    effectiveInitialStatus,
  );
  const [kycFilter, setKycFilter] = useState<string>("ALL");
  const [roleFilter, setRoleFilter] = useState<string>("ALL");

  // Synchronize statusFilter when props or route path change
  useEffect(() => {
    if (filter) {
      setStatusFilter(filter);
    } else if (initialStatus) {
      setStatusFilter(initialStatus);
    } else if (pathname === "/users/active") {
      setStatusFilter("ACTIVE");
    } else if (pathname === "/users/blocked") {
      setStatusFilter("BLOCKED");
    } else if (pathname === "/users") {
      setStatusFilter("ALL");
    }
  }, [filter, initialStatus, pathname]);

  // Modals state
  const [selectedUserDetails, setSelectedUserDetails] =
    useState<UserItem | null>(null);
  const [adjustBalanceUserId, setAdjustBalanceUserId] = useState<string | null>(
    null,
  );

  // Filtered users with debounced & deferred search
  const filteredUsers = useMemo(() => {
    const q = debouncedSearch.toLowerCase().trim();
    return users.filter((u) => {
      if (q) {
        const matchesSearch =
          u.fullName.toLowerCase().includes(q) ||
          u.username.toLowerCase().includes(q) ||
          u.phone.toLowerCase().includes(q) ||
          u.email.toLowerCase().includes(q) ||
          u.publicId.toLowerCase().includes(q);
        if (!matchesSearch) return false;
      }

      if (statusFilter !== "ALL" && u.status !== statusFilter) return false;
      if (kycFilter !== "ALL" && u.kycStatus !== kycFilter) return false;
      if (roleFilter !== "ALL" && u.role !== roleFilter) return false;

      return true;
    });
  }, [users, debouncedSearch, statusFilter, kycFilter, roleFilter]);

  const [page, setPage] = useState(1);
  const totalPages = Math.ceil(filteredUsers.length / PAGE_SIZE) || 1;
  const currentPage = Math.min(page, totalPages);

  const paginatedUsers = useMemo(() => {
    const startIndex = (currentPage - 1) * PAGE_SIZE;
    return filteredUsers.slice(startIndex, startIndex + PAGE_SIZE);
  }, [filteredUsers, currentPage]);

  const activeCount = users.filter((u) => u.status === "ACTIVE").length;
  const suspendedBlockedCount = users.filter(
    (u) => u.status !== "ACTIVE",
  ).length;
  const verifiedKycCount = users.filter(
    (u) => u.kycStatus === "VERIFIED",
  ).length;

  const handleOpenDetails = useCallback((user: UserItem) => {
    setSelectedUserDetails(user);
  }, []);

  const handleOpenAdjustBalance = useCallback((userId: string) => {
    setAdjustBalanceUserId(userId);
  }, []);

  const handleToggleBlock = useCallback(
    (user: UserItem) => {
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
    },
    [toggleUserStatus],
  );

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
            <Group gap="xs" align="center">
              <ThemeIcon
                size={38}
                radius="lg"
                variant="gradient"
                gradient={{ from: "#D97706", to: "#F59E0B", deg: 135 }}
                c="#070B14"
              >
                <IconUsers size={22} stroke={2} />
              </ThemeIcon>
              <Box>
                <Title order={2} fw={800} c="var(--mantine-color-text)">
                  User Accounts & Access Management
                </Title>
                <Text size="xs" c="dimmed" fw={600}>
                  Manage TRADEX player accounts, identity verification, balance
                  state, and access controls.
                </Text>
              </Box>
            </Group>
          </Box>

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

        {/* Clean Path-Based Navigation Buttons (Zero ?x=y Query Routes) */}
        <Group gap="xs" wrap="wrap" mt="lg">
          {USERS_NAV_LINKS.map((link) => {
            const active =
              link.href === "/users"
                ? pathname === "/users"
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

      {/* 2. Metrics Row */}
      <SimpleGrid cols={{ base: 1, sm: 2, md: 4 }} spacing="md">
        <Card p="md" radius="lg" withBorder className="glass-card-hover">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Total Accounts
            </Text>
            <ThemeIcon size={36} radius="lg" color="gray" variant="light">
              <IconUsers size={18} />
            </ThemeIcon>
          </Group>
          <Text size="xl" fw={900} mt="xs" className="font-tabular">
            {users.length}
          </Text>
          <Text size="xs" c="dimmed" mt={4} fw={500}>
            Registered on TRADEX
          </Text>
        </Card>

        <Card p="md" radius="lg" withBorder className="glass-card-hover">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Active Accounts
            </Text>
            <ThemeIcon size={36} radius="lg" color="teal" variant="light">
              <IconUserCheck size={18} />
            </ThemeIcon>
          </Group>
          <Text
            size="xl"
            fw={900}
            c="emerald.4"
            mt="xs"
            className="font-tabular"
          >
            {activeCount}
          </Text>
          <Text size="xs" c="dimmed" mt={4} fw={500}>
            Fully eligible to play draws
          </Text>
        </Card>

        <Card p="md" radius="lg" withBorder className="glass-card-hover">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Suspended / Blocked
            </Text>
            <ThemeIcon size={36} radius="lg" color="red" variant="light">
              <IconUserOff size={18} />
            </ThemeIcon>
          </Group>
          <Text size="xl" fw={900} c="red.4" mt="xs" className="font-tabular">
            {suspendedBlockedCount}
          </Text>
          <Text size="xs" c="dimmed" mt={4} fw={500}>
            Security restricted
          </Text>
        </Card>

        <Card p="md" radius="lg" withBorder className="glass-card-hover">
          <Group justify="space-between">
            <Text size="xs" c="dimmed" fw={700} tt="uppercase">
              Verified KYC
            </Text>
            <ThemeIcon size={36} radius="lg" color="tradexGold" variant="light">
              <IconUserExclamation size={18} />
            </ThemeIcon>
          </Group>
          <Text
            size="xl"
            fw={900}
            c="tradexGold.4"
            mt="xs"
            className="font-tabular"
          >
            {verifiedKycCount}
          </Text>
          <Text size="xs" c="dimmed" mt={4} fw={500}>
            Identity documents approved
          </Text>
        </Card>
      </SimpleGrid>

      {/* 3. Main Table Card */}
      <Card p="md" radius="lg" withBorder>
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
                    <UserTableRow
                      key={user.id}
                      user={user}
                      onDetails={handleOpenDetails}
                      onAdjustBalance={handleOpenAdjustBalance}
                      onToggleBlock={handleToggleBlock}
                    />
                  ))
                )}
              </Table.Tbody>
            </Table>
          </Table.ScrollContainer>

          {filteredUsers.length > 0 && (
            <Group justify="space-between" align="center" mt="xs" wrap="wrap">
              <Text size="xs" c="dimmed" fw={500}>
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
      {selectedUserDetails && (
        <UserDetailsModal
          opened={!!selectedUserDetails}
          onClose={() => setSelectedUserDetails(null)}
          user={selectedUserDetails}
          onAdjustBalance={(u) => setAdjustBalanceUserId(u.id)}
        />
      )}

      {/* Balance Adjustment Modal prefilled with user */}
      {adjustBalanceUserId && (
        <AdminAdjustBalanceModal
          opened={!!adjustBalanceUserId}
          onClose={() => setAdjustBalanceUserId(null)}
          preselectedUserId={adjustBalanceUserId}
        />
      )}
    </Stack>
  );
}

// ==================== MEMOIZED USER TABLE ROW ====================

interface UserTableRowProps {
  user: UserItem;
  onDetails: (u: UserItem) => void;
  onAdjustBalance: (userId: string) => void;
  onToggleBlock: (u: UserItem) => void;
}

const UserTableRow = React.memo(function UserTableRow({
  user,
  onDetails,
  onAdjustBalance,
  onToggleBlock,
}: UserTableRowProps) {
  return (
    <Table.Tr key={user.id}>
      {/* User Cell */}
      <Table.Td>
        <Group gap="sm" wrap="nowrap">
          <Avatar
            src={user.avatarUrl}
            radius="xl"
            size="md"
            variant="gradient"
            gradient={{
              from: "#D97706",
              to: "#F59E0B",
              deg: 135,
            }}
            c="#070B14"
            fw={800}
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
                  <Tooltip label={copied ? "Copied" : "Copy ID"} withArrow>
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
            <Text size="sm" fw={800} c="emerald.4" className="font-tabular">
              {formatBDT(user.availableBalanceMinor)}
            </Text>
          </Group>
          {user.lockedBalanceMinor > 0 && (
            <Group gap={4}>
              <Text size="10px" c="dimmed">
                Locked:
              </Text>
              <Text size="xs" fw={700} c="yellow.4" className="font-tabular">
                {formatBDT(user.lockedBalanceMinor)}
              </Text>
            </Group>
          )}
        </Stack>
      </Table.Td>

      {/* KYC Status */}
      <Table.Td>
        <Badge color={getStatusColor(user.kycStatus)} size="sm" variant="light">
          {user.kycStatus}
        </Badge>
      </Table.Td>

      {/* Account Status */}
      <Table.Td>
        <Badge color={getStatusColor(user.status)} size="sm" variant="filled">
          {user.status}
        </Badge>
      </Table.Td>

      {/* Joined Date */}
      <Table.Td>
        <Text size="xs" c="dimmed" className="font-tabular">
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
            onClick={() => onDetails(user)}
          >
            Details
          </Button>

          <Menu shadow="xl" width={180} position="bottom-end">
            <Menu.Target>
              <ActionIcon variant="subtle" color="gray">
                <IconDotsVertical size={16} />
              </ActionIcon>
            </Menu.Target>

            <Menu.Dropdown>
              <Menu.Label>User Actions</Menu.Label>
              <Menu.Item
                leftSection={<IconEye size={14} />}
                onClick={() => onDetails(user)}
              >
                View Details
              </Menu.Item>
              <Menu.Item
                leftSection={<IconScale size={14} color="#F59E0B" />}
                onClick={() => onAdjustBalance(user.id)}
              >
                Adjust Balance
              </Menu.Item>
              <Menu.Divider />
              {user.status === "BLOCKED" ? (
                <Menu.Item
                  color="teal"
                  leftSection={<IconLockOpen size={14} />}
                  onClick={() => onToggleBlock(user)}
                >
                  Unblock User
                </Menu.Item>
              ) : (
                <Menu.Item
                  color="red"
                  leftSection={<IconLock size={14} />}
                  onClick={() => onToggleBlock(user)}
                >
                  Block User
                </Menu.Item>
              )}
            </Menu.Dropdown>
          </Menu>
        </Group>
      </Table.Td>
    </Table.Tr>
  );
});

export default UsersView;
