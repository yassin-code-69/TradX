"use client";

import {
  Badge,
  Box,
  Button,
  Card,
  Divider,
  Group,
  Modal,
  NumberInput,
  Paper,
  Select,
  SimpleGrid,
  Stack,
  Switch,
  Text,
  Textarea,
  TextInput,
  ThemeIcon,
  Title,
  UnstyledButton,
} from "@mantine/core";
import { notifications } from "@mantine/notifications";
import {
  IconAlertTriangle,
  IconBuildingBank,
  IconCheck,
  IconCreditCard,
  IconDeviceMobile,
  IconEdit,
  IconPlus,
  IconRefresh,
  IconServer,
  IconSettings,
  IconShieldLock,
  IconUser,
} from "@tabler/icons-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import { formatBDT } from "@/lib/formatters";
import { useLotteryStore } from "@/lib/store";
import type {
  PaymentMethodItem,
  PlatformGeneralSettings,
} from "@/types/lottery";

const SETTINGS_NAV_LINKS = [
  {
    label: "Payment Gateways & MFS",
    href: "/settings/gateways",
    icon: IconCreditCard,
  },
  {
    label: "General Platform Controls",
    href: "/settings/general",
    icon: IconServer,
  },
  {
    label: "Admin Profile & Account",
    href: "/settings/profile",
    icon: IconUser,
  },
  {
    label: "Security & API Keys",
    href: "/settings/security",
    icon: IconShieldLock,
  },
];

interface SettingsViewProps {
  initialTab?: "payment" | "general" | "profile" | "security";
}

