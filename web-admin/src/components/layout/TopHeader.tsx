"use client";

import {
  ActionIcon,
  Avatar,
  Badge,
  Box,
  Breadcrumbs,
  Burger,
  Divider,
  Group,
  Indicator,
  Kbd,
  Menu,
  Text,
  TextInput,
  Tooltip,
  UnstyledButton,
  useComputedColorScheme,
  useMantineColorScheme,
} from "@mantine/core";
import {
  IconBell,
  IconChevronDown,
  IconChevronRight,
  IconLayoutSidebarLeftCollapse,
  IconLayoutSidebarLeftExpand,
  IconLogout,
  IconMoon,
  IconSearch,
  IconSettings,
  IconShieldLock,
  IconSun,
  IconUser,
} from "@tabler/icons-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/context/AuthContext";

// Map path segments to readable breadcrumb titles
const PATH_LABELS: Record<string, string> = {
  dashboard: "Dashboard",
  draws: "Draws",
  mega: "Mega Draw",
  daily: "Daily Draw",
  hourly: "Hourly Draw",
  numbers: "Numbers",
  tickets: "Tickets",
  results: "Results & Winners",
  winners: "Winners",
  finance: "Financial",
  wallets: "Wallets",
  deposits: "Add Money Requests",
  withdrawals: "Withdrawals",
  transfers: "Transfers",
  transactions: "Transactions",
  users: "Users",
  settings: "Settings",
  profile: "Profile",
};

interface TopHeaderProps {
  mobileOpened: boolean;
  onToggleMobile: () => void;
  isCollapsed: boolean;
  onToggleCollapse: () => void;
}

