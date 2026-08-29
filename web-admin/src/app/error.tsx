"use client";

import {
  Alert,
  Box,
  Button,
  Card,
  Container,
  Group,
  Stack,
  Text,
  ThemeIcon,
  Title,
} from "@mantine/core";
import { IconAlertTriangle, IconHome, IconRefresh } from "@tabler/icons-react";
import Link from "next/link";
import { useEffect } from "react";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("[TRADEX Admin Error Caught]:", error);
  }, [error]);

  return (
    <Container size="sm" py="xl">
      <Card
        p="xl"
        radius="lg"
        withBorder
        bg="var(--surface-card, var(--mantine-color-default))"
        style={{
          borderColor: "rgba(239, 68, 68, 0.3)",
          boxShadow: "0 20px 40px -15px rgba(239, 68, 68, 0.15)",
        }}
      >
        <Stack align="center" ta="center" gap="md">
          <ThemeIcon
            size={56}
            radius="xl"
            color="red"
            variant="light"
            style={{ boxShadow: "0 8px 24px rgba(239, 68, 68, 0.25)" }}
          >
            <IconAlertTriangle size={30} />
          </ThemeIcon>

          <Box>
            <Title order={2} fw={800} c="var(--mantine-color-text)">
              Application Glitch Detected
            </Title>
            <Text size="sm" c="dimmed" mt={6} maw={440}>
              An unhandled exception occurred in the administrative interface.
              State has been protected.
            </Text>
          </Box>

          {error?.message && (
            <Alert
              color="red"
              variant="light"
              w="100%"
              ta="left"
              styles={{
                root: {
                  fontFamily: "var(--font-geist-mono), monospace",
                  fontSize: "12px",
                  wordBreak: "break-word",
                },
              }}
            >
              <Text size="xs" fw={700} ff="monospace">
                {error.name}: {error.message}
              </Text>
            </Alert>
          )}

          <Group gap="sm" mt="xs">
            <Button
              variant="default"
              leftSection={<IconRefresh size={16} />}
              onClick={() => reset()}
            >
              Retry Action
            </Button>
            <Button
              component={Link}
              href="/dashboard"
              color="tradexGold"
              style={{ color: "#0A0F1D", fontWeight: 700 }}
              leftSection={<IconHome size={16} />}
            >
              Go to Dashboard
            </Button>
          </Group>
        </Stack>
      </Card>
    </Container>
  );
}
