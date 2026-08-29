"use client";

import {
  ActionIcon,
  Badge,
  Box,
  Collapse,
  Divider,
  Group,
  Menu,
  ScrollArea,
  Stack,
  Text,
  ThemeIcon,
  Tooltip,
  UnstyledButton,
} from "@mantine/core";
import {
  IconAward,
  IconBuildingBank,
  IconCalendarEvent,
  IconChevronDown,
  IconChevronRight,
  IconClock,
  IconCoin,
  IconCreditCard,
  IconCrown,
  IconDashboard,
  IconLayoutSidebarLeftCollapse,
  IconLayoutSidebarLeftExpand,
  IconNumbers,
  IconReceipt2,
  IconSettings,
  IconShieldLock,
  IconSparkles,
  IconTicket,
  IconTransfer,
  IconTrophy,
  IconUser,
  IconUserCheck,
  IconUserOff,
  IconUsers,
  IconWallet,
} from "@tabler/icons-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type React from "react";
import { Suspense, useState } from "react";
import { useAuth } from "@/context/AuthContext";

export interface NavSubItem {
  label: string;
  href: string;
  icon?: React.ComponentType<{
    size?: number | string;
    stroke?: number;
    style?: React.CSSProperties;
  }>;
  permission?: string;
  role?: string;
}

export interface NavItem {
  label: string;
  icon: React.ComponentType<{
    size?: number | string;
    stroke?: number;
    style?: React.CSSProperties;
  }>;
  href?: string;
  permission?: string;
  role?: string;
  subItems?: NavSubItem[];
  badge?: string | number;
}

const NAV_ITEMS: NavItem[] = [
  {
    label: "Dashboard",
    icon: IconDashboard,
    href: "/dashboard",
    permission: "dashboard.view",
  },
  {
    label: "Draws",
    icon: IconTrophy,
    permission: "draw.view",
    subItems: [
      {
        label: "All Draws",
        href: "/draws",
        icon: IconTrophy,
        permission: "draw.view",
      },
      {
        label: "Mega Draw",
        href: "/draws/mega",
        icon: IconSparkles,
        permission: "draw.view",
      },
      {
        label: "Daily Draw",
        href: "/draws/daily",
        icon: IconCalendarEvent,
        permission: "draw.view",
      },
      {
        label: "Hourly Draw",
        href: "/draws/hourly",
        icon: IconClock,
        permission: "draw.view",
      },
      {
        label: "Numbers Matrix",
        href: "/draws/numbers",
        icon: IconNumbers,
        permission: "draw.view",
      },
    ],
  },
  {
    label: "Tickets",
    icon: IconTicket,
    permission: "tickets.view",
    subItems: [
      {
        label: "All Tickets",
        href: "/tickets",
        icon: IconTicket,
        permission: "tickets.view",
      },
      {
        label: "Active Tickets",
        href: "/tickets/active",
        icon: IconClock,
        permission: "tickets.view",
      },
      {
        label: "Winning Tickets",
        href: "/tickets/winning",
        icon: IconAward,
        permission: "tickets.view",
      },
    ],
  },
  {
    label: "Results & Winners",
    icon: IconAward,
    permission: "result.view",
    subItems: [
      {
        label: "Results",
        href: "/results",
        icon: IconAward,
        permission: "result.view",
      },
      {
        label: "Winners List",
        href: "/results/winners",
        icon: IconTrophy,
        permission: "result.view",
      },
      {
        label: "Pending Verification",
        href: "/results/pending",
        icon: IconCrown,
        permission: "result.view",
      },
      {
        label: "Publish Results",
        href: "/results/publish",
        icon: IconSparkles,
        permission: "result.view",
      },
    ],
  },
  {
    label: "Financial",
    icon: IconWallet,
    permission: "wallet.view",
    subItems: [
      {
        label: "Wallets Overview",
        href: "/finance/wallets",
        icon: IconWallet,
        permission: "wallet.view",
      },
      {
        label: "Deposit Requests",
        href: "/finance/deposits",
        icon: IconCoin,
        permission: "deposit.view",
      },
      {
        label: "Withdrawals",
        href: "/finance/withdrawals",
        icon: IconBuildingBank,
        permission: "withdraw.view",
      },
      {
        label: "Transfers",
        href: "/finance/transfers",
        icon: IconTransfer,
        permission: "transfer.view",
      },
      {
        label: "Ledger Transactions",
        href: "/finance/ledger",
        icon: IconReceipt2,
        permission: "wallet.view",
      },
      {
        label: "Adjustments",
        href: "/finance/adjustments",
        icon: IconSparkles,
        permission: "wallet.view",
      },
    ],
  },
  {
    label: "Users",
    icon: IconUsers,
    permission: "users.view",
    subItems: [
      {
        label: "All Users",
        href: "/users",
        icon: IconUsers,
        permission: "users.view",
      },
      {
        label: "Active Users",
        href: "/users/active",
        icon: IconUserCheck,
        permission: "users.view",
      },
      {
        label: "Blocked Users",
        href: "/users/blocked",
        icon: IconUserOff,
        permission: "users.view",
      },
    ],
  },
  {
    label: "Settings",
    icon: IconSettings,
    permission: "settings.manage",
    subItems: [
      {
        label: "Payment Gateways",
        href: "/settings/gateways",
        icon: IconCreditCard,
        permission: "settings.manage",
      },
      {
        label: "General Settings",
        href: "/settings/general",
        icon: IconSettings,
        permission: "settings.manage",
      },
      {
        label: "Admin Profile",
        href: "/settings/profile",
        icon: IconUser,
        permission: "settings.manage",
      },
      {
        label: "Security & Keys",
        href: "/settings/security",
        icon: IconShieldLock,
        permission: "settings.manage",
      },
    ],
  },
];

