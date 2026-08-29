"use client";

import {
  ActionIcon,
  Avatar,
  Badge,
  Button,
  CopyButton,
  Divider,
  Group,
  Modal,
  Paper,
  SimpleGrid,
  Stack,
  Text,
  Tooltip,
} from "@mantine/core";
import { notifications } from "@mantine/notifications";
import {
  IconArrowDownLeft,
  IconArrowUpRight,
  IconCalendar,
  IconCheck,
  IconCopy,
  IconLock,
  IconLockOpen,
  IconMail,
  IconPhone,
  IconScale,
  IconTicket,
  IconTrophy,
  IconUser,
} from "@tabler/icons-react";
import { formatBDT, formatDateTime, getStatusColor } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";
import type { UserItem, UserStatus } from "@/types";

interface UserDetailsModalProps {
  opened: boolean;
  onClose: () => void;
  user: UserItem | null;
  onAdjustBalance?: (user: UserItem) => void;
}

export function UserDetailsModal({
  opened,
  onClose,
  user,
  onAdjustBalance,
}: UserDetailsModalProps) {
  const toggleUserStatus = useAdminStore((s) => s.toggleUserStatus);

  if (!user) return null;

  const handleToggleStatus = () => {
    const nextStatus: UserStatus =
      user.status === "BLOCKED" ? "ACTIVE" : "BLOCKED";
    toggleUserStatus(user.id, nextStatus);
    notifications.show({
      title: nextStatus === "BLOCKED" ? "User Blocked" : "User Unblocked",
      message: `Account status for ${user.fullName} changed to ${nextStatus}.`,
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
    <Modal
      opened={opened}
      onClose={onClose}
      title={
        <Group gap="xs">
          <IconUser size={20} color="#F59E0B" />
          <Text fw={800} size="md">
            User Account Profile
          </Text>
        </Group>
      }
      size="lg"
      centered
    >
      <Stack gap="md">
        {/* User Card Header */}
        <Paper p="md" radius="lg" withBorder>
          <Group justify="space-between" align="center">
            <Group gap="md">
              <Avatar
                src={user.avatarUrl}
                size="lg"
                radius="xl"
                variant="gradient"
                gradient={{ from: "#D97706", to: "#F59E0B", deg: 135 }}
                c="#070B14"
                fw={800}
              >
                {user.fullName.slice(0, 2).toUpperCase()}
              </Avatar>
              <Stack gap={2}>
                <Group gap="xs">
                  <Text size="lg" fw={800}>
                    {user.fullName}
                  </Text>
                  <Badge color="blue" size="xs" variant="light">
                    {user.role}
                  </Badge>
                </Group>
                <Text size="xs" c="dimmed">
                  @{user.username}
                </Text>
                <Group gap={4}>
                  <Text size="xs" c="dimmed" ff="monospace">
                    ID: {user.publicId.slice(0, 18)}...
                  </Text>
                  <CopyButton value={user.publicId} timeout={2000}>
                    {({ copied, copy }) => (
                      <Tooltip
                        label={copied ? "Copied" : "Copy Public ID"}
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
              </Stack>
            </Group>

            <Stack gap="xs" align="flex-end">
              <Badge
                color={getStatusColor(user.status)}
                size="md"
                variant="filled"
              >
                {user.status}
              </Badge>
              <Badge
                color={getStatusColor(user.kycStatus)}
                size="sm"
                variant="outline"
              >
                KYC: {user.kycStatus}
              </Badge>
            </Stack>
          </Group>
        </Paper>

        {/* Contact & Registration Info */}
        <SimpleGrid cols={{ base: 1, sm: 3 }} spacing="sm">
          <Paper p="sm" radius="md" withBorder>
            <Group gap="xs">
              <IconPhone size={16} color="#10B981" />
              <Stack gap={1}>
                <Text size="xs" c="dimmed" fw={600}>
                  Phone Number
                </Text>
                <Text size="xs" fw={700} ff="monospace">
                  {user.phone}
                </Text>
              </Stack>
            </Group>
          </Paper>
          <Paper p="sm" radius="md" withBorder>
            <Group gap="xs">
              <IconMail size={16} color="#3B82F6" />
              <Stack gap={1}>
                <Text size="xs" c="dimmed" fw={600}>
                  Email Address
                </Text>
                <Text size="xs" fw={600} truncate>
                  {user.email}
                </Text>
              </Stack>
            </Group>
          </Paper>
          <Paper p="sm" radius="md" withBorder>
            <Group gap="xs">
              <IconCalendar size={16} color="#F59E0B" />
              <Stack gap={1}>
                <Text size="xs" c="dimmed" fw={600}>
                  Joined TRADEX
                </Text>
                <Text size="xs" fw={600} className="font-tabular">
                  {formatDateTime(user.createdAt).split(",")[0]}
                </Text>
              </Stack>
            </Group>
          </Paper>
        </SimpleGrid>

        {/* Financial Breakdown */}
        <Stack gap="xs">
          <Text size="xs" fw={700} c="dimmed" tt="uppercase">
            Financial Ledger & Wallet Breakdown
          </Text>

          <SimpleGrid cols={{ base: 2, sm: 4 }} spacing="sm">
            <Paper p="sm" radius="md" withBorder>
              <Text size="xs" c="dimmed" fw={600}>
                Available Balance
              </Text>
              <Text size="md" fw={900} c="emerald.4" className="font-tabular">
                {formatBDT(user.availableBalanceMinor)}
              </Text>
            </Paper>
            <Paper p="sm" radius="md" withBorder>
              <Text size="xs" c="dimmed" fw={600}>
                Locked Balance
              </Text>
              <Text size="md" fw={900} c="yellow.4" className="font-tabular">
                {formatBDT(user.lockedBalanceMinor)}
              </Text>
            </Paper>
            <Paper p="sm" radius="md" withBorder>
              <Group gap={4}>
                <IconArrowDownLeft size={14} color="#10B981" />
                <Text size="xs" c="dimmed" fw={600}>
                  Total Deposits
                </Text>
              </Group>
              <Text size="sm" fw={700} className="font-tabular">
                {formatBDT(user.totalDepositsMinor)}
              </Text>
            </Paper>
            <Paper p="sm" radius="md" withBorder>
              <Group gap={4}>
                <IconArrowUpRight size={14} color="#EF4444" />
                <Text size="xs" c="dimmed" fw={600}>
                  Total Withdrawals
                </Text>
              </Group>
              <Text size="sm" fw={700} className="font-tabular">
                {formatBDT(user.totalWithdrawalsMinor)}
              </Text>
            </Paper>
          </SimpleGrid>

          <SimpleGrid cols={{ base: 2, sm: 2 }} spacing="sm" mt={2}>
            <Paper p="sm" radius="md" withBorder>
              <Group justify="space-between">
                <Group gap={4}>
                  <IconTicket size={16} color="#3B82F6" />
                  <Text size="xs" c="dimmed" fw={600}>
                    Tickets Purchased
                  </Text>
                </Group>
                <Text size="sm" fw={800} className="font-tabular">
                  {user.totalTicketsBought}
                </Text>
              </Group>
            </Paper>
            <Paper p="sm" radius="md" withBorder>
              <Group justify="space-between">
                <Group gap={4}>
                  <IconTrophy size={16} color="#F59E0B" />
                  <Text size="xs" c="dimmed" fw={600}>
                    Total Prize Winnings
                  </Text>
                </Group>
                <Text size="sm" fw={900} c="emerald.4" className="font-tabular">
                  {formatBDT(user.totalWonMinor)}
                </Text>
              </Group>
            </Paper>
          </SimpleGrid>
        </Stack>

        <Divider />

        {/* Action Controls */}
        <Group justify="space-between">
          <Button variant="default" onClick={onClose}>
            Close
          </Button>

          <Group gap="sm">
            <Button
              color={user.status === "BLOCKED" ? "teal" : "red"}
              variant="light"
              onClick={handleToggleStatus}
              leftSection={
                user.status === "BLOCKED" ? (
                  <IconLockOpen size={16} />
                ) : (
                  <IconLock size={16} />
                )
              }
            >
              {user.status === "BLOCKED" ? "Unblock Account" : "Block Account"}
            </Button>

            {onAdjustBalance && (
              <Button
                color="tradexGold"
                style={{ color: "#070B14", fontWeight: 800 }}
                onClick={() => {
                  onClose();
                  onAdjustBalance(user);
                }}
                leftSection={<IconScale size={16} />}
              >
                Adjust Balance
              </Button>
            )}
          </Group>
        </Group>
      </Stack>
    </Modal>
  );
}
