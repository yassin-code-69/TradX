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
  numbers: "Numbers Matrix",
  tickets: "Tickets",
  active: "Active",
  winning: "Winning Tickets",
  results: "Results & Winners",
  winners: "Winners List",
  pending: "Pending Verification",
  publish: "Publish Results",
  finance: "Financial",
  wallets: "Wallets Overview",
  deposits: "Deposit Requests",
  withdrawals: "Withdrawals",
  transfers: "Transfers",
  ledger: "Ledger Transactions",
  transactions: "Transactions",
  adjustments: "Adjustments",
  users: "Users",
  blocked: "Blocked Users",
  settings: "Settings",
  gateways: "Payment Gateways",
  general: "General Settings",
  profile: "Admin Profile",
  security: "Security & Keys",
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
        fontWeight: 600,
        letterSpacing: "0.02em",
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
            fw={700}
            style={{ color: "var(--brand-gold-text)" }}
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
        <Box visibleFrom="md" w={260}>
          <TextInput
            placeholder="Search draws, tickets, txns..."
            size="xs"
            leftSection={<IconSearch size={14} stroke={1.75} />}
            rightSection={
              <Group gap={2}>
                <Kbd size="xs" style={{ fontSize: "10px", padding: "1px 4px" }}>
                  ⌘
                </Kbd>
                <Kbd size="xs" style={{ fontSize: "10px", padding: "1px 4px" }}>
                  K
                </Kbd>
              </Group>
            }
            styles={{
              input: {
                backgroundColor: "var(--header-search-bg)",
                borderColor: "var(--header-search-border)",
                color: "var(--mantine-color-text)",
                fontSize: "12px",
                borderRadius: "8px",
                transition: "all 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
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
              fontWeight: 600,
              backgroundColor: "var(--status-emerald-bg)",
              borderColor: "var(--status-emerald-border)",
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
              transition: "all 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
            }}
          >
            {isDark ? (
              <IconSun
                size={18}
                stroke={1.75}
                color="var(--mantine-color-tradexGold-4)"
              />
            ) : (
              <IconMoon
                size={18}
                stroke={1.75}
                color="var(--mantine-color-tradexNavy-7)"
              />
            )}
          </ActionIcon>
        </Tooltip>

        {/* Notification Bell */}
        <Tooltip label="Notifications">
          <Indicator inline size={8} offset={4} color="tradexGold" processing>
            <ActionIcon
              variant="default"
              size="md"
              aria-label="Notifications"
              style={{
                transition: "all 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
              }}
            >
              <IconBell size={18} stroke={1.6} />
            </ActionIcon>
          </Indicator>
        </Tooltip>

        <Divider orientation="vertical" h={22} />

        {/* Admin User Menu */}
        <Menu
          shadow="xl"
          width={230}
          position="bottom-end"
          transitionProps={{ transition: "pop-top-right", duration: 180 }}
        >
          <Menu.Target>
            <UnstyledButton
              p={4}
              px={6}
              style={{
                borderRadius: "10px",
                backgroundColor: "var(--header-btn-bg)",
                border: "1px solid var(--header-btn-border)",
                transition: "all 0.15s ease",
              }}
            >
              <Group gap="xs" wrap="nowrap">
                <Avatar
                  radius="xl"
                  size="sm"
                  variant="gradient"
                  gradient={{ from: "#D97706", to: "#F59E0B", deg: 135 }}
                  c="#070B14"
                  fw={800}
                >
                  {userInitials}
                </Avatar>
                <Box visibleFrom="sm" style={{ textAlign: "left" }}>
                  <Text size="xs" fw={700} lh={1.2}>
                    {adminUser?.profile?.fullName ||
                      adminUser?.username ||
                      "Admin"}
                  </Text>
                  <Badge
                    size="xs"
                    variant="filled"
                    color="tradexGold"
                    px={4}
                    h={14}
                    style={{
                      fontSize: "9px",
                      fontWeight: 700,
                      color: "#070B14",
                    }}
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

          <Menu.Dropdown>
            <Box px="xs" py={8}>
              <Text size="xs" fw={700}>
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
              prefetch={true}
            >
              My Profile & Account
            </Menu.Item>
            <Menu.Item
              leftSection={<IconShieldLock size={15} stroke={1.5} />}
              component={Link}
              href="/settings/security"
              prefetch={true}
            >
              Security & Auth Keys
            </Menu.Item>
            <Menu.Item
              leftSection={<IconSettings size={15} stroke={1.5} />}
              component={Link}
              href="/settings/gateways"
              prefetch={true}
            >
              Payment & System Settings
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