export function SettingsView({ initialTab = "payment" }: SettingsViewProps) {
  const pathname = usePathname();
  const {
    paymentMethods,
    settings,
    updatePaymentMethod,
    addPaymentMethod,
    updateSettings,
    resetToDefaults,
  } = useLotteryStore();

  const activeTab = useMemo(() => {
    if (pathname === "/settings/general") return "general";
    if (pathname === "/settings/profile") return "profile";
    if (pathname === "/settings/security") return "security";
    return initialTab;
  }, [pathname, initialTab]);

  const [selectedMethodForEdit, setSelectedMethodForEdit] =
    useState<PaymentMethodItem | null>(null);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [addModalOpen, setAddModalOpen] = useState(false);

  const handleReset = useCallback(() => {
    resetToDefaults();
    notifications.show({
      title: "Settings Reset",
      message: "Platform and payment configurations restored to defaults.",
      color: "blue",
    });
  }, [resetToDefaults]);

  const handleOpenEdit = useCallback((method: PaymentMethodItem) => {
    setSelectedMethodForEdit({ ...method });
    setEditModalOpen(true);
  }, []);

  const handleSaveEdit = useCallback(() => {
    if (!selectedMethodForEdit) return;
    updatePaymentMethod(selectedMethodForEdit.id, selectedMethodForEdit);
    setEditModalOpen(false);
    notifications.show({
      title: "Gateway Updated",
      message: `${selectedMethodForEdit.name} details successfully saved.`,
      color: "teal",
      icon: <IconCheck size={18} />,
    });
  }, [selectedMethodForEdit, updatePaymentMethod]);

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
                <IconSettings size={22} stroke={2} />
              </ThemeIcon>
              <Box>
                <Title order={2} fw={800} c="var(--mantine-color-text)">
                  System & Platform Configuration
                </Title>
                <Text size="xs" c="dimmed" fw={600}>
                  Manage Mobile Financial Services (bKash, Nagad, Rocket), Bank
                  Gateway accounts, limits, and system controls.
                </Text>
              </Box>
            </Group>
          </Box>

          <Group gap="sm">
            <Button
              variant="default"
              size="sm"
              leftSection={<IconRefresh size={16} />}
              onClick={handleReset}
            >
              Reset to Defaults
            </Button>
          </Group>
        </Group>

        {/* Clean Path-Based Navigation Buttons (Zero ?x=y Query Routes) */}
        <Group gap="xs" wrap="wrap" mt="lg">
          {SETTINGS_NAV_LINKS.map((link) => {
            const active =
              link.href === "/settings/gateways"
                ? pathname === "/settings" || pathname === "/settings/gateways"
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

      {/* 2. Content Display based on active route */}
      {activeTab === "general" ? (
        <Card
          p="lg"
          radius="lg"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
        >
          <Title order={4} fw={800} mb="xs">
            General Platform Settings & Thresholds
          </Title>
          <Text size="xs" c="dimmed" mb="lg">
            Configure system-wide deposit limits, withdrawal fee rates, ticket
            commission margins, and service maintenance mode.
          </Text>

          <SimpleGrid cols={{ base: 1, md: 2 }} spacing="lg">
            <Paper p="md" radius="md" withBorder bg="var(--surface-card)">
              <Title order={5} fw={700} mb="sm">
                Financial Guardrails (BDT ৳)
              </Title>
              <Stack gap="sm">
                <NumberInput
                  label="Minimum Transfer (BDT)"
                  value={settings.minTransferMinor / 100}
                  onChange={(val) =>
                    updateSettings({
                      minTransferMinor: (Number(val) || 100) * 100,
                    })
                  }
                />
                <NumberInput
                  label="Maximum Transfer (BDT)"
                  value={settings.maxTransferMinor / 100}
                  onChange={(val) =>
                    updateSettings({
                      maxTransferMinor: (Number(val) || 10000) * 100,
                    })
                  }
                />
                <NumberInput
                  label="Daily Transfer Limit (BDT)"
                  value={settings.dailyTransferLimitMinor / 100}
                  onChange={(val) =>
                    updateSettings({
                      dailyTransferLimitMinor: (Number(val) || 50000) * 100,
                    })
                  }
                />
                <NumberInput
                  label="Transfer Fee (basis points)"
                  value={settings.transferFeeBps}
                  onChange={(val) =>
                    updateSettings({ transferFeeBps: Number(val) || 0 })
                  }
                />
              </Stack>
            </Paper>

            <Paper p="md" radius="md" withBorder bg="var(--surface-card)">
              <Title order={5} fw={700} mb="sm">
                System Operations & Controls
              </Title>
              <Stack gap="md">
                <Switch
                  label="Platform Maintenance Mode"
                  description="Temporarily block ticket sales and deposit approvals during server migrations."
                  checked={settings.maintenanceMode}
                  onChange={(e) =>
                    updateSettings({ maintenanceMode: e.currentTarget.checked })
                  }
                />
                <Switch
                  label="Automatic P2P Transfers"
                  description="Enable immediate peer-to-peer balance transfers without manual admin approval."
                  checked={settings.allowUserTransfers}
                  onChange={(e) =>
                    updateSettings({
                      allowUserTransfers: e.currentTarget.checked,
                    })
                  }
                />
                <Switch
                  label="Allow Withdrawals"
                  description="Enable withdrawal requests and automated payouts."
                  checked={settings.allowWithdrawals}
                  onChange={(e) =>
                    updateSettings({
                      allowWithdrawals: e.currentTarget.checked,
                    })
                  }
                />
              </Stack>
            </Paper>
          </SimpleGrid>
        </Card>
      ) : activeTab === "profile" ? (
        <Card
          p="lg"
          radius="lg"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
        >
          <Title order={4} fw={800} mb="xs">
            Administrator Profile & Credentials
          </Title>
          <Text size="xs" c="dimmed" mb="lg">
            Manage your developer and supervisor identity, notification
            preferences, and session tokens.
          </Text>

          <SimpleGrid cols={{ base: 1, md: 2 }} spacing="lg">
            <Paper p="md" radius="md" withBorder bg="var(--surface-card)">
              <Stack gap="sm">
                <TextInput
                  label="Admin Full Name"
                  defaultValue="System Administrator"
                />
                <TextInput
                  label="Email Address"
                  defaultValue="admin@xoxoshop.com"
                  disabled
                />
                <TextInput
                  label="Role / Authorization"
                  defaultValue="SUPER_ADMIN"
                  disabled
                />
                <Button color="tradexGold" c="#070B14" fw={700} mt="sm">
                  Update Profile Details
                </Button>
              </Stack>
            </Paper>
          </SimpleGrid>
        </Card>
      ) : activeTab === "security" ? (
        <Card
          p="lg"
          radius="lg"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
        >
          <Title order={4} fw={800} mb="xs">
            Security Credentials & API Keys
          </Title>
          <Text size="xs" c="dimmed" mb="lg">
            Supabase authorization tokens, cryptographic draw seed salts, and
            audit webhook keys.
          </Text>

          <SimpleGrid cols={{ base: 1, md: 2 }} spacing="lg">
            <Paper p="md" radius="md" withBorder bg="var(--surface-card)">
              <Stack gap="sm">
                <TextInput
                  label="Supabase Connected Project Ref"
                  defaultValue="mqrtqldebapvllidkcgs"
                  disabled
                />
                <TextInput
                  label="Platform API URL"
                  defaultValue="https://mqrtqldebapvllidkcgs.supabase.co"
                  disabled
                />
                <Switch
                  label="Enforce Two-Factor Authentication (2FA) for Admins"
                  defaultChecked
                />
              </Stack>
            </Paper>
          </SimpleGrid>
        </Card>
      ) : (
        <Stack gap="md">
          <Group justify="space-between">
            <Box>
              <Title order={4} fw={800}>
                Active Payment Gateways & Manual Accounts (
                {paymentMethods.length})
              </Title>
              <Text size="xs" c="dimmed">
                Configure MFS merchant numbers, personal send-money accounts,
                bank routing codes, and auto-settlement webhooks.
              </Text>
            </Box>
            <Button
              color="tradexGold"
              c="#070B14"
              fw={700}
              leftSection={<IconPlus size={16} />}
              onClick={() => setAddModalOpen(true)}
            >
              Add Payment Gateway
            </Button>
          </Group>

          <SimpleGrid cols={{ base: 1, md: 2, lg: 3 }} spacing="md">
            {paymentMethods.map((method) => (
              <Card
                key={method.id}
                p="md"
                radius="lg"
                withBorder
                bg="var(--surface-card)"
                className="glass-card-hover"
              >
                <Group justify="space-between" mb="xs">
                  <Group gap="xs">
                    <ThemeIcon
                      size={32}
                      radius="md"
                      color={method.type === "MOBILE_BANKING" ? "pink" : "blue"}
                      variant="light"
                    >
                      {method.type === "MOBILE_BANKING" ? (
                        <IconDeviceMobile size={18} />
                      ) : (
                        <IconBuildingBank size={18} />
                      )}
                    </ThemeIcon>
                    <Box>
                      <Text size="sm" fw={800}>
                        {method.name}
                      </Text>
                      <Text size="11px" c="dimmed">
                        {method.type} • {method.code}
                      </Text>
                    </Box>
                  </Group>
                  <Badge
                    color={method.status === "ACTIVE" ? "teal" : "gray"}
                    size="sm"
                  >
                    {method.status === "ACTIVE" ? "Active" : "Disabled"}
                  </Badge>
                </Group>

                <Divider my="xs" />

                <Stack gap={4} mb="md">
                  <Group justify="space-between">
                    <Text size="11px" c="dimmed">
                      Account / Number:
                    </Text>
                    <Text size="xs" fw={700} className="font-tabular">
                      {method.accountNumber || "N/A"}
                    </Text>
                  </Group>
                  <Group justify="space-between">
                    <Text size="11px" c="dimmed">
                      Deposit Limits:
                    </Text>
                    <Text size="xs" fw={600} className="font-tabular">
                      {formatBDT(method.minimumDepositMinor)} -{" "}
                      {formatBDT(method.maximumDepositMinor)}
                    </Text>
                  </Group>
                </Stack>

                <Button
                  fullWidth
                  variant="light"
                  size="xs"
                  leftSection={<IconEdit size={14} />}
                  onClick={() => handleOpenEdit(method)}
                >
                  Edit Configuration
                </Button>
              </Card>
            ))}
          </SimpleGrid>
        </Stack>
      )}

      {/* Edit Gateway Modal */}
      {selectedMethodForEdit && (
        <Modal
          opened={editModalOpen}
          onClose={() => setEditModalOpen(false)}
          title={
            <Title order={4}>Edit Gateway: {selectedMethodForEdit.name}</Title>
          }
          radius="md"
        >
          <Stack gap="md">
            <TextInput
              label="Account Number / Wallet ID"
              value={selectedMethodForEdit.accountNumber}
              onChange={(e) =>
                setSelectedMethodForEdit({
                  ...selectedMethodForEdit,
                  accountNumber: e.currentTarget.value,
                })
              }
            />
            <NumberInput
              label="Minimum Deposit (BDT)"
              value={selectedMethodForEdit.minimumDepositMinor / 100}
              onChange={(val) =>
                setSelectedMethodForEdit({
                  ...selectedMethodForEdit,
                  minimumDepositMinor: (Number(val) || 100) * 100,
                })
              }
            />
            <NumberInput
              label="Maximum Deposit (BDT)"
              value={selectedMethodForEdit.maximumDepositMinor / 100}
              onChange={(val) =>
                setSelectedMethodForEdit({
                  ...selectedMethodForEdit,
                  maximumDepositMinor: (Number(val) || 50000) * 100,
                })
              }
            />
            <Switch
              label="Enable Gateway for Deposits & Withdrawals"
              checked={selectedMethodForEdit.status === "ACTIVE"}
              onChange={(e) =>
                setSelectedMethodForEdit({
                  ...selectedMethodForEdit,
                  status: e.currentTarget.checked ? "ACTIVE" : "INACTIVE",
                })
              }
            />
            <Group justify="flex-end" mt="sm">
              <Button variant="default" onClick={() => setEditModalOpen(false)}>
                Cancel
              </Button>
              <Button
                color="tradexGold"
                c="#070B14"
                fw={700}
                onClick={handleSaveEdit}
              >
                Save Changes
              </Button>
            </Group>
          </Stack>
        </Modal>
      )}
    </Stack>
  );
}

export default SettingsView;
