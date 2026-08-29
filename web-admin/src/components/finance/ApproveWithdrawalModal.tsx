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
import {
  IconAlertTriangle,
  IconCashBanknote,
  IconCheck,
} from "@tabler/icons-react";
import { useState } from "react";
import { useApproveWithdrawal } from "@/lib/api";
import { useAdminStore } from "@/lib/store";
import type { WithdrawalItem } from "@/types";

interface ApproveWithdrawalModalProps {
  opened: boolean;
  onClose: () => void;
  withdrawal: WithdrawalItem | null;
}

export function ApproveWithdrawalModal({
  opened,
  onClose,
  withdrawal,
}: ApproveWithdrawalModalProps) {
  const approveWithdrawalMutation = useApproveWithdrawal();
  const approveWithdrawal = useAdminStore((s) => s.approveWithdrawal);
  const [transactionRef, setTransactionRef] = useState("");
  const [note, setNote] = useState("");

  if (!withdrawal) return null;

  const loading = approveWithdrawalMutation.isPending;

  const handleApprove = async () => {
    const payoutRef =
      transactionRef.trim() || `TXN-PAYOUT-${Date.now().toString().slice(-6)}`;
    try {
      await approveWithdrawalMutation.mutateAsync({
        withdrawalId: withdrawal.id,
        transactionReference: payoutRef,
        note: note.trim() || undefined,
      });

      approveWithdrawal(withdrawal.id, payoutRef, note);
      notifications.show({
        title: "Withdrawal Payout Approved",
        message: `Approved payout of ${withdrawal.formattedNetAmount} to ${withdrawal.userFullName}.`,
        color: "teal",
        icon: <IconCheck size={18} />,
      });
      setTransactionRef("");
      setNote("");
      onClose();
    } catch (err: unknown) {
      const errorMsg =
        err instanceof Error ? err.message : "Failed to approve withdrawal";
      notifications.show({
        title: "Approval Failed",
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
          <IconCashBanknote size={20} color="#10B981" />
          <Text fw={800} size="md">
            Process & Approve Withdrawal Payout
          </Text>
        </Group>
      }
      centered
      size="md"
    >
      <Stack gap="md">
        <Alert
          icon={<IconCashBanknote size={18} />}
          title="Payout Disbursement Confirmation"
          color="teal"
          variant="light"
        >
          Confirm disbursement of funds to the user&apos;s external account. The
          locked balance will be permanently cleared and debited from the
          ledger.
        </Alert>

        <Paper p="md" radius="md" withBorder bg="var(--mantine-color-default)">
          <Stack gap="xs">
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                User:
              </Text>
              <Text size="sm" fw={700}>
                {withdrawal.userFullName} (@{withdrawal.username})
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                Destination Method:
              </Text>
              <Text size="sm" fw={600}>
                {withdrawal.paymentMethod}
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                Receiver Account / Number:
              </Text>
              <Text size="sm" ff="monospace" fw={700} c="cyan.4">
                {withdrawal.receiverAccount}
              </Text>
            </Group>
            <Divider my={4} />
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                Requested Gross Amount:
              </Text>
              <Text size="sm" className="font-tabular">
                {withdrawal.formattedAmount}
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                Platform Fee (1%):
              </Text>
              <Text size="xs" c="dimmed" className="font-tabular">
                {withdrawal.formattedFee}
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="sm" fw={700}>
                Net Payout Amount:
              </Text>
              <Text size="lg" fw={900} c="emerald.4" className="font-tabular">
                {withdrawal.formattedNetAmount}
              </Text>
            </Group>
          </Stack>
        </Paper>

        <TextInput
          label="Payment Provider Transaction Reference"
          placeholder="e.g. BKASH-DISB-998124 or Bank UTR"
          value={transactionRef}
          onChange={(e) => setTransactionRef(e.target.value)}
        />

        <TextInput
          label="Administrative Note (Optional)"
          placeholder="e.g. Sent via corporate merchant batch #14"
          value={note}
          onChange={(e) => setNote(e.target.value)}
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
            Confirm & Complete Payout
          </Button>
        </Group>
      </Stack>
    </Modal>
  );
}
