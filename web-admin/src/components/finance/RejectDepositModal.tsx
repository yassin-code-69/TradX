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
import { IconAlertTriangle, IconX } from "@tabler/icons-react";
import { useState } from "react";
import { useRejectDeposit } from "@/lib/api";
import { useAdminStore } from "@/lib/store";
import type { DepositItem } from "@/types";

interface RejectDepositModalProps {
  opened: boolean;
  onClose: () => void;
  deposit: DepositItem | null;
}

const REJECT_REASONS = [
  "Invalid Transaction ID",
  "Payment Not Found in Merchant Statement",
  "Incorrect Amount Transferred",
  "Duplicate Request / TrxID Already Claimed",
  "Unrecognized Sender Account",
  "Suspicious / Disputed Transaction",
  "Other Reason",
];

export function RejectDepositModal({
  opened,
  onClose,
  deposit,
}: RejectDepositModalProps) {
  const rejectDepositMutation = useRejectDeposit();
  const { rejectDeposit } = useAdminStore();
  const [selectedReason, setSelectedReason] = useState<string | null>(
    REJECT_REASONS[0],
  );
  const [customDetails, setCustomDetails] = useState("");

  if (!deposit) return null;

  const loading = rejectDepositMutation.isPending;

  const handleReject = async () => {
    if (!selectedReason) return;
    const finalReason =
      selectedReason === "Other Reason"
        ? customDetails || "Deposit request rejected by administrator"
        : customDetails
          ? `${selectedReason}: ${customDetails}`
          : selectedReason;

    try {
      await rejectDepositMutation.mutateAsync({
        depositId: deposit.id,
        reason: finalReason,
      });

      rejectDeposit(deposit.id, finalReason);
      notifications.show({
        title: "Deposit Rejected",
        message: `Deposit request #${deposit.id} rejected.`,
        color: "red",
        icon: <IconX size={18} />,
      });
      setCustomDetails("");
      onClose();
    } catch (err: unknown) {
      const errorMsg =
        err instanceof Error ? err.message : "Failed to reject deposit";
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
          <IconX size={20} color="#fa5252" />
          <Text fw={700} size="md">
            Reject Deposit Request
          </Text>
        </Group>
      }
      centered
      size="md"
    >
      <Stack gap="md">
        <Alert
          icon={<IconAlertTriangle size={18} />}
          title="Action Confirmation"
          color="red"
          variant="light"
        >
          Rejecting this deposit will notify the user and void request{" "}
          <strong>#{deposit.id}</strong>. No wallet balance will be credited.
        </Alert>

        <Paper p="md" radius="md" withBorder bg="dark.8">
          <Stack gap="xs">
            <Group justify="space-between">
              <Text size="xs" c="dimmed">
                User:
              </Text>
              <Text size="sm" fw={600}>
                {deposit.userFullName} (@{deposit.username})
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed">
                Requested Amount:
              </Text>
              <Text size="sm" fw={700}>
                {deposit.formattedAmount}
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed">
                Provider / TrxID:
              </Text>
              <Text size="sm" ff="monospace">
                {deposit.paymentMethod} • {deposit.providerTransactionId}
              </Text>
            </Group>
          </Stack>
        </Paper>

        <Select
          label="Rejection Reason"
          description="Select standard reason template for audit record"
          data={REJECT_REASONS}
          value={selectedReason}
          onChange={setSelectedReason}
          required
        />

        <Textarea
          label="Additional Details (Optional)"
          placeholder="Provide further clarification for the audit log and user notification..."
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
            Reject Deposit
          </Button>
        </Group>
      </Stack>
    </Modal>
  );
}
