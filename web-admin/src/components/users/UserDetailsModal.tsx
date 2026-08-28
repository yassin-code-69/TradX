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
  const { toggleUserStatus } = useAdminStore();

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
          <IconUser size={20} color="#fad045" />
          <Text fw={700} size="md">
            User Account Profile
          </Text>
        </Group>
      }
      size="lg"
      centered
    >
      <Stack gap="md">
        {/* User Card Header */}
        <Paper p="md" radius="md" withBorder bg="dark.8">
          <Group justify="space-between" align="center">
            <Group gap="md">
              <Avatar
                src={user.avatarUrl}
                size="lg"
                radius="xl"
                color="tradexNavy"
              >
                {user.fullName.slice(0, 2).toUpperCase()}
              </Avatar>
              <Stack gap={2}>
                <Group gap="xs">
                  <Text size="lg" fw={700}>
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
          <Paper p="sm" radius="md" withBorder bg="dark.8">
            <Group gap="xs">
              <IconPhone size={16} color="#38d9a9" />
              <Stack gap={1}>
                <Text size="xs" c="dimmed">
                  Phone Number
                </Text>
                <Text size="xs" fw={600}>
                  {user.phone}
                </Text>
              </Stack>
            </Group>
          </Paper>
          <Paper p="sm" radius="md" withBorder bg="dark.8">
            <Group gap="xs">
              <IconMail size={16} color="#638cdd" />
              <Stack gap={1}>
                <Text size="xs" c="dimmed">
                  Email Address
                </Text>
                <Text size="xs" fw={600} truncate>
                  {user.email}
                </Text>
              </Stack>
            </Group>
          </Paper>
          <Paper p="sm" radius="md" withBorder bg="dark.8">
            <Group gap="xs">
              <IconCalendar size={16} color="#fad045" />
              <Stack gap={1}>
                <Text size="xs" c="dimmed">
                  Joined TRADEX
                </Text>
                <Text size="xs" fw={600}>
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
            <Paper p="sm" radius="md" withBorder bg="dark.8">
              <Text size="xs" c="dimmed">
                Available Balance
              </Text>
              <Text size="md" fw={700} c="emerald.4">
                {formatBDT(user.availableBalanceMinor)}
              </Text>
            </Paper>
            <Paper p="sm" radius="md" withBorder bg="dark.8">
              <Text size="xs" c="dimmed">
                Locked Balance
              </Text>
              <Text size="md" fw={700} c="yellow.4">
                {formatBDT(user.lockedBalanceMinor)}
              </Text>
            </Paper>
            <Paper p="sm" radius="md" withBorder bg="dark.8">
              <Group gap={4}>
                <IconArrowDownLeft size={14} color="#38d9a9" />
                <Text size="xs" c="dimmed">
                  Total Deposits
                </Text>
              </Group>
              <Text size="sm" fw={600}>
                {formatBDT(user.totalDepositsMinor)}
              </Text>
            </Paper>
            <Paper p="sm" radius="md" withBorder bg="dark.8">
              <Group gap={4}>
                <IconArrowUpRight size={14} color="#ff8787" />
                <Text size="xs" c="dimmed">
                  Total Withdrawals
                </Text>
              </Group>
              <Text size="sm" fw={600}>
                {formatBDT(user.totalWithdrawalsMinor)}
              </Text>
            </Paper>
          </SimpleGrid>

          <SimpleGrid cols={{ base: 2, sm: 2 }} spacing="sm" mt={2}>
            <Paper p="sm" radius="md" withBorder bg="dark.8">
              <Group justify="space-between">
                <Group gap={4}>
                  <IconTicket size={16} color="#87a7e4" />
                  <Text size="xs" c="dimmed">
                    Tickets Purchased
                  </Text>
                </Group>
                <Text size="sm" fw={700}>
                  {user.totalTicketsBought}
                </Text>
              </Group>
            </Paper>
            <Paper p="sm" radius="md" withBorder bg="dark.8">
              <Group justify="space-between">
                <Group gap={4}>
                  <IconTrophy size={16} color="#f9c212" />
                  <Text size="xs" c="dimmed">
                    Total Prize Winnings
                  </Text>
                </Group>
                <Text size="sm" fw={700} c="emerald.4">
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
                color="yellow"
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
