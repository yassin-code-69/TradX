"use client";

import {
  ActionIcon,
  Badge,
  Button,
  CopyButton,
  Divider,
  Group,
  Image,
  Modal,
  Paper,
  Stack,
  Text,
  Tooltip,
} from "@mantine/core";
import {
  IconCheck,
  IconCopy,
  IconExternalLink,
  IconReceipt2,
} from "@tabler/icons-react";
import { formatDateTime, getStatusColor } from "@/lib/formatters";
import type { DepositItem } from "@/types";

interface DepositReceiptModalProps {
  opened: boolean;
  onClose: () => void;
  deposit: DepositItem | null;
  onApprove?: (deposit: DepositItem) => void;
  onReject?: (deposit: DepositItem) => void;
}

export function DepositReceiptModal({
  opened,
  onClose,
  deposit,
  onApprove,
  onReject,
}: DepositReceiptModalProps) {
  if (!deposit) return null;

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title={
        <Group gap="xs">
          <IconReceipt2 size={20} color="#F59E0B" />
          <Text fw={800} size="md">
            Deposit Receipt & Proof Verification
          </Text>
        </Group>
      }
      size="lg"
      centered
    >
      <Stack gap="md">
        {/* Payment Summary Header */}
        <Paper p="md" radius="lg" withBorder>
          <Group justify="space-between" align="flex-start">
            <Stack gap={2}>
              <Text size="xs" c="dimmed" tt="uppercase" fw={700}>
                Deposit Amount
              </Text>
              <Text size="xl" fw={900} c="emerald.4" className="font-tabular">
                {deposit.formattedAmount}
              </Text>
              <Text size="xs" c="dimmed">
                Method: <strong>{deposit.paymentMethod}</strong>
              </Text>
            </Stack>
            <Badge
              color={getStatusColor(deposit.status)}
              size="lg"
              variant="filled"
            >
              {deposit.status}
            </Badge>
          </Group>
        </Paper>

        {/* Transaction Metadata Grid */}
        <Paper p="md" radius="lg" withBorder>
          <Stack gap="xs">
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                User / Sender:
              </Text>
              <Text size="sm" fw={700}>
                {deposit.userFullName} (@{deposit.username})
              </Text>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                Sender Account / Number:
              </Text>
              <Group gap={4}>
                <Text size="sm" ff="monospace" fw={700}>
                  {deposit.senderAccount}
                </Text>
                <CopyButton value={deposit.senderAccount} timeout={2000}>
                  {({ copied, copy }) => (
                    <Tooltip label={copied ? "Copied" : "Copy"} withArrow>
                      <ActionIcon
                        color={copied ? "teal" : "gray"}
                        variant="subtle"
                        size="xs"
                        onClick={copy}
                      >
                        {copied ? (
                          <IconCheck size={14} />
                        ) : (
                          <IconCopy size={14} />
                        )}
                      </ActionIcon>
                    </Tooltip>
                  )}
                </CopyButton>
              </Group>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                Provider Transaction ID (TrxID):
              </Text>
              <Group gap={4}>
                <Badge
                  variant="light"
                  color="tradexGold"
                  ff="monospace"
                  size="md"
                >
                  {deposit.providerTransactionId}
                </Badge>
                <CopyButton
                  value={deposit.providerTransactionId}
                  timeout={2000}
                >
                  {({ copied, copy }) => (
                    <Tooltip label={copied ? "Copied" : "Copy"} withArrow>
                      <ActionIcon
                        color={copied ? "teal" : "gray"}
                        variant="subtle"
                        size="xs"
                        onClick={copy}
                      >
                        {copied ? (
                          <IconCheck size={14} />
                        ) : (
                          <IconCopy size={14} />
                        )}
                      </ActionIcon>
                    </Tooltip>
                  )}
                </CopyButton>
              </Group>
            </Group>
            <Group justify="space-between">
              <Text size="xs" c="dimmed" fw={600}>
                Submitted At:
              </Text>
              <Text size="xs" c="dimmed" className="font-tabular">
                {formatDateTime(deposit.submittedAt)}
              </Text>
            </Group>
            {deposit.reviewedBy && (
              <Group justify="space-between">
                <Text size="xs" c="dimmed" fw={600}>
                  Reviewed By:
                </Text>
                <Text size="xs" className="font-tabular">
                  {deposit.reviewedBy} at{" "}
                  {formatDateTime(deposit.reviewedAt || "")}
                </Text>
              </Group>
            )}
            {deposit.rejectReason && (
              <Paper p="xs" radius="sm" mt="xs" withBorder>
                <Text size="xs" c="red.4" fw={700}>
                  Rejection Reason: {deposit.rejectReason}
                </Text>
              </Paper>
            )}
          </Stack>
        </Paper>

        {/* Screenshot / Payment Proof */}
        <Stack gap="xs">
          <Group justify="space-between">
            <Text size="xs" fw={700} c="dimmed" tt="uppercase">
              Customer Payment Proof
            </Text>
            {deposit.proofImageUrl && (
              <Button
                component="a"
                href={deposit.proofImageUrl}
                target="_blank"
                variant="subtle"
                size="xs"
                rightSection={<IconExternalLink size={14} />}
              >
                Open Fullscreen
              </Button>
            )}
          </Group>

          {deposit.proofImageUrl ? (
            <Paper withBorder radius="md" style={{ overflow: "hidden" }} p="xs">
              <Image
                src={deposit.proofImageUrl}
                alt="Deposit proof screenshot"
                radius="md"
                h={260}
                fit="contain"
                fallbackSrc="https://placehold.co/600x300?text=Payment+Screenshot"
              />
            </Paper>
          ) : (
            <Paper p="lg" withBorder radius="md" ta="center">
              <Text size="sm" c="dimmed">
                No screenshot attachment uploaded. Verified via TrxID and SMS
                webhook.
              </Text>
            </Paper>
          )}
        </Stack>

        <Divider />

        {/* Action Controls */}
        <Group justify="space-between">
          <Button variant="default" onClick={onClose}>
            Close
          </Button>

          {deposit.status === "PENDING" && (
            <Group gap="sm">
              {onReject && (
                <Button
                  color="red"
                  variant="light"
                  onClick={() => {
                    onClose();
                    onReject(deposit);
                  }}
                >
                  Reject Deposit
                </Button>
              )}
              {onApprove && (
                <Button
                  color="teal"
                  onClick={() => {
                    onClose();
                    onApprove(deposit);
                  }}
                >
                  Approve & Credit Wallet
                </Button>
              )}
            </Group>
          )}
        </Group>
      </Stack>
    </Modal>
  );
}
