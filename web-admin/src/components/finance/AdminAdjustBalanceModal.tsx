"use client";

import {
  Alert,
  Badge,
  Button,
  Divider,
  Group,
  Modal,
  NumberInput,
  Paper,
  SegmentedControl,
  Select,
  Stack,
  Text,
  Textarea,
} from "@mantine/core";
import { notifications } from "@mantine/notifications";
import {
  IconAlertTriangle,
  IconArrowLeft,
  IconArrowRight,
  IconCheck,
  IconScale,
  IconShieldCheck,
} from "@tabler/icons-react";
import { useEffect, useState } from "react";
import { useAdminAdjustBalance } from "@/lib/api";
import { bdtToMinor, formatBDT } from "@/lib/formatters";
import { useAdminStore } from "@/lib/store";

interface AdminAdjustBalanceModalProps {
  opened: boolean;
  onClose: () => void;
  preselectedUserId?: string | null;
}

const ADJUSTMENT_REASONS = [
  "Support ticket resolution / Correction",
  "Promotional agent incentive / Bonus",
  "Disputed draw refund compensation",
  "Clawback of duplicate deposit credit",
  "Internal accounting reconciliation",
  "Other administrative adjustment",
];

export function AdminAdjustBalanceModal({
  opened,
  onClose,
  preselectedUserId,
}: AdminAdjustBalanceModalProps) {
  const adjustBalanceMutation = useAdminAdjustBalance();
  const { users, adjustUserBalance } = useAdminStore();
  const [selectedUserId, setSelectedUserId] = useState<string | null>(
    preselectedUserId || null,
  );
  const [adjustmentType, setAdjustmentType] = useState<"CREDIT" | "DEBIT">(
    "CREDIT",
  );
  const [amountBdt, setAmountBdt] = useState<number | string>(100);
  const [reason, setReason] = useState<string | null>(ADJUSTMENT_REASONS[0]);
  const [customNote, setCustomNote] = useState("");
  const [step, setStep] = useState<"FORM" | "CONFIRM">("FORM");
  const loading = adjustBalanceMutation.isPending;

  useEffect(() => {
    if (preselectedUserId) {
      setSelectedUserId(preselectedUserId);
    } else if (!selectedUserId && users.length > 0) {
      setSelectedUserId(users[0].id);
    }
  }, [preselectedUserId, users, selectedUserId]);

  const targetUser = users.find((u) => u.id === selectedUserId) || users[0];
  const numAmount =
    typeof amountBdt === "number" ? amountBdt : parseFloat(amountBdt) || 0;
  const adjustmentMinor = bdtToMinor(numAmount);

  const currentAvailableMinor = targetUser
    ? targetUser.availableBalanceMinor
    : 0;
  const projectedAvailableMinor =
    adjustmentType === "CREDIT"
      ? currentAvailableMinor + adjustmentMinor
      : Math.max(0, currentAvailableMinor - adjustmentMinor);

  const handleProceedToConfirm = () => {
    if (numAmount <= 0) {
      notifications.show({
        title: "Invalid Amount",
        message: "Please specify an adjustment amount greater than zero.",
        color: "red",
      });
      return;
    }
    if (adjustmentType === "DEBIT" && adjustmentMinor > currentAvailableMinor) {
      notifications.show({
        title: "Insufficient Balance",
        message: "Debit amount exceeds available user wallet balance.",
        color: "red",
      });
      return;
    }
    setStep("CONFIRM");
  };

  const handleFinalSubmit = async () => {
    if (!targetUser) return;
    const reasonText = reason || "Admin Adjustment";
    try {
      await adjustBalanceMutation.mutateAsync({
        userId: targetUser.id,
        type: adjustmentType,
        amountMinor: adjustmentMinor,
        reason: reasonText,
        note: customNote.trim() || undefined,
      });

      adjustUserBalance(
        targetUser.id,
        adjustmentType,
        adjustmentMinor,
        reasonText,
        customNote,
      );

      notifications.show({
        title: "Balance Adjusted",
        message: `Successfully ${adjustmentType === "CREDIT" ? "credited" : "debited"} ${formatBDT(adjustmentMinor)} for ${targetUser.fullName}.`,
        color: "teal",
        icon: <IconCheck size={18} />,
      });
      setStep("FORM");
      setAmountBdt(100);
      setCustomNote("");
      onClose();
    } catch (err: unknown) {
      const errorMsg =
        err instanceof Error ? err.message : "Failed to adjust balance";
      notifications.show({
        title: "Adjustment Failed",
        message: errorMsg,
        color: "red",
        icon: <IconAlertTriangle size={18} />,
      });
    }
  };

  const handleClose = () => {
    setStep("FORM");
    onClose();
  };

  const userSelectData = users.map((u) => ({
    value: u.id,
    label: `${u.fullName} (@${u.username}) — Avail: ${formatBDT(u.availableBalanceMinor)}`,
  }));

  return (
    <Modal
      opened={opened}
      onClose={handleClose}
      title={
        <Group gap="xs">
          <IconScale size={20} color="#fad045" />
          <Text fw={700} size="md">
            Administrative Balance Adjustment
          </Text>
        </Group>
      }
      centered
      size="lg"
    >
      <Stack gap="md">
        {step === "FORM" ? (
          <>
            <Alert
              icon={<IconAlertTriangle size={18} />}
              title="Financial Audit Notice"
              color="yellow"
              variant="light"
            >
              Manual balance adjustments bypass payment gateways and directly
              affect ledger liability. Every adjustment is immutably logged with
              your admin identity.
            </Alert>

            {/* User Selection */}
            <Select
              label="Select Target User"
              placeholder="Search user by name or username"
              data={userSelectData}
              value={selectedUserId}
              onChange={setSelectedUserId}
              searchable
              disabled={!!preselectedUserId}
              required
            />

            {/* Adjustment Type Selector */}
            <Stack gap={4}>
              <Text size="sm" fw={500}>
                Adjustment Type
              </Text>
              <SegmentedControl
                value={adjustmentType}
                onChange={(val) => setAdjustmentType(val as "CREDIT" | "DEBIT")}
                fullWidth
                data={[
                  {
                    label: (
                      <Group gap="xs" justify="center">
                        <Badge color="teal" size="xs">
                          CREDIT
                        </Badge>
                        <Text size="sm">Add Funds to User</Text>
                      </Group>
                    ),
                    value: "CREDIT",
                  },
                  {
                    label: (
                      <Group gap="xs" justify="center">
                        <Badge color="red" size="xs">
                          DEBIT
                        </Badge>
                        <Text size="sm">Deduct Funds from User</Text>
                      </Group>
                    ),
                    value: "DEBIT",
                  },
                ]}
              />
            </Stack>

            {/* Amount Input */}
            <NumberInput
              label="Adjustment Amount (BDT)"
              description="Enter amount in standard Taka (decimals supported)"
              prefix="৳ "
              min={1}
              decimalScale={2}
              fixedDecimalScale
              value={amountBdt}
              onChange={(val) => setAmountBdt(val || 0)}
              required
            />

            {/* Realtime Projected Balance Display */}
            {targetUser && (
              <Paper p="md" radius="md" withBorder bg="dark.8">
                <Group justify="space-between" align="center">
                  <Stack gap={2}>
                    <Text size="xs" c="dimmed">
                      Current Available
                    </Text>
                    <Text size="md" fw={600}>
                      {formatBDT(currentAvailableMinor)}
                    </Text>
                  </Stack>
                  <IconArrowRight size={20} color="#94a3b8" />
                  <Stack gap={2}>
                    <Text size="xs" c="dimmed">
                      Adjustment
                    </Text>
                    <Text
                      size="md"
                      fw={700}
                      c={adjustmentType === "CREDIT" ? "emerald.4" : "red.4"}
                    >
                      {adjustmentType === "CREDIT" ? "+" : "-"}{" "}
                      {formatBDT(adjustmentMinor)}
                    </Text>
                  </Stack>
                  <IconArrowRight size={20} color="#94a3b8" />
                  <Stack gap={2} ta="right">
                    <Text size="xs" c="dimmed">
                      Projected Balance
                    </Text>
                    <Text size="md" fw={800} c="cyan.4">
                      {formatBDT(projectedAvailableMinor)}
                    </Text>
                  </Stack>
                </Group>
              </Paper>
            )}

            {/* Reason selection */}
            <Select
              label="Mandatory Reason"
              description="Category classification for double-entry bookkeeping"
              data={ADJUSTMENT_REASONS}
              value={reason}
              onChange={setReason}
              required
            />

            {/* Internal Note */}
            <Textarea
              label="Internal Audit Note (Optional)"
              placeholder="Provide case number, ticket ID, or justification..."
              rows={2}
              value={customNote}
              onChange={(e) => setCustomNote(e.target.value)}
            />

            <Divider />

            <Group justify="flex-end" gap="sm">
              <Button variant="default" onClick={handleClose}>
                Cancel
              </Button>
              <Button
                color="yellow"
                onClick={handleProceedToConfirm}
                rightSection={<IconArrowRight size={16} />}
              >
                Review Adjustment
              </Button>
            </Group>
          </>
        ) : (
          /* Step 2: Confirmation Warning */
          <>
            <Alert
              icon={<IconShieldCheck size={20} />}
              title="Confirm Authoritative Ledger Mutation"
              color={adjustmentType === "CREDIT" ? "teal" : "red"}
              variant="filled"
            >
              You are about to execute a permanent {adjustmentType} of{" "}
              <strong>{formatBDT(adjustmentMinor)}</strong>. This will modify
              the user&apos;s authoritative ledger balance immediately.
            </Alert>

            <Paper p="lg" radius="md" withBorder bg="dark.8">
              <Stack gap="sm">
                <Group justify="space-between">
                  <Text size="sm" c="dimmed">
                    User Account:
                  </Text>
                  <Text size="sm" fw={700}>
                    {targetUser?.fullName} (@{targetUser?.username})
                  </Text>
                </Group>
                <Group justify="space-between">
                  <Text size="sm" c="dimmed">
                    Adjustment Type:
                  </Text>
                  <Badge
                    color={adjustmentType === "CREDIT" ? "teal" : "red"}
                    size="lg"
                  >
                    {adjustmentType}
                  </Badge>
                </Group>
                <Group justify="space-between">
                  <Text size="sm" c="dimmed">
                    Current Balance:
                  </Text>
                  <Text size="sm">{formatBDT(currentAvailableMinor)}</Text>
                </Group>
                <Group justify="space-between">
                  <Text size="sm" c="dimmed">
                    New Projected Balance:
                  </Text>
                  <Text
                    size="md"
                    fw={800}
                    c={adjustmentType === "CREDIT" ? "emerald.4" : "yellow.4"}
                  >
                    {formatBDT(projectedAvailableMinor)}
                  </Text>
                </Group>
                <Group justify="space-between">
                  <Text size="sm" c="dimmed">
                    Stated Reason:
                  </Text>
                  <Text size="sm" fw={600}>
                    {reason}
                  </Text>
                </Group>
                {customNote && (
                  <Group justify="space-between">
                    <Text size="sm" c="dimmed">
                      Notes:
                    </Text>
                    <Text size="xs">{customNote}</Text>
                  </Group>
                )}
                <Divider my={4} />
                <Text size="xs" c="dimmed">
                  Authorized by: <strong>Admin Shahin Ahmed</strong> • IP:
                  10.0.4.18 • Immutable Ledger UUID created upon submit.
                </Text>
              </Stack>
            </Paper>

            <Group justify="space-between">
              <Button
                variant="default"
                onClick={() => setStep("FORM")}
                leftSection={<IconArrowLeft size={16} />}
                disabled={loading}
              >
                Back to Edit
              </Button>
              <Button
                color={adjustmentType === "CREDIT" ? "teal" : "red"}
                onClick={handleFinalSubmit}
                loading={loading}
                leftSection={<IconCheck size={16} />}
              >
                Confirm & Apply Adjustment
              </Button>
            </Group>
          </>
        )}
      </Stack>
    </Modal>
  );
}
