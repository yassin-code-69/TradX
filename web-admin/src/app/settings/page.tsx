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
  Tabs,
  Text,
  Textarea,
  TextInput,
  ThemeIcon,
  Title,
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
} from "@tabler/icons-react";
import { useState } from "react";
import { formatBDT } from "@/lib/formatters";
import { useLotteryStore } from "@/lib/store";
import type {
  PaymentMethodItem,
  PlatformGeneralSettings,
} from "@/types/lottery";

export default function SettingsPage() {
  const {
    paymentMethods,
    settings,
    updatePaymentMethod,
    addPaymentMethod,
    updateSettings,
    resetToDefaults,
  } = useLotteryStore();

  // Active tab state
  const [activeTab, setActiveTab] = useState<string | null>("payment");

  // Edit Payment Method Modal state
  const [editingMethod, setEditingMethod] = useState<PaymentMethodItem | null>(
    null,
  );
  const [editAccountNumber, setEditAccountNumber] = useState("");
  const [editAccountName, setEditAccountName] = useState("");
  const [editInstructions, setEditInstructions] = useState("");
  const [editMinDepositBDT, setEditMinDepositBDT] = useState<number | string>(
    100,
  );
  const [editMaxDepositBDT, setEditMaxDepositBDT] = useState<number | string>(
    25000,
  );
  const [editMinWithdrawBDT, setEditMinWithdrawBDT] = useState<number | string>(
    500,
  );
  const [editMaxWithdrawBDT, setEditMaxWithdrawBDT] = useState<number | string>(
    25000,
  );
  const [editDepositFeePct, setEditDepositFeePct] = useState<number | string>(
    1.5,
  );
  const [editWithdrawFeePct, setEditWithdrawFeePct] = useState<number | string>(
    1.8,
  );
  const [editDepositEnabled, setEditDepositEnabled] = useState(true);
  const [editWithdrawEnabled, setEditWithdrawEnabled] = useState(true);
  const [editStatus, setEditStatus] = useState<"ACTIVE" | "INACTIVE">("ACTIVE");

  // Add Payment Method Modal state
  const [addModalOpen, setAddModalOpen] = useState(false);
  const [newCode, setNewCode] = useState<"BKASH" | "NAGAD" | "ROCKET" | "BANK">(
    "BKASH",
  );
  const [newName, setNewName] = useState("");
  const [newType, setNewType] = useState<"MOBILE_BANKING" | "BANK_TRANSFER">(
    "MOBILE_BANKING",
  );
  const [newAccountNo, setNewAccountNo] = useState("");
  const [newAccountHolder, setNewAccountHolder] = useState(
    "TRADEX Operations Bangladesh Ltd",
  );
  const [newInstructionsText, setNewInstructionsText] = useState("");

  // General Settings Form state
  const [genSettings, setGenSettings] =
    useState<PlatformGeneralSettings>(settings);
  const [isSavingSettings, setIsSavingSettings] = useState(false);

  // Open edit modal for payment method
  const handleOpenEditMethod = (pm: PaymentMethodItem) => {
    setEditingMethod(pm);
    setEditAccountNumber(pm.accountNumber);
    setEditAccountName(pm.accountName);
    setEditInstructions(pm.instructions);
    setEditMinDepositBDT(pm.minimumDepositMinor / 100);
    setEditMaxDepositBDT(pm.maximumDepositMinor / 100);
    setEditMinWithdrawBDT(pm.minimumWithdrawMinor / 100);
    setEditMaxWithdrawBDT(pm.maximumWithdrawMinor / 100);
    setEditDepositFeePct(pm.depositFeePercentageBasisPoints / 100);
    setEditWithdrawFeePct(pm.withdrawFeePercentageBasisPoints / 100);
    setEditDepositEnabled(pm.depositEnabled);
    setEditWithdrawEnabled(pm.withdrawEnabled);
    setEditStatus(pm.status);
  };

  // Save payment method changes
  const handleSaveMethod = () => {
    if (!editingMethod) return;

    const minDepMinor = Math.round(Number(editMinDepositBDT) * 100);
    const maxDepMinor = Math.round(Number(editMaxDepositBDT) * 100);
    const minWdMinor = Math.round(Number(editMinWithdrawBDT) * 100);
    const maxWdMinor = Math.round(Number(editMaxWithdrawBDT) * 100);
    const depFeeBps = Math.round(Number(editDepositFeePct) * 100);
    const wdFeeBps = Math.round(Number(editWithdrawFeePct) * 100);

    updatePaymentMethod(editingMethod.id, {
      accountNumber: editAccountNumber,
      accountName: editAccountName,
      instructions: editInstructions,
      minimumDepositMinor: minDepMinor,
      maximumDepositMinor: maxDepMinor,
      minimumWithdrawMinor: minWdMinor,
      maximumWithdrawMinor: maxWdMinor,
      depositFeePercentageBasisPoints: depFeeBps,
      withdrawFeePercentageBasisPoints: wdFeeBps,
      depositEnabled: editDepositEnabled,
      withdrawEnabled: editWithdrawEnabled,
      status: editStatus,
    });

    notifications.show({
      title: "Payment Gateway Updated",
      message: `${editingMethod.name} account & limits configuration saved.`,
      color: "teal",
      icon: <IconCheck size={18} />,
    });

    setEditingMethod(null);
  };

  // Create new payment method
  const handleCreatePaymentMethod = () => {
    if (!newName.trim() || !newAccountNo.trim()) {
      notifications.show({
        title: "Validation Error",
        message: "Name and account number are required.",
        color: "red",
      });
      return;
    }

    addPaymentMethod({
      code: newCode,
      name: newName.trim(),
      type: newType,
      accountNumber: newAccountNo.trim(),
      accountName: newAccountHolder.trim(),
      instructions:
        newInstructionsText.trim() ||
        "Follow provider instructions to complete transfer.",
      minimumDepositMinor: 10000,
      maximumDepositMinor: 2500000,
      minimumWithdrawMinor: 50000,
      maximumWithdrawMinor: 2500000,
      depositFeePercentageBasisPoints: 150,
      depositFeeFixedMinor: 0,
      withdrawFeePercentageBasisPoints: 180,
      withdrawFeeFixedMinor: 0,
      depositEnabled: true,
      withdrawEnabled: true,
      status: "ACTIVE",
      displayOrder: paymentMethods.length + 1,
    });

    notifications.show({
      title: "Payment Gateway Added",
      message: `${newName} has been registered and activated.`,
      color: "teal",
      icon: <IconCheck size={18} />,
    });

    setAddModalOpen(false);
    setNewName("");
    setNewAccountNo("");
  };

  // Save General Platform Settings
  const handleSaveGeneralSettings = () => {
    setIsSavingSettings(true);
    setTimeout(() => {
      updateSettings(genSettings);
      setIsSavingSettings(false);
      notifications.show({
        title: "Platform Settings Updated",
        message:
          "General configuration, risk parameters, and feature toggles saved.",
        color: "teal",
        icon: <IconCheck size={18} />,
      });
    }, 400);
  };

  // Quick toggle for method
  const handleQuickToggle = (
    id: string,
    field: "depositEnabled" | "withdrawEnabled" | "status",
    currentVal: boolean | "ACTIVE" | "INACTIVE",
  ) => {
    const newVal =
      field === "status"
        ? currentVal === "ACTIVE"
          ? "INACTIVE"
          : "ACTIVE"
        : !currentVal;
    updatePaymentMethod(id, { [field]: newVal });

    notifications.show({
      title: "State Updated",
      message: `Gateway ${field} set to ${String(newVal)}.`,
      color: "blue",
    });
  };

  return (
    <Stack gap="lg">
      {/* 1. Header Card */}
      <Card p="lg" radius="md" withBorder>
        <Group justify="space-between" align="flex-start">
          <Box>
            <Group gap="xs" align="center">
              <ThemeIcon
                size={34}
                radius="md"
                color="tradexGold"
                variant="light"
              >
                <IconSettings
                  size={20}
                  color="var(--mantine-color-tradexGold-6)"
                />
              </ThemeIcon>
              <Box>
                <Title order={2} size="h3" fw={700}>
                  Platform & Payment Settings
                </Title>
                <Text size="xs" c="dimmed">
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
              onClick={() => {
                resetToDefaults();
                setGenSettings(settings);
                notifications.show({
                  title: "Settings Reset",
                  message:
                    "Platform and payment configurations restored to defaults.",
                  color: "blue",
                });
              }}
            >
              Reset to Defaults
            </Button>
          </Group>
        </Group>
      </Card>

      {/* 2. Settings Tabs */}
      <Tabs value={activeTab} onChange={setActiveTab}>
        <Tabs.List>
          <Tabs.Tab value="payment" leftSection={<IconCreditCard size={16} />}>
            Payment Methods ({paymentMethods.length})
          </Tabs.Tab>
          <Tabs.Tab value="general" leftSection={<IconServer size={16} />}>
            General Platform Settings
          </Tabs.Tab>
        </Tabs.List>

        {/* ========================================================================= */}
        {/* TAB 1: Payment Methods Configuration                                      */}
        {/* ========================================================================= */}
        <Tabs.Panel value="payment" pt="md">
          <Stack gap="md">
            {/* Top Action Bar for Payment Methods */}
            <Group justify="space-between">
              <Box>
                <Text size="sm" fw={700}>
                  Configured Payment Gateways
                </Text>
                <Text size="xs" c="dimmed">
                  Control deposit/withdraw routing, limits, merchant account
                  numbers, and fee structures.
                </Text>
              </Box>

              <Button
                color="tradexGold"
                style={{ color: "#0A0F1D", fontWeight: 700 }}
                leftSection={<IconPlus size={16} />}
                onClick={() => setAddModalOpen(true)}
              >
                Add Payment Method
              </Button>
            </Group>

            {/* Grid of Payment Method Cards */}
            <SimpleGrid cols={{ base: 1, md: 2 }} spacing="md">
              {paymentMethods.map((pm: PaymentMethodItem) => {
                const isBank = pm.type === "BANK_TRANSFER";

                return (
                  <Card key={pm.id} p="md" radius="md" withBorder>
                    <Stack gap="sm">
                      {/* Card Header: Icon, Provider, Status Badge */}
                      <Group justify="space-between" align="flex-start">
                        <Group gap="xs">
                          <ThemeIcon
                            size={40}
                            radius="md"
                            color={
                              pm.code === "BKASH"
                                ? "pink"
                                : pm.code === "NAGAD"
                                  ? "orange"
                                  : pm.code === "ROCKET"
                                    ? "violet"
                                    : "blue"
                            }
                            variant="light"
                          >
                            {isBank ? (
                              <IconBuildingBank size={22} />
                            ) : (
                              <IconDeviceMobile size={22} />
                            )}
                          </ThemeIcon>
                          <Box>
                            <Group gap={6}>
                              <Text fw={700} size="sm">
                                {pm.name}
                              </Text>
                              <Badge
                                size="xs"
                                color={pm.status === "ACTIVE" ? "teal" : "gray"}
                                variant="filled"
                              >
                                {pm.status}
                              </Badge>
                            </Group>
                            <Text size="11px" c="dimmed">
                              {isBank
                                ? "Corporate Bank Account"
                                : "MFS Merchant Channel"}
                            </Text>
                          </Box>
                        </Group>

                        <Button
                          size="xs"
                          variant="light"
                          color="blue"
                          leftSection={<IconEdit size={14} />}
                          onClick={() => handleOpenEditMethod(pm)}
                        >
                          Configure
                        </Button>
                      </Group>

                      {/* Account Number Box */}
                      <Paper
                        p="xs"
                        radius="sm"
                        withBorder
                        bg="rgba(0, 0, 0, 0.2)"
                      >
                        <Group justify="space-between">
                          <Box>
                            <Text size="10px" c="dimmed" tt="uppercase">
                              Receiving Account / Merchant Number
                            </Text>
                            <Text
                              fw={800}
                              size="sm"
                              ff="monospace"
                              c="tradexGold.4"
                            >
                              {pm.accountNumber}
                            </Text>
                          </Box>
                          <Box ta="right">
                            <Text size="10px" c="dimmed" tt="uppercase">
                              Account Holder
                            </Text>
                            <Text fw={600} size="xs">
                              {pm.accountName}
                            </Text>
                          </Box>
                        </Group>
                      </Paper>

                      {/* Limits & Fees Matrix */}
                      <SimpleGrid cols={2} spacing="xs">
                        <Paper
                          p="xs"
                          radius="sm"
                          withBorder
                          bg="rgba(0,0,0,0.08)"
                        >
                          <Text size="10px" c="dimmed">
                            Deposit Range
                          </Text>
                          <Text size="xs" fw={700}>
                            {formatBDT(pm.minimumDepositMinor)} —{" "}
                            {formatBDT(pm.maximumDepositMinor)}
                          </Text>
                          <Text size="10px" c="teal" mt={2}>
                            Fee:{" "}
                            {(pm.depositFeePercentageBasisPoints / 100).toFixed(
                              2,
                            )}
                            %
                          </Text>
                        </Paper>

                        <Paper
                          p="xs"
                          radius="sm"
                          withBorder
                          bg="rgba(0,0,0,0.08)"
                        >
                          <Text size="10px" c="dimmed">
                            Withdrawal Range
                          </Text>
                          <Text size="xs" fw={700}>
                            {formatBDT(pm.minimumWithdrawMinor)} —{" "}
                            {formatBDT(pm.maximumWithdrawMinor)}
                          </Text>
                          <Text size="10px" c="dimmed" mt={2}>
                            Fee:{" "}
                            {(
                              pm.withdrawFeePercentageBasisPoints / 100
                            ).toFixed(2)}
                            %
                            {pm.withdrawFeeFixedMinor > 0 &&
                              ` + ${formatBDT(pm.withdrawFeeFixedMinor)}`}
                          </Text>
                        </Paper>
                      </SimpleGrid>

                      {/* Instructions Snippet */}
                      <Text size="11px" c="dimmed" lineClamp={2}>
                        {pm.instructions}
                      </Text>

                      <Divider />

                      {/* Quick Toggles: Deposit & Withdraw Enabled */}
                      <Group justify="space-between">
                        <Group gap="lg">
                          <Switch
                            size="xs"
                            color="teal"
                            label="Deposits"
                            checked={pm.depositEnabled}
                            onChange={() =>
                              handleQuickToggle(
                                pm.id,
                                "depositEnabled",
                                pm.depositEnabled,
                              )
                            }
                          />
                          <Switch
                            size="xs"
                            color="teal"
                            label="Withdrawals"
                            checked={pm.withdrawEnabled}
                            onChange={() =>
                              handleQuickToggle(
                                pm.id,
                                "withdrawEnabled",
                                pm.withdrawEnabled,
                              )
                            }
                          />
                        </Group>

                        <Button
                          size="compact-xs"
                          variant="subtle"
                          color={pm.status === "ACTIVE" ? "red" : "teal"}
                          onClick={() =>
                            handleQuickToggle(pm.id, "status", pm.status)
                          }
                        >
                          {pm.status === "ACTIVE"
                            ? "Disable Gateway"
                            : "Enable Gateway"}
                        </Button>
                      </Group>
                    </Stack>
                  </Card>
                );
              })}
            </SimpleGrid>
          </Stack>
        </Tabs.Panel>

        {/* ========================================================================= */}
        {/* TAB 2: General Platform Settings                                          */}
        {/* ========================================================================= */}
        <Tabs.Panel value="general" pt="md">
          <Stack gap="lg">
            {/* Maintenance Mode Emergency Alert Card */}
            <Card
              p="md"
              radius="md"
              withBorder
              bg={
                genSettings.maintenanceMode
                  ? "rgba(239, 68, 68, 0.1)"
                  : undefined
              }
              style={{
                borderColor: genSettings.maintenanceMode
                  ? "#EF4444"
                  : undefined,
              }}
            >
              <Group justify="space-between" align="center">
                <Group gap="md">
                  <ThemeIcon
                    size={42}
                    radius="md"
                    color={genSettings.maintenanceMode ? "red" : "gray"}
                    variant="light"
                  >
                    <IconAlertTriangle size={24} />
                  </ThemeIcon>
                  <Box>
                    <Title order={4} size="h5" fw={700}>
                      System Maintenance Mode
                    </Title>
                    <Text size="xs" c="dimmed">
                      When enabled, user apps enter read-only maintenance.
                      Ticket sales and transactions will be suspended.
                    </Text>
                  </Box>
                </Group>

                <Switch
                  size="md"
                  color="red"
                  checked={genSettings.maintenanceMode}
                  onChange={(e) =>
                    setGenSettings({
                      ...genSettings,
                      maintenanceMode: e.currentTarget.checked,
                    })
                  }
                  label={
                    genSettings.maintenanceMode
                      ? "ACTIVE (LOCKED)"
                      : "OFF (NORMAL)"
                  }
                />
              </Group>
            </Card>

            {/* Platform Identification */}
            <Card p="lg" radius="md" withBorder>
              <Title order={4} size="h5" fw={700} mb="xs">
                Platform Identity & Support Channels
              </Title>
              <Text size="xs" c="dimmed" mb="md">
                Official contact details and timezone configuration shown to
                users on tickets and receipts.
              </Text>

              <SimpleGrid cols={{ base: 1, sm: 2 }} spacing="md">
                <TextInput
                  label="Platform Name"
                  value={genSettings.platformName}
                  onChange={(e) =>
                    setGenSettings({
                      ...genSettings,
                      platformName: e.currentTarget.value,
                    })
                  }
                />

                <TextInput
                  label="Timezone"
                  value={genSettings.timezone}
                  disabled
                  description="System operational timezone"
                />

                <TextInput
                  label="Support Email"
                  value={genSettings.supportEmail}
                  onChange={(e) =>
                    setGenSettings({
                      ...genSettings,
                      supportEmail: e.currentTarget.value,
                    })
                  }
                />

                <TextInput
                  label="Support Phone (Hotline)"
                  value={genSettings.supportPhone}
                  onChange={(e) =>
                    setGenSettings({
                      ...genSettings,
                      supportPhone: e.currentTarget.value,
                    })
                  }
                />
              </SimpleGrid>
            </Card>

            {/* Feature Flags & Operational Toggles */}
            <Card p="lg" radius="md" withBorder>
              <Title order={4} size="h5" fw={700} mb="xs">
                Module Feature Flags
              </Title>
              <Text size="xs" c="dimmed" mb="md">
                Enable or temporarily disable specific lottery tiers and
                platform capabilities.
              </Text>

              <SimpleGrid cols={{ base: 1, sm: 2, lg: 3 }} spacing="md">
                <Paper p="sm" radius="md" withBorder>
                  <Group justify="space-between">
                    <Box>
                      <Text size="xs" fw={700}>
                        User-to-User Transfer
                      </Text>
                      <Text size="11px" c="dimmed">
                        Allow wallet send money
                      </Text>
                    </Box>
                    <Switch
                      color="teal"
                      checked={genSettings.allowUserTransfers}
                      onChange={(e) =>
                        setGenSettings({
                          ...genSettings,
                          allowUserTransfers: e.currentTarget.checked,
                        })
                      }
                    />
                  </Group>
                </Paper>

                <Paper p="sm" radius="md" withBorder>
                  <Group justify="space-between">
                    <Box>
                      <Text size="xs" fw={700}>
                        Withdrawal Gateway
                      </Text>
                      <Text size="11px" c="dimmed">
                        Allow payout requests
                      </Text>
                    </Box>
                    <Switch
                      color="teal"
                      checked={genSettings.allowWithdrawals}
                      onChange={(e) =>
                        setGenSettings({
                          ...genSettings,
                          allowWithdrawals: e.currentTarget.checked,
                        })
                      }
                    />
                  </Group>
                </Paper>

                <Paper p="sm" radius="md" withBorder>
                  <Group justify="space-between">
                    <Box>
                      <Text size="xs" fw={700}>
                        Mega 7-Digit Draws
                      </Text>
                      <Text size="11px" c="dimmed">
                        Weekly Jackpot module
                      </Text>
                    </Box>
                    <Switch
                      color="teal"
                      checked={genSettings.enableMegaDraws}
                      onChange={(e) =>
                        setGenSettings({
                          ...genSettings,
                          enableMegaDraws: e.currentTarget.checked,
                        })
                      }
                    />
                  </Group>
                </Paper>

                <Paper p="sm" radius="md" withBorder>
                  <Group justify="space-between">
                    <Box>
                      <Text size="xs" fw={700}>
                        Daily 3-Digit Draws
                      </Text>
                      <Text size="11px" c="dimmed">
                        Daily prize module
                      </Text>
                    </Box>
                    <Switch
                      color="teal"
                      checked={genSettings.enableDailyDraws}
                      onChange={(e) =>
                        setGenSettings({
                          ...genSettings,
                          enableDailyDraws: e.currentTarget.checked,
                        })
                      }
                    />
                  </Group>
                </Paper>

                <Paper p="sm" radius="md" withBorder>
                  <Group justify="space-between">
                    <Box>
                      <Text size="xs" fw={700}>
                        Hourly 3-Digit Draws
                      </Text>
                      <Text size="11px" c="dimmed">
                        Instant hourly game
                      </Text>
                    </Box>
                    <Switch
                      color="teal"
                      checked={genSettings.enableHourlyDraws}
                      onChange={(e) =>
                        setGenSettings({
                          ...genSettings,
                          enableHourlyDraws: e.currentTarget.checked,
                        })
                      }
                    />
                  </Group>
                </Paper>

                <Paper p="sm" radius="md" withBorder>
                  <Group justify="space-between">
                    <Box>
                      <Text size="xs" fw={700}>
                        Referral & Commission
                      </Text>
                      <Text size="11px" c="dimmed">
                        Multi-tier agent earnings
                      </Text>
                    </Box>
                    <Switch
                      color="teal"
                      checked={genSettings.enableReferralProgram}
                      onChange={(e) =>
                        setGenSettings({
                          ...genSettings,
                          enableReferralProgram: e.currentTarget.checked,
                        })
                      }
                    />
                  </Group>
                </Paper>
              </SimpleGrid>
            </Card>

            {/* Financial Risk Parameters */}
            <Card p="lg" radius="md" withBorder>
              <Title order={4} size="h5" fw={700} mb="xs">
                Financial Risk & Transfer Limits
              </Title>
              <Text size="xs" c="dimmed" mb="md">
                Configure platform limits for anti-fraud and compliance limits.
              </Text>

              <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} spacing="md">
                <NumberInput
                  label="Min Transfer (BDT)"
                  prefix="৳ "
                  value={genSettings.minTransferMinor / 100}
                  onChange={(val) =>
                    setGenSettings({
                      ...genSettings,
                      minTransferMinor: Math.round(Number(val) * 100),
                    })
                  }
                />

                <NumberInput
                  label="Max Transfer (BDT)"
                  prefix="৳ "
                  value={genSettings.maxTransferMinor / 100}
                  onChange={(val) =>
                    setGenSettings({
                      ...genSettings,
                      maxTransferMinor: Math.round(Number(val) * 100),
                    })
                  }
                />

                <NumberInput
                  label="Daily Transfer Cap (BDT)"
                  prefix="৳ "
                  value={genSettings.dailyTransferLimitMinor / 100}
                  onChange={(val) =>
                    setGenSettings({
                      ...genSettings,
                      dailyTransferLimitMinor: Math.round(Number(val) * 100),
                    })
                  }
                />

                <NumberInput
                  label="Max Tickets / Order"
                  value={genSettings.maxTicketsPerOrder}
                  onChange={(val) =>
                    setGenSettings({
                      ...genSettings,
                      maxTicketsPerOrder: Number(val),
                    })
                  }
                />
              </SimpleGrid>
            </Card>

            {/* Save Button for General Settings */}
            <Group justify="flex-end">
              <Button
                size="md"
                color="tradexGold"
                style={{ color: "#0A0F1D", fontWeight: 700 }}
                leftSection={<IconCheck size={18} />}
                loading={isSavingSettings}
                onClick={handleSaveGeneralSettings}
              >
                Save General Settings
              </Button>
            </Group>
          </Stack>
        </Tabs.Panel>
      </Tabs>

      {/* ========================================================================= */}
      {/* MODAL 1: Edit Payment Method Modal                                        */}
      {/* ========================================================================= */}
      <Modal
        opened={!!editingMethod}
        onClose={() => setEditingMethod(null)}
        title={
          <Group gap="xs">
            <ThemeIcon color="blue" variant="light" size={28}>
              <IconEdit size={16} />
            </ThemeIcon>
            <Title order={4} size="h5" fw={700}>
              Configure Gateway — {editingMethod?.name}
            </Title>
          </Group>
        }
        size="lg"
      >
        {editingMethod && (
          <Stack gap="md">
            <SimpleGrid cols={2} spacing="md">
              <TextInput
                label="Account Number / Merchant ID"
                required
                value={editAccountNumber}
                onChange={(e) => setEditAccountNumber(e.currentTarget.value)}
              />

              <TextInput
                label="Account Holder Name"
                required
                value={editAccountName}
                onChange={(e) => setEditAccountName(e.currentTarget.value)}
              />
            </SimpleGrid>

            <SimpleGrid cols={2} spacing="md">
              <NumberInput
                label="Min Deposit (BDT)"
                prefix="৳ "
                value={editMinDepositBDT}
                onChange={setEditMinDepositBDT}
              />
              <NumberInput
                label="Max Deposit (BDT)"
                prefix="৳ "
                value={editMaxDepositBDT}
                onChange={setEditMaxDepositBDT}
              />
            </SimpleGrid>

            <SimpleGrid cols={2} spacing="md">
              <NumberInput
                label="Min Withdrawal (BDT)"
                prefix="৳ "
                value={editMinWithdrawBDT}
                onChange={setEditMinWithdrawBDT}
              />
              <NumberInput
                label="Max Withdrawal (BDT)"
                prefix="৳ "
                value={editMaxWithdrawBDT}
                onChange={setEditMaxWithdrawBDT}
              />
            </SimpleGrid>

            <SimpleGrid cols={2} spacing="md">
              <NumberInput
                label="Deposit Fee (%)"
                suffix=" %"
                decimalScale={2}
                value={editDepositFeePct}
                onChange={setEditDepositFeePct}
              />
              <NumberInput
                label="Withdrawal Fee (%)"
                suffix=" %"
                decimalScale={2}
                value={editWithdrawFeePct}
                onChange={setEditWithdrawFeePct}
              />
            </SimpleGrid>

            <Textarea
              label="User Payment Instructions"
              description="Steps displayed in mobile app during payment"
              minRows={3}
              value={editInstructions}
              onChange={(e) => setEditInstructions(e.currentTarget.value)}
            />

            <Divider
              label="Status & Routing Availability"
              labelPosition="center"
            />

            <SimpleGrid cols={3} spacing="sm">
              <Switch
                label="Deposits Enabled"
                checked={editDepositEnabled}
                onChange={(e) => setEditDepositEnabled(e.currentTarget.checked)}
              />
              <Switch
                label="Withdrawals Enabled"
                checked={editWithdrawEnabled}
                onChange={(e) =>
                  setEditWithdrawEnabled(e.currentTarget.checked)
                }
              />
              <Select
                label="Status"
                data={[
                  { value: "ACTIVE", label: "ACTIVE" },
                  { value: "INACTIVE", label: "INACTIVE" },
                ]}
                value={editStatus}
                onChange={(val) =>
                  setEditStatus((val as "ACTIVE" | "INACTIVE") || "ACTIVE")
                }
              />
            </SimpleGrid>

            <Group justify="flex-end" mt="md">
              <Button variant="default" onClick={() => setEditingMethod(null)}>
                Cancel
              </Button>
              <Button color="blue" onClick={handleSaveMethod}>
                Save Gateway Changes
              </Button>
            </Group>
          </Stack>
        )}
      </Modal>

      {/* ========================================================================= */}
      {/* MODAL 2: Add New Payment Method Modal                                     */}
      {/* ========================================================================= */}
      <Modal
        opened={addModalOpen}
        onClose={() => setAddModalOpen(false)}
        title={
          <Group gap="xs">
            <ThemeIcon color="tradexGold" variant="light" size={28}>
              <IconPlus size={16} />
            </ThemeIcon>
            <Title order={4} size="h5" fw={700}>
              Register New Payment Gateway
            </Title>
          </Group>
        }
        size="md"
      >
        <Stack gap="md">
          <Select
            label="Gateway Provider Code"
            required
            data={[
              { value: "BKASH", label: "bKash (MFS)" },
              { value: "NAGAD", label: "Nagad (MFS)" },
              { value: "ROCKET", label: "Rocket (DBBL MFS)" },
              { value: "BANK", label: "Commercial Bank Transfer" },
            ]}
            value={newCode}
            onChange={(val) => {
              const code =
                (val as "BKASH" | "NAGAD" | "ROCKET" | "BANK") || "BKASH";
              setNewCode(code);
              setNewType(code === "BANK" ? "BANK_TRANSFER" : "MOBILE_BANKING");
            }}
          />

          <TextInput
            label="Method Display Name"
            placeholder="e.g. bKash Sub-Merchant Account #2"
            required
            value={newName}
            onChange={(e) => setNewName(e.currentTarget.value)}
          />

          <TextInput
            label="Account / Merchant Number"
            placeholder="e.g. 01712-000000 or Account No"
            required
            value={newAccountNo}
            onChange={(e) => setNewAccountNo(e.currentTarget.value)}
          />

          <TextInput
            label="Account Holder Name"
            value={newAccountHolder}
            onChange={(e) => setNewAccountHolder(e.currentTarget.value)}
          />

          <Textarea
            label="Payment Instructions"
            placeholder="Dial *247# or make payment to merchant..."
            value={newInstructionsText}
            onChange={(e) => setNewInstructionsText(e.currentTarget.value)}
          />

          <Group justify="flex-end" mt="md">
            <Button variant="default" onClick={() => setAddModalOpen(false)}>
              Cancel
            </Button>
            <Button
              color="tradexGold"
              style={{ color: "#0A0F1D", fontWeight: 700 }}
              onClick={handleCreatePaymentMethod}
            >
              Add Method
            </Button>
          </Group>
        </Stack>
      </Modal>
    </Stack>
  );
}
