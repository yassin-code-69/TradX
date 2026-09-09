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
        backgroundColor: "#070B14",
        backgroundImage:
          "radial-gradient(ellipse 80% 60% at 50% -10%, rgba(245, 158, 11, 0.22), transparent 75%), radial-gradient(ellipse 50% 40% at 90% 90%, rgba(16, 185, 129, 0.12), transparent 70%), linear-gradient(180deg, #070B14 0%, #0F172A 100%)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "32px 16px",
      }}
    >
      <Container size={460} w="100%">
        {/* Brand Header */}
        <Stack align="center" gap="xs" mb="xl">
          <Box style={{ position: "relative" }}>
            <ThemeIcon
              size={68}
              radius="xl"
              variant="gradient"
              gradient={{ from: "#F59E0B", to: "#D97706", deg: 135 }}
              style={{
                boxShadow: "0 12px 36px rgba(245, 158, 11, 0.45)",
                border: "2px solid rgba(254, 243, 199, 0.3)",
              }}
            >
              <IconCrown size={38} stroke={2.2} color="#070B14" />
            </ThemeIcon>
          </Box>

          <Title
            order={1}
            size="26px"
            fw={900}
            style={{
              letterSpacing: "1.8px",
              color: "#FFFFFF",
              textShadow: "0 2px 10px rgba(0, 0, 0, 0.5)",
            }}
          >
            TRADEX ADMIN
          </Title>

          <Text
            size="xs"
            fw={600}
            ta="center"
            style={{
              letterSpacing: "0.6px",
              color: "#CBD5E1",
            }}
          >
            Operational Command Center • Sign in to access system
          </Text>
        </Stack>

        {/* Login Card */}
        <Paper
          withBorder
          p="xl"
          radius="lg"
          style={{
            backgroundColor: "rgba(15, 23, 42, 0.94)",
            backdropFilter: "blur(24px)",
            WebkitBackdropFilter: "blur(24px)",
            borderColor: "rgba(255, 255, 255, 0.14)",
            boxShadow:
              "0 30px 60px -15px rgba(0, 0, 0, 0.8), 0 0 0 1px rgba(255, 255, 255, 0.08)",
          }}
        >
          <form onSubmit={handleSubmit}>
            <Stack gap="md">
              {authError && (
                <Alert
                  icon={<IconAlertCircle size={18} />}
                  color="red"
                  variant="filled"
                  radius="md"
                  styles={{
                    root: {
                      backgroundColor: "rgba(220, 38, 38, 0.9)",
                      color: "#FFFFFF",
                    },
                    message: {
                      color: "#FFFFFF",
                      fontWeight: 600,
                    },
                  }}
                >
                  <Text size="xs" fw={600} c="#FFFFFF">
                    {authError}
                  </Text>
                </Alert>
              )}

              <TextInput
                label="Admin Email"
                placeholder="admin@xoxoshop.com"
                value={email}
                onChange={(e) => setEmail(e.currentTarget.value)}
                error={emailError}
                required
                size="md"
                leftSection={
                  <IconMail size={18} stroke={1.8} color="#F59E0B" />
                }
                autoComplete="email"
                disabled={isSubmitting}
                styles={{
                  label: {
                    color: "#F1F5F9",
                    fontWeight: 600,
                    fontSize: "13px",
                    marginBottom: "6px",
                  },
                  input: {
                    backgroundColor: "rgba(7, 11, 20, 0.9)",
                    borderColor: "rgba(255, 255, 255, 0.18)",
                    color: "#FFFFFF",
                    fontSize: "14px",
                    height: "44px",
                  },
                  error: {
                    color: "#FCA5A5",
                    fontSize: "12px",
                    marginTop: "4px",
                    fontWeight: 500,
                  },
                }}
              />

              <PasswordInput
                label="Password"
                placeholder="Enter admin password"
                value={password}
                onChange={(e) => setPassword(e.currentTarget.value)}
                error={passwordError}
                required
                size="md"
                leftSection={
                  <IconLock size={18} stroke={1.8} color="#F59E0B" />
                }
                autoComplete="current-password"
                disabled={isSubmitting}
                styles={{
                  label: {
                    color: "#F1F5F9",
                    fontWeight: 600,
                    fontSize: "13px",
                    marginBottom: "6px",
                  },
                  input: {
                    backgroundColor: "rgba(7, 11, 20, 0.9)",
                    borderColor: "rgba(255, 255, 255, 0.18)",
                    color: "#FFFFFF",
                    fontSize: "14px",
                    height: "44px",
                  },
                  innerInput: {
                    color: "#FFFFFF",
                  },
                  error: {
                    color: "#FCA5A5",
                    fontSize: "12px",
                    marginTop: "4px",
                    fontWeight: 500,
                  },
                }}
              />

              <Group justify="space-between" mt={4}>
                <Checkbox
                  label="Remember this workstation"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.currentTarget.checked)}
                  size="xs"
                  color="yellow"
                  styles={{
                    label: {
                      fontSize: "13px",
                      fontWeight: 500,
                      color: "#CBD5E1",
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
                rightSection={<IconArrowRight size={18} />}
                variant="gradient"
                gradient={{ from: "#F59E0B", to: "#D97706", deg: 90 }}
                className="btn-shimmer"
                style={{
                  height: "46px",
                  color: "#070B14",
                  fontWeight: 800,
                  fontSize: "15px",
                  boxShadow: "0 8px 24px rgba(245, 158, 11, 0.4)",
                  letterSpacing: "0.5px",
                }}
              >
                Authenticate & Enter
              </Button>
            </Stack>
          </form>

          <Divider my="lg" color="rgba(255, 255, 255, 0.12)" />

          <Center>
            <Group gap={8}>
              <IconShieldCheck size={16} style={{ color: "#F59E0B" }} />
              <Text size="12px" c="#94A3B8" fw={600}>
                Role-gated administrative session • 256-bit encrypted
              </Text>
            </Group>
          </Center>
        </Paper>

        <Text size="12px" c="#64748B" ta="center" mt="lg" fw={500}>
          TRADEX System Administration • All activities are audited and logged
        </Text>
      </Container>
    </Box>
  );
}