export function TopHeader({
  mobileOpened,
  onToggleMobile,
  isCollapsed,
  onToggleCollapse,
}: TopHeaderProps) {
  const pathname = usePathname();
  const { adminUser, logout, roles } = useAuth();
  const { setColorScheme } = useMantineColorScheme();
  const computedColorScheme = useComputedColorScheme("dark", {
    getInitialValueInEffect: true,
  });
  const isDark = computedColorScheme === "dark";

  const handleToggleColorScheme = () => {
    setColorScheme(isDark ? "light" : "dark");
  };

  // Generate breadcrumb items from current pathname
  const segments = pathname.split("/").filter(Boolean);
  const breadcrumbItems = [
    <Link
      key="home"
      href="/dashboard"
      style={{
        textDecoration: "none",
        color: "var(--mantine-color-dimmed)",
        fontSize: "13px",
        fontWeight: 500,
      }}
    >
      TRADEX
    </Link>,
    ...segments.map((segment, index) => {
      const url = `/${segments.slice(0, index + 1).join("/")}`;
      const isLast = index === segments.length - 1;
      const label =
        PATH_LABELS[segment] ||
        segment.charAt(0).toUpperCase() + segment.slice(1);

      if (isLast) {
        return (
          <Text
            key={url}
            size="xs"
            fw={600}
            c={isDark ? "tradexGold.4" : "tradexGold.8"}
          >
            {label}
          </Text>
        );
      }

      return (
        <Link
          key={url}
          href={url}
          style={{
            textDecoration: "none",
            color: "var(--mantine-color-dimmed)",
            fontSize: "13px",
            fontWeight: 500,
          }}
        >
          {label}
        </Link>
      );
    }),
  ];

  const primaryRole = roles[0] || "ADMIN";
  const roleDisplay = primaryRole.replace(/_/g, " ");
  const userInitials =
    adminUser?.profile?.fullName
      ?.split(" ")
      .map((n) => n[0])
      .slice(0, 2)
      .join("")
      .toUpperCase() ||
    adminUser?.username?.slice(0, 2).toUpperCase() ||
    "AD";

  return (
    <Group h="100%" px="md" justify="space-between" wrap="nowrap">
      {/* Left: Burger, Toggle & Breadcrumbs */}
      <Group gap="sm" wrap="nowrap">
        <Burger
          opened={mobileOpened}
          onClick={onToggleMobile}
          hiddenFrom="sm"
          size="sm"
          aria-label="Toggle navigation"
        />

        <Tooltip
          label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
          position="bottom"
        >
          <ActionIcon
            variant="subtle"
            color="gray"
            size="md"
            visibleFrom="sm"
            onClick={onToggleCollapse}
            aria-label="Toggle collapse"
          >
            {isCollapsed ? (
              <IconLayoutSidebarLeftExpand size={20} />
            ) : (
              <IconLayoutSidebarLeftCollapse size={20} />
            )}
          </ActionIcon>
        </Tooltip>

        <Divider orientation="vertical" h={20} visibleFrom="sm" />

        <Breadcrumbs
          separator={
            <IconChevronRight
              size={12}
              style={{ color: "var(--mantine-color-dimmed)" }}
            />
          }
        >
          {breadcrumbItems}
        </Breadcrumbs>
      </Group>

      {/* Right: Search, Status, Theme, Notifications & User Menu */}
      <Group gap="sm" wrap="nowrap">
        {/* Global Search Box */}
        <Box visibleFrom="md" w={240}>
          <TextInput
            placeholder="Search draws, tickets, txns..."
            size="xs"
            leftSection={<IconSearch size={14} stroke={1.5} />}
            rightSection={
              <Group gap={2}>
                <Kbd size="xs">⌘</Kbd>
                <Kbd size="xs">K</Kbd>
              </Group>
            }
            styles={{
              input: {
                backgroundColor: isDark ? "#0F172A" : "#F1F5F9",
                borderColor: isDark ? "#1E293B" : "#CBD5E1",
                color: "var(--mantine-color-text)",
                fontSize: "12px",
                transition:
                  "background-color 0.2s ease, border-color 0.2s ease",
              },
            }}
          />
        </Box>

        {/* System Health Indicator */}
        <Badge
          color="teal"
          variant="dot"
          size="sm"
          visibleFrom="lg"
          styles={{
            root: {
              textTransform: "capitalize",
              fontWeight: 500,
            },
          }}
        >
          Operational
        </Badge>

        {/* Theme Toggle Button */}
        <Tooltip
          label={isDark ? "Switch to Light Mode" : "Switch to Dark Mode"}
        >
          <ActionIcon
            variant="default"
            size="md"
            onClick={handleToggleColorScheme}
            aria-label="Toggle color scheme"
            style={{
              transition:
                "background-color 0.2s ease, border-color 0.2s ease, color 0.2s ease",
            }}
          >
            {isDark ? (
              <IconSun
                size={18}
                stroke={1.5}
                color="var(--mantine-color-yellow-4)"
              />
            ) : (
              <IconMoon
                size={18}
                stroke={1.5}
                color="var(--mantine-color-tradexNavy-7)"
              />
            )}
          </ActionIcon>
        </Tooltip>

        {/* Notification Bell */}
        <Tooltip label="Notifications">
          <Indicator
            inline
            size={9}
            offset={4}
            color={isDark ? "tradexGold.5" : "tradexGold.7"}
            processing
          >
            <ActionIcon
              variant="default"
              size="md"
              aria-label="Notifications"
              style={{
                transition:
                  "background-color 0.2s ease, border-color 0.2s ease, color 0.2s ease",
              }}
            >
              <IconBell size={18} stroke={1.5} />
            </ActionIcon>
          </Indicator>
        </Tooltip>

        <Divider orientation="vertical" h={22} />

        {/* Admin User Menu */}
        <Menu
          shadow="md"
          width={220}
          position="bottom-end"
          transitionProps={{ transition: "pop-top-right" }}
        >
          <Menu.Target>
            <UnstyledButton
              p={4}
              style={{
                borderRadius: "8px",
                transition: "background-color 0.15s ease",
              }}
            >
              <Group gap="xs" wrap="nowrap">
                <Avatar
                  radius="xl"
                  size="sm"
                  color="tradexNavy"
                  bg={isDark ? "tradexGold.5" : "tradexGold.6"}
                  c="dark.9"
                  fw={700}
                >
                  {userInitials}
                </Avatar>
                <Box visibleFrom="sm" style={{ textAlign: "left" }}>
                  <Text size="xs" fw={600} lh={1.2}>
                    {adminUser?.profile?.fullName ||
                      adminUser?.username ||
                      "Admin"}
                  </Text>
                  <Badge
                    size="xs"
                    variant={isDark ? "light" : "outline"}
                    color="tradexGold"
                    px={4}
                    h={14}
                    style={{ fontSize: "9px", fontWeight: 600 }}
                  >
                    {roleDisplay}
                  </Badge>
                </Box>
                <IconChevronDown
                  size={14}
                  style={{ opacity: 0.6 }}
                  stroke={1.5}
                />
              </Group>
            </UnstyledButton>
          </Menu.Target>

          <Menu.Dropdown
            style={{
              backgroundColor: "var(--mantine-color-body)",
              borderColor: "var(--mantine-color-default-border)",
            }}
          >
            <Box px="xs" py={6}>
              <Text size="xs" fw={600}>
                {adminUser?.profile?.fullName ||
                  adminUser?.username ||
                  "Administrator"}
              </Text>
              <Text size="xs" c="dimmed" truncate>
                {adminUser?.email || "admin@tradex.com"}
              </Text>
            </Box>

            <Menu.Divider />

            <Menu.Label>Admin Account</Menu.Label>
            <Menu.Item
              leftSection={<IconUser size={15} stroke={1.5} />}
              component={Link}
              href="/settings/profile"
            >
              My Profile
            </Menu.Item>
            <Menu.Item
              leftSection={<IconShieldLock size={15} stroke={1.5} />}
              component={Link}
              href="/settings/security"
            >
              Security
            </Menu.Item>
            <Menu.Item
              leftSection={<IconSettings size={15} stroke={1.5} />}
              component={Link}
              href="/settings"
            >
              Settings
            </Menu.Item>

            <Menu.Divider />

            <Menu.Item
              color="red"
              leftSection={<IconLogout size={15} stroke={1.5} />}
              onClick={() => logout()}
            >
              Sign Out
            </Menu.Item>
          </Menu.Dropdown>
        </Menu>
      </Group>
    </Group>
  );
}

export default TopHeader;
