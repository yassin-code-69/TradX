"use client";

import {
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
import { IconDashboard, IconFileOff } from "@tabler/icons-react";
import Link from "next/link";

export default function NotFound() {
  return (
    <Container size="sm" py={60}>
      <Card
        p="xl"
        radius="lg"
        withBorder
        bg="var(--surface-card, var(--mantine-color-default))"
        style={{
          boxShadow: "0 20px 40px -15px rgba(0, 0, 0, 0.2)",
        }}
      >
        <Stack align="center" ta="center" gap="md">
          <ThemeIcon size={64} radius="xl" color="yellow" variant="light">
            <IconFileOff size={32} />
          </ThemeIcon>

          <Box>
            <Text
              size="xs"
              fw={700}
              c="tradexGold.5"
              tt="uppercase"
              style={{ letterSpacing: "1px" }}
            >
              404 • Resource Not Located
            </Text>
            <Title order={2} fw={800} mt={4}>
              Administrative Route Missing
            </Title>
            <Text size="sm" c="dimmed" mt={6} maw={420}>
              The administrative endpoint or resource you are trying to access
              does not exist or has been relocated in this deployment.
            </Text>
          </Box>

          <Group mt="sm">
            <Button
              component={Link}
              href="/dashboard"
              color="tradexGold"
              style={{ color: "#0A0F1D", fontWeight: 700 }}
              leftSection={<IconDashboard size={16} />}
            >
              Back to Operational Dashboard
            </Button>
          </Group>
        </Stack>
      </Card>
    </Container>
  );
}
