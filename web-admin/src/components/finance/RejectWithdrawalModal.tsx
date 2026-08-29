"use client";

import {
  Alert,
  Button,
  Divider,
  Group,
  Modal,
  Paper,
  Select,
  Stack,
  Text,
  Textarea,
} from "@mantine/core";
import { notifications } from "@mantine/notifications";
import { IconAlertTriangle, IconRefresh, IconX } from "@tabler/icons-react";
import { useState } from "react";
import { useRejectWithdrawal } from "@/lib/api";
import { useAdminStore } from "@/lib/store";
import type { WithdrawalItem } from "@/types";

interface RejectWithdrawalModalProps {
  opened: boolean;
  onClose: () => void;
  withdrawal: WithdrawalItem | null;
}

const WITHDRAWAL_REJECT_REASONS = [
  "Incorrect or Inactive Receiver Account Number",
  "KYC Verification Incomplete / Name Mismatch",
  "Suspicious Activity / Multi-accounting Flag",
  "Duplicate Withdrawal Request",
  "Daily Payout Limit Exceeded",
  "Other Operational Reason",
];

export function RejectWithdrawalModal({
  opened,
  onClose,
  withdrawal,
}: RejectWithdrawalModalProps) {
  const rejectWithdrawalMutation = useRejectWithdrawal();
  const rejectWithdrawal = useAdminStore((s) => s.rejectWithdrawal);
  const [selectedReason, setSelectedReason] = useState<string | null>(
    WITHDRAWAL_REJECT_REASONS[0],
  );
  const [customDetails, setCustomDetails] = useState("");

  if (!withdrawal) return null;

  const loading = rejectWithdrawalMutation.isPending;

  const handleReject = async () => {
    if (!selectedReason) return;
    const finalReason =
      selectedReason === "Other Operational Reason"
        ? customDetails || "Withdrawal request rejected by admin"
        : customDetails
          ? `${selectedReason}: ${customDetails}`
          : selectedReason;

    try {
      await rejectWithdrawalMutation.mutateAsync({
        withdrawalId: withdrawal.id,
        reason: finalReason,
      });

      rejectWithdrawal(withdrawal.id, finalReason);
      notifications.show({
        title: "Withdrawal Rejected & Refunded",
        message: `${withdrawal.formattedAmount} unlocked back to user @${withdrawal.username}'s available balance.`,
        color: "orange",
        icon: <IconRefresh size={18} />,
      });
      setCustomDetails("");
      onClose();
    } catch (err: unknown) {
      const errorMsg =
        err instanceof Error ? err.message : "Failed to reject withdrawal";
      notifications.show({
        title: "Rejection Failed",
        message: errorMsg,
        color: "red",
        icon: <IconAlertTriangle size={18} />,
      });
    }
  };

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title={
        <Group gap="xs">
          <IconX size={20} color="#EF4444" />
          <Text fw={800} size="md">
            Reject Withdrawal Request
          </Text>
        </Group>
      }
      centered
      size="md"
    >
      <Stack gap="md">
        <Alert
          icon={<IconAlertTriangle size={18} />}
          title="Automatic Balance Release"
          color="orange"
          variant="light"
        >
          Rejecting this withdrawal will immediately return the locked funds (
          <strong>{withdrawal.formattedAmount}</strong>) back to the user&apos;s
          available wallet balance.
        </Alert>

        <Paper p="md" radius="md" withBorder bg="var(--mantine-color-default)">
          <Stack gap="xs">
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                User Account:
              </Text>
              <Text size="sm" fw={700}>
                {withdrawal.userFullName} (@{withdrawal.username})
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                Destination Account:
              </Text>
              <Text size="sm" ff="monospace" fw={600}>
                {withdrawal.paymentMethod} • {withdrawal.receiverAccount}
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                Gross Amount to Refund:
              </Text>
              <Text size="sm" fw={900} c="orange.4" className="font-tabular">
                {withdrawal.formattedAmount}
              </Text>
            </Group>
          </Stack>
        </Paper>

        <Select
          label="Rejection Reason"
          description="Reason displayed to the customer and recorded in audit logs"
          data={WITHDRAWAL_REJECT_REASONS}
          value={selectedReason}
          onChange={setSelectedReason}
          required
        />

        <Textarea
          label="Internal Investigation Notes (Optional)"
          placeholder="Additional notes on why this withdrawal was declined..."
          rows={3}
          value={customDetails}
          onChange={(e) => setCustomDetails(e.target.value)}
        />

        <Divider />

        <Group justify="flex-end" gap="sm">
          <Button variant="default" onClick={onClose} disabled={loading}>
            Cancel
          </Button>
          <Button
            color="red"
            onClick={handleReject}
            loading={loading}
            leftSection={<IconX size={16} />}
          >
            Reject & Refund Balance
          </Button>
        </Group>
      </Stack>
    </Modal>
  );
}
