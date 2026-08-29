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
import { Component, type ErrorInfo, type ReactNode } from "react";

interface Props {
  children?: ReactNode;
  fallbackTitle?: string;
  fallbackMessage?: string;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

export class ErrorBoundary extends Component<Props, State> {
  public override state: State = {
    hasError: false,
    error: null,
    errorInfo: null,
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error, errorInfo: null };
  }

  public override componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error(
      "[TRADEX Admin ErrorBoundary caught an error]:",
      error,
      errorInfo,
    );
    this.setState({ errorInfo });
  }

  private handleReset = () => {
    this.setState({ hasError: false, error: null, errorInfo: null });
  };

  public override render() {
    if (this.state.hasError) {
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
                size={54}
                radius="xl"
                color="red"
                variant="light"
                style={{
                  boxShadow: "0 8px 24px rgba(239, 68, 68, 0.25)",
                }}
              >
                <IconAlertTriangle size={28} />
              </ThemeIcon>

              <Box>
                <Title order={3} fw={800} c="var(--mantine-color-text)">
                  {this.props.fallbackTitle || "An Unexpected Glitch Occurred"}
                </Title>
                <Text size="sm" c="dimmed" mt={4}>
                  {this.props.fallbackMessage ||
                    "A rendering error was caught safely. Your session and operational data remain intact."}
                </Text>
              </Box>

              {this.state.error && (
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
                    {this.state.error.name}: {this.state.error.message}
                  </Text>
                </Alert>
              )}

              <Group gap="sm" mt="xs">
                <Button
                  variant="default"
                  leftSection={<IconRefresh size={16} />}
                  onClick={this.handleReset}
                >
                  Try Again
                </Button>
                <Button
                  component={Link}
                  href="/dashboard"
                  color="tradexGold"
                  style={{ color: "#0A0F1D", fontWeight: 700 }}
                  leftSection={<IconHome size={16} />}
                  onClick={this.handleReset}
                >
                  Return to Dashboard
                </Button>
              </Group>
            </Stack>
          </Card>
        </Container>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
