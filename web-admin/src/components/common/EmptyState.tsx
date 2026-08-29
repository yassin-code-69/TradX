"use client";

import {
  Box,
  Button,
  Paper,
  Stack,
  Text,
  ThemeIcon,
  Title,
} from "@mantine/core";
import { IconDatabaseOff } from "@tabler/icons-react";
import type React from "react";

interface EmptyStateProps {
  icon?: React.ComponentType<{
    size?: number | string;
    stroke?: number;
    color?: string;
  }>;
  title?: string;
  description?: string;
  actionLabel?: string;
  onAction?: () => void;
  actionIcon?: React.ReactNode;
}

export function EmptyState({
  icon: Icon = IconDatabaseOff,
  title = "No Records Found",
  description = "No data items match your current filter or search criteria.",
  actionLabel,
  onAction,
  actionIcon,
}: EmptyStateProps) {
  return (
    <Paper
      p="xl"
      radius="md"
      withBorder
      ta="center"
      bg="var(--surface-card, var(--mantine-color-default))"
      style={{
        borderStyle: "dashed",
        borderColor:
          "var(--surface-border, var(--mantine-color-default-border))",
      }}
    >
      <Stack align="center" gap="sm" py="md">
        <ThemeIcon size={48} radius="xl" color="gray" variant="light">
          <Icon size={24} />
        </ThemeIcon>

        <Box>
          <Title order={4} fw={700} c="var(--mantine-color-text)">
            {title}
          </Title>
          <Text size="xs" c="dimmed" mt={4} maw={400} mx="auto">
            {description}
          </Text>
        </Box>

        {actionLabel && onAction && (
          <Button
            size="xs"
            variant="light"
            color="tradexGold"
            onClick={onAction}
            leftSection={actionIcon}
            mt="xs"
          >
            {actionLabel}
          </Button>
        )}
      </Stack>
    </Paper>
  );
}

export default EmptyState;