interface SidebarProps {
  isCollapsed: boolean;
  onToggleCollapse: () => void;
}

function SidebarInner({ isCollapsed, onToggleCollapse }: SidebarProps) {
  const pathname = usePathname();
  const { hasPermission, hasRole } = useAuth();

  const [openedGroups, setOpenedGroups] = useState<Record<string, boolean>>({
    Draws: true,
    Tickets: true,
    "Results & Winners": true,
    Financial: true,
    Users: true,
    Settings: true,
  });

  const toggleGroup = (groupLabel: string) => {
    setOpenedGroups((prev) => ({
      ...prev,
      [groupLabel]: !prev[groupLabel],
    }));
  };

  const filteredNavItems = NAV_ITEMS.map((item) => {
    if (item.permission && !hasPermission(item.permission)) {
      return null;
    }
    if (item.role && !hasRole(item.role)) {
      return null;
    }

    if (item.subItems) {
      const allowedSubItems = item.subItems.filter((sub) => {
        if (sub.permission && !hasPermission(sub.permission)) return false;
        if (sub.role && !hasRole(sub.role)) return false;
        return true;
      });

      if (allowedSubItems.length === 0) return null;
      return { ...item, subItems: allowedSubItems };
    }

    return item;
  }).filter(Boolean) as NavItem[];

  const isNavActive = (href?: string) => {
    if (!href) return false;
    if (href === "/dashboard") {
      return pathname === "/dashboard" || pathname === "/";
    }
    return pathname === href;
  };

  const isGroupActive = (item: NavItem) => {
    if (item.href && isNavActive(item.href)) return true;
    return item.subItems?.some((sub) => isNavActive(sub.href)) || false;
  };

  return (
    <Stack
      h="100%"
      justify="space-between"
      p={isCollapsed ? "xs" : "sm"}
      gap="xs"
      style={{
        userSelect: "none",
      }}
    >
      {/* Brand Header */}
      <Box pt={4} pb="xs">
        {isCollapsed ? (
          <Tooltip label="TRADEX Admin" position="right" withArrow>
            <Group justify="center">
              <ThemeIcon
                size={40}
                radius="lg"
                variant="gradient"
                gradient={{ from: "#D97706", to: "#F59E0B", deg: 135 }}
                style={{
                  boxShadow: "var(--sidebar-shadow)",
                }}
              >
                <IconCrown size={22} stroke={2} color="#070B14" />
              </ThemeIcon>
            </Group>
          </Tooltip>
        ) : (
          <Group justify="space-between" px="xs">
            <Group gap="sm">
              <ThemeIcon
                size={38}
                radius="lg"
                variant="gradient"
                gradient={{ from: "#D97706", to: "#F59E0B", deg: 135 }}
                style={{
                  boxShadow: "var(--sidebar-shadow)",
                }}
              >
                <IconCrown size={22} stroke={2} color="#070B14" />
              </ThemeIcon>
              <Box>
                <Group gap={6} align="center">
                  <Text
                    size="md"
                    fw={900}
                    lh={1}
                    style={{
                      letterSpacing: "0.5px",
                      background: "var(--brand-title-gradient)",
                      WebkitBackgroundClip: "text",
                      WebkitTextFillColor: "transparent",
                    }}
                  >
                    TRADEX
                  </Text>
                  <Badge
                    size="xs"
                    variant="filled"
                    color="tradexGold"
                    px={5}
                    h={16}
                    style={{
                      fontSize: "9px",
                      fontWeight: 800,
                      color: "#070B14",
                    }}
                  >
                    PRO
                  </Badge>
                </Group>
                <Text
                  size="9px"
                  c="dimmed"
                  fw={700}
                  mt={2}
                  style={{ letterSpacing: "1.2px" }}
                >
                  ADMIN CENTER
                </Text>
              </Box>
            </Group>
          </Group>
        )}
      </Box>

      <Divider
        style={{
          borderColor: "var(--surface-border)",
        }}
      />

      {/* Main Navigation Links */}
      <ScrollArea
        flex={1}
        scrollbarSize={4}
        type="hover"
        styles={{
          viewport: {
            paddingRight: isCollapsed ? 0 : 4,
          },
        }}
      >
        <Stack gap={4}>
          {filteredNavItems.map((item) => {
            const Icon = item.icon;
            const active = isGroupActive(item);

            // Collapsed view: Show Tooltip or Dropdown Menu
            if (isCollapsed) {
              if (item.subItems && item.subItems.length > 0) {
                return (
                  <Menu
                    key={item.label}
                    position="right-start"
                    withArrow
                    shadow="xl"
                    width={220}
                  >
                    <Menu.Target>
                      <Tooltip label={item.label} position="right" withArrow>
                        <ActionIcon
                          variant={active ? "light" : "subtle"}
                          color={active ? "tradexGold" : "gray"}
                          size={44}
                          radius="md"
                          mx="auto"
                          styles={{
                            root: {
                              position: "relative",
                              backgroundColor: active
                                ? "var(--brand-gold-bg-hover)"
                                : undefined,
                              borderLeft: active
                                ? "3px solid var(--color-gold-500)"
                                : "none",
                              transition:
                                "all 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
                            },
                          }}
                        >
                          <Icon size={20} stroke={1.8} />
                        </ActionIcon>
                      </Tooltip>
                    </Menu.Target>
                    <Menu.Dropdown>
                      <Menu.Label>{item.label}</Menu.Label>
                      {item.subItems.map((sub) => {
                        const SubIcon = sub.icon || IconChevronRight;
                        const subActive = isNavActive(sub.href);
                        return (
                          <Menu.Item
                            key={sub.label}
                            component={Link}
                            href={sub.href}
                            prefetch={true}
                            leftSection={<SubIcon size={14} stroke={1.6} />}
                            style={{
                              fontWeight: subActive ? 700 : 500,
                              color: subActive
                                ? "var(--brand-gold-text)"
                                : undefined,
                            }}
                          >
                            {sub.label}
                          </Menu.Item>
                        );
                      })}
                    </Menu.Dropdown>
                  </Menu>
                );
              }

              return (
                <Tooltip
                  key={item.label}
                  label={item.label}
                  position="right"
                  withArrow
                >
                  <ActionIcon
                    component={Link}
                    href={item.href || "#"}
                    prefetch={true}
                    variant={active ? "light" : "subtle"}
                    color={active ? "tradexGold" : "gray"}
                    size={44}
                    radius="md"
                    mx="auto"
                    styles={{
                      root: {
                        position: "relative",
                        backgroundColor: active
                          ? "var(--brand-gold-bg-hover)"
                          : undefined,
                        borderLeft: active
                          ? "3px solid var(--color-gold-500)"
                          : "none",
                        transition: "all 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
                      },
                    }}
                  >
                    <Icon size={20} stroke={1.8} />
                  </ActionIcon>
                </Tooltip>
              );
            }

            // Expanded view: Full navigation list with dropdowns
            if (item.subItems && item.subItems.length > 0) {
              const isOpened = !!openedGroups[item.label];

              return (
                <Box key={item.label}>
                  <UnstyledButton
                    onClick={() => toggleGroup(item.label)}
                    w="100%"
                    p="xs"
                    style={{
                      borderRadius: "10px",
                      backgroundColor: active
                        ? "var(--brand-gold-bg)"
                        : "transparent",
                      border: active
                        ? "1px solid var(--brand-gold-border)"
                        : "1px solid transparent",
                      transition: "all 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
                    }}
                  >
                    <Group justify="space-between" wrap="nowrap">
                      <Group gap="xs" wrap="nowrap">
                        <Icon
                          size={18}
                          stroke={1.8}
                          style={{
                            color: active
                              ? "var(--brand-gold-text)"
                              : "var(--mantine-color-dimmed)",
                          }}
                        />
                        <Text
                          size="sm"
                          fw={active ? 700 : 500}
                          style={{
                            color: active
                              ? "var(--brand-gold-text)"
                              : "var(--mantine-color-text)",
                          }}
                        >
                          {item.label}
                        </Text>
                      </Group>
                      {isOpened ? (
                        <IconChevronDown
                          size={14}
                          style={{ opacity: 0.6 }}
                          stroke={1.5}
                        />
                      ) : (
                        <IconChevronRight
                          size={14}
                          style={{ opacity: 0.6 }}
                          stroke={1.5}
                        />
                      )}
                    </Group>
                  </UnstyledButton>

                  <Collapse expanded={isOpened}>
                    <Stack gap={2} pl="md" pt={4}>
                      {item.subItems.map((sub) => {
                        const subActive = isNavActive(sub.href);
                        const SubIcon = sub.icon || IconChevronRight;
                        return (
                          <Link
                            key={sub.label}
                            href={sub.href}
                            prefetch={true}
                            style={{ textDecoration: "none" }}
                          >
                            <UnstyledButton
                              w="100%"
                              py={6}
                              px={10}
                              style={{
                                borderRadius: "8px",
                                backgroundColor: subActive
                                  ? "var(--brand-gold-bg-hover)"
                                  : "transparent",
                                color: subActive
                                  ? "var(--brand-gold-text)"
                                  : "var(--mantine-color-dimmed)",
                                fontWeight: subActive ? 700 : 500,
                                fontSize: "13px",
                                transition: "all 0.15s ease",
                              }}
                            >
                              <Group gap="xs" wrap="nowrap">
                                <SubIcon size={14} stroke={1.6} />
                                <Text size="13px" truncate>
                                  {sub.label}
                                </Text>
                              </Group>
                            </UnstyledButton>
                          </Link>
                        );
                      })}
                    </Stack>
                  </Collapse>
                </Box>
              );
            }

            return (
              <Link
                key={item.label}
                href={item.href || "#"}
                prefetch={true}
                style={{ textDecoration: "none" }}
              >
                <UnstyledButton
                  w="100%"
                  p="xs"
                  style={{
                    borderRadius: "10px",
                    height: "40px",
                    fontWeight: active ? 700 : 500,
                    backgroundColor: active
                      ? "var(--brand-gold-bg)"
                      : "transparent",
                    border: active
                      ? "1px solid var(--brand-gold-border)"
                      : "1px solid transparent",
                    color: active
                      ? "var(--brand-gold-text)"
                      : "var(--mantine-color-text)",
                    transition: "all 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
                  }}
                >
                  <Group gap="xs" wrap="nowrap">
                    <Icon size={18} stroke={1.8} />
                    <Text size="sm" fw={active ? 700 : 500}>
                      {item.label}
                    </Text>
                  </Group>
                </UnstyledButton>
              </Link>
            );
          })}
        </Stack>
      </ScrollArea>

      <Divider
        style={{
          borderColor: "var(--surface-border)",
        }}
      />

      {/* Bottom Footer: Sidebar Collapse Toggle & Status */}
      <Box pt={4}>
        {isCollapsed ? (
          <Tooltip label="Expand Sidebar" position="right">
            <ActionIcon
              variant="subtle"
              color="gray"
              size={36}
              radius="md"
              mx="auto"
              onClick={onToggleCollapse}
              aria-label="Expand sidebar"
            >
              <IconLayoutSidebarLeftExpand size={18} stroke={1.5} />
            </ActionIcon>
          </Tooltip>
        ) : (
          <Group justify="space-between" px="xs">
            <Text
              size="10px"
              c="dimmed"
              fw={700}
              style={{ letterSpacing: "0.5px" }}
            >
              TRADEX v1.0 PRO
            </Text>
            <ActionIcon
              variant="subtle"
              color="gray"
              size="sm"
              onClick={onToggleCollapse}
              aria-label="Collapse sidebar"
            >
              <IconLayoutSidebarLeftCollapse size={16} stroke={1.5} />
            </ActionIcon>
          </Group>
        )}
      </Box>
    </Stack>
  );
}

export function Sidebar(props: SidebarProps) {
  return (
    <Suspense fallback={null}>
      <SidebarInner {...props} />
    </Suspense>
  );
}

export default Sidebar;
