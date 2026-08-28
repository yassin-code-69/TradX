"use client";

import {
  Alert,
  Box,
  Button,
  Center,
  Checkbox,
  Container,
  Divider,
  Group,
  Paper,
  PasswordInput,
  Stack,
  Text,
  TextInput,
  ThemeIcon,
  Title,
} from "@mantine/core";
import {
  IconAlertCircle,
  IconArrowRight,
  IconCrown,
  IconLock,
  IconMail,
  IconShieldCheck,
} from "@tabler/icons-react";
import { useRouter } from "next/navigation";
import type React from "react";
import { useState } from "react";
import { useAuth } from "@/context/AuthContext";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(true);
  const [emailError, setEmailError] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [authError, setAuthError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { login } = useAuth();
  const router = useRouter();

  const validate = (): boolean => {
    let isValid = true;
    setEmailError("");
    setPasswordError("");
    setAuthError(null);

    const trimmedEmail = email.trim();
    if (!trimmedEmail) {
      setEmailError("Email address is required");
      isValid = false;
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmedEmail)) {
      setEmailError("Please enter a valid email address");
      isValid = false;
    }

    if (!password) {
      setPasswordError("Password is required");
      isValid = false;
    } else if (password.length < 6) {
      setPasswordError("Password must be at least 6 characters");
      isValid = false;
    }

    return isValid;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validate()) {
      return;
    }

    setIsSubmitting(true);
    setAuthError(null);

    try {
      const { error } = await login(email.trim(), password);

      if (error) {
        setAuthError(
          error.message ||
            "Authentication failed. Please check your credentials.",
        );
        setIsSubmitting(false);
        return;
      }

      router.replace("/dashboard");
    } catch (err) {
      setAuthError(
        err instanceof Error ? err.message : "An unexpected error occurred.",
      );
      setIsSubmitting(false);
    }
  };

  return (
    <Box
      style={{
        minHeight: "100vh",
        backgroundColor: "#0A0F1D",
        backgroundImage:
          "radial-gradient(ellipse 80% 60% at 50% -20%, rgba(217, 119, 6, 0.12), transparent 70%)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "24px 16px",
      }}
    >
      <Container size={440} w="100%">
        <Stack align="center" gap="xs" mb="xl">
          {/* TRADEX Luxury Brand Logo */}
          <ThemeIcon
            size={56}
            radius="xl"
            variant="gradient"
            gradient={{ from: "#D97706", to: "#F59E0B", deg: 135 }}
            style={{
              boxShadow: "0 8px 24px rgba(217, 119, 6, 0.35)",
            }}
          >
            <IconCrown size={32} stroke={1.75} color="#0A0F1D" />
          </ThemeIcon>

          <Title
            order={1}
            size="h2"
            fw={800}
            style={{
              letterSpacing: "1px",
              background: "linear-gradient(135deg, #FFFFFF 0%, #CBD5E1 100%)",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
            }}
          >
            TRADEX ADMIN
          </Title>

          <Text size="xs" c="dimmed" fw={500} ta="center">
            Operational Command Center • Sign in to access system
          </Text>
        </Stack>

        <Paper
          withBorder
          p="xl"
          radius="lg"
          style={{
            backgroundColor: "#0F172A",
            borderColor: "#1E293B",
            boxShadow:
              "0 20px 25px -5px rgba(0, 0, 0, 0.5), 0 8px 10px -6px rgba(0, 0, 0, 0.5)",
          }}
        >
          <form onSubmit={handleSubmit}>
            <Stack gap="md">
              {authError && (
                <Alert
                  icon={<IconAlertCircle size={16} />}
                  color="red"
                  variant="light"
                  radius="md"
                  styles={{
                    root: {
                      backgroundColor: "rgba(239, 68, 68, 0.1)",
                      borderColor: "rgba(239, 68, 68, 0.3)",
                    },
                  }}
                >
                  <Text size="xs" fw={500}>
                    {authError}
                  </Text>
                </Alert>
              )}

              <TextInput
                label="Admin Email"
                placeholder="admin@tradex.com"
                value={email}
                onChange={(e) => setEmail(e.currentTarget.value)}
                error={emailError}
                required
                size="sm"
                leftSection={<IconMail size={16} stroke={1.5} />}
                autoComplete="email"
                disabled={isSubmitting}
                styles={{
                  input: {
                    backgroundColor: "#141E33",
                    borderColor: "#1E293B",
                  },
                }}
              />

              <PasswordInput
                label="Password"
                placeholder="••••••••••••"
                value={password}
                onChange={(e) => setPassword(e.currentTarget.value)}
                error={passwordError}
                required
                size="sm"
                leftSection={<IconLock size={16} stroke={1.5} />}
                autoComplete="current-password"
                disabled={isSubmitting}
                styles={{
                  input: {
                    backgroundColor: "#141E33",
                    borderColor: "#1E293B",
                  },
                }}
              />

              <Group justify="space-between" mt={4}>
                <Checkbox
                  label="Remember this workstation"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.currentTarget.checked)}
                  size="xs"
                  color="tradexGold"
                  styles={{
                    label: {
                      fontSize: "12px",
                      color: "var(--mantine-color-dimmed)",
                    },
                  }}
                />
              </Group>

              <Button
                type="submit"
                fullWidth
                size="md"
                mt="xs"
                loading={isSubmitting}
                rightSection={<IconArrowRight size={16} />}
                variant="gradient"
                gradient={{ from: "#D97706", to: "#F59E0B", deg: 90 }}
                style={{
                  color: "#0A0F1D",
                  fontWeight: 700,
                  boxShadow: "0 4px 14px rgba(217, 119, 6, 0.3)",
                }}
              >
                Authenticate & Enter
              </Button>
            </Stack>
          </form>

          <Divider my="lg" color="#1E293B" />

          <Center>
            <Group gap={6}>
              <IconShieldCheck
                size={14}
                style={{ color: "var(--mantine-color-tradexGold-5)" }}
              />
              <Text size="11px" c="dimmed" fw={500}>
                Role-gated administrative session • 256-bit encrypted
              </Text>
            </Group>
          </Center>
        </Paper>

        <Text size="11px" c="dimmed" ta="center" mt="lg">
          TRADEX System Administration • All activities are audited and logged
        </Text>
      </Container>
    </Box>
  );
}
