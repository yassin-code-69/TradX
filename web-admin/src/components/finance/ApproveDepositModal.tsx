"use client";

import {
  Alert,
  Button,
  Divider,
  Group,
  Modal,
  Paper,
  Stack,
  Text,
  TextInput,
} from "@mantine/core";
import { notifications } from "@mantine/notifications";
import { IconAlertCircle, IconCheck } from "@tabler/icons-react";
import { useState } from "react";
import { useApproveDeposit } from "@/lib/api";
import { useAdminStore } from "@/lib/store";
import type { DepositItem } from "@/types";

interface ApproveDepositModalProps {
  opened: boolean;
  onClose: () => void;
  deposit: DepositItem | null;
}

export function ApproveDepositModal({
  opened,
  onClose,
  deposit,
}: ApproveDepositModalProps) {
  const approveDepositMutation = useApproveDeposit();
  const { approveDeposit } = useAdminStore();
  const [adminNote, setAdminNote] = useState("");

  if (!deposit) return null;

  const loading = approveDepositMutation.isPending;

  const handleApprove = async () => {
    try {
      await approveDepositMutation.mutateAsync({
        depositId: deposit.id,
        note: adminNote.trim() || undefined,
      });

      approveDeposit(deposit.id, adminNote);
      notifications.show({
        title: "Deposit Approved",
        message: `Credited ${deposit.formattedAmount} to @${deposit.username}'s wallet.`,
        color: "teal",
        icon: <IconCheck size={18} />,
      });
      setAdminNote("");
      onClose();
    } catch (err: unknown) {
      const errorMsg =
        err instanceof Error ? err.message : "Failed to approve deposit";
      notifications.show({
        title: "Approval Failed",
        message: errorMsg,
        color: "red",
        icon: <IconAlertCircle size={18} />,
      });
    }
  };

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title={
        <Group gap="xs">
          <IconCheck size={20} color="#20c997" />
          <Text fw={700} size="md">
            Approve Manual Deposit
          </Text>
        </Group>
      }
      centered
      size="md"
    >
      <Stack gap="md">
        <Alert
          icon={<IconAlertCircle size={18} />}
          title="Authoritative Wallet Credit"
          color="teal"
          variant="light"
        >
          Approving this deposit will atomically credit{" "}
          <strong>{deposit.formattedAmount}</strong> to the user&apos;s
          available wallet balance and record a ledger transaction.
        </Alert>

        <Paper p="md" radius="md" withBorder bg="dark.8">
          <Stack gap="xs">
            <Group justify="space-between">
              <Text size="xs" c="dimmed">
                User Account:
              </Text>
              <Text size="sm" fw={600}>
                {deposit.userFullName} (@{deposit.username})
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed">
                Deposit Amount:
              </Text>
              <Text size="md" fw={700} c="emerald.4">
                {deposit.formattedAmount}
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed">
                Payment Method:
              </Text>
              <Text size="sm" fw={600}>
                {deposit.paymentMethod}
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed">
                Sender Account:
              </Text>
              <Text size="sm" ff="monospace">
                {deposit.senderAccount}
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed">
                Transaction ID (TrxID):
              </Text>
              <Text size="sm" ff="monospace" fw={600}>
                {deposit.providerTransactionId}
              </Text>
            </Group>
          </Stack>
        </Paper>

        <TextInput
          label="Internal Verification Note (Optional)"
          placeholder="e.g. Verified with bKash Merchant Portal"
          value={adminNote}
          onChange={(e) => setAdminNote(e.target.value)}
        />

        <Divider />

        <Group justify="flex-end" gap="sm">
          <Button variant="default" onClick={onClose} disabled={loading}>
            Cancel
          </Button>
          <Button
            color="teal"
            onClick={handleApprove}
            loading={loading}
            leftSection={<IconCheck size={16} />}
          >
            Confirm & Credit Wallet
          </Button>
        </Group>
      </Stack>
    </Modal>
  );
}
