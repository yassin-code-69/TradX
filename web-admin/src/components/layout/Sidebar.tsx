"use client";

import {
  ActionIcon,
  Badge,
  Box,
  Collapse,
  Divider,
  Group,
  Menu,
  NavLink,
  ScrollArea,
  Stack,
  Text,
  ThemeIcon,
  Tooltip,
  UnstyledButton,
  useComputedColorScheme,
} from "@mantine/core";
import {
  IconAward,
  IconBuildingBank,
  IconCalendarEvent,
  IconChevronDown,
  IconChevronRight,
  IconClock,
  IconCoin,
  IconCrown,
  IconDashboard,
  IconHash,
  IconLayoutSidebarLeftCollapse,
  IconLayoutSidebarLeftExpand,
  IconReceipt2,
  IconSettings,
  IconSparkles,
  IconTicket,
  IconTransfer,
  IconTrophy,
  IconUsers,
  IconWallet,
} from "@tabler/icons-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type React from "react";
import { useState } from "react";
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
        label: "Numbers",
        href: "/draws/numbers",
        icon: IconHash,
        permission: "draw.view",
      },
    ],
  },
  {
    label: "Tickets",
    icon: IconTicket,
    href: "/tickets",
    permission: "tickets.view",
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
        label: "Winners",
        href: "/results/winners",
        icon: IconCrown,
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
        label: "Wallets",
        href: "/finance/wallets",
        icon: IconWallet,
        permission: "wallet.view",
      },
      {
        label: "Add Money Requests",
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
        label: "Transactions",
        href: "/finance/transactions",
        icon: IconReceipt2,
        permission: "wallet.view",
      },
    ],
  },
  {
    label: "Users",
    icon: IconUsers,
    href: "/users",
    permission: "users.view",
  },
  {
    label: "Settings",
    icon: IconSettings,
    href: "/settings",
    permission: "settings.manage",
  },
];

interface SidebarProps {
  isCollapsed: boolean;
  onToggleCollapse: () => void;
}

export function Sidebar({ isCollapsed, onToggleCollapse }: SidebarProps) {
  const pathname = usePathname();
  const { hasPermission, hasRole } = useAuth();
  const computedColorScheme = useComputedColorScheme("dark", {
    getInitialValueInEffect: true,
  });
  const isDark = computedColorScheme === "dark";

  // Expanded submenus state
  const [openedGroups, setOpenedGroups] = useState<Record<string, boolean>>({
    Draws: true,
    Financial: true,
    "Results & Winners": true,
  });

  const toggleGroup = (groupLabel: string) => {
    setOpenedGroups((prev) => ({
      ...prev,
      [groupLabel]: !prev[groupLabel],
    }));
  };

  // Filter items according to permissions & roles
  const filteredNavItems = NAV_ITEMS.map((item) => {
    // Check main item permission
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
    if (href === "/dashboard") return pathname === "/dashboard";
    return pathname === href || pathname.startsWith(`${href}/`);
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
                size={38}
                radius="md"
                variant="gradient"
                gradient={{ from: "#D97706", to: "#F59E0B", deg: 135 }}
                style={{
                  boxShadow: isDark
                    ? "0 4px 12px rgba(217, 119, 6, 0.35)"
                    : "0 4px 12px rgba(217, 119, 6, 0.2)",
                }}
              >
                <IconCrown size={22} stroke={1.75} color="#0A0F1D" />
              </ThemeIcon>
            </Group>
          </Tooltip>
        ) : (
          <Group justify="space-between" px="xs">
            <Group gap="xs">
              <ThemeIcon
                size={36}
                radius="md"
                variant="gradient"
                gradient={{ from: "#D97706", to: "#F59E0B", deg: 135 }}
                style={{
                  boxShadow: isDark
                    ? "0 4px 12px rgba(217, 119, 6, 0.35)"
                    : "0 4px 12px rgba(217, 119, 6, 0.2)",
                }}
              >
                <IconCrown size={20} stroke={2} color="#0A0F1D" />
              </ThemeIcon>
              <Box>
                <Group gap={6} align="center">
                  <Text
                    size="md"
                    fw={800}
                    lh={1}
                    style={{
                      letterSpacing: "0.5px",
                      background: isDark
                        ? "linear-gradient(135deg, #FDE68A 0%, #D97706 100%)"
                        : "linear-gradient(135deg, #B45309 0%, #78350F 100%)",
                      WebkitBackgroundClip: "text",
                      WebkitTextFillColor: "transparent",
                    }}
                  >
                    TRADEX
                  </Text>
                  <Badge
                    size="xs"
                    variant={isDark ? "outline" : "light"}
                    color="tradexGold"
                    px={4}
                    h={14}
                    style={{ fontSize: "8px", fontWeight: 700 }}
                  >
                    PRO
                  </Badge>
                </Group>
                <Text
                  size="9px"
                  c="dimmed"
                  fw={600}
                  style={{ letterSpacing: "1px" }}
                >
                  ADMIN CONSOLE
                </Text>
              </Box>
            </Group>
          </Group>
        )}
      </Box>

      <Divider />

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
                    shadow="md"
                    width={200}
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
                              borderLeft: active
                                ? `3px solid var(--mantine-color-tradexGold-${isDark ? "4" : "7"})`
                                : "none",
                            },
                          }}
                        >
                          <Icon size={20} stroke={1.75} />
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
                            leftSection={<SubIcon size={14} stroke={1.5} />}
                            style={{
                              fontWeight: subActive ? 600 : 400,
                              color: subActive
                                ? isDark
                                  ? "var(--mantine-color-tradexGold-4)"
                                  : "var(--mantine-color-tradexGold-8)"
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
                    variant={active ? "light" : "subtle"}
                    color={active ? "tradexGold" : "gray"}
                    size={44}
                    radius="md"
                    mx="auto"
                    styles={{
                      root: {
                        borderLeft: active
                          ? `3px solid var(--mantine-color-tradexGold-${isDark ? "4" : "7"})`
                          : "none",
                      },
                    }}
                  >
                    <Icon size={20} stroke={1.75} />
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
                      borderRadius: "8px",
                      backgroundColor: active
                        ? isDark
                          ? "rgba(217, 119, 6, 0.15)"
                          : "rgba(217, 119, 6, 0.1)"
                        : "transparent",
                      transition:
                        "background-color 0.15s ease, color 0.15s ease",
                    }}
                  >
                    <Group justify="space-between" wrap="nowrap">
                      <Group gap="xs" wrap="nowrap">
                        <Icon
                          size={18}
                          stroke={1.75}
                          style={{
                            color: active
                              ? isDark
                                ? "var(--mantine-color-tradexGold-4)"
                                : "var(--mantine-color-tradexGold-7)"
                              : "var(--mantine-color-dimmed)",
                          }}
                        />
                        <Text
                          size="sm"
                          fw={active ? 600 : 500}
                          c={
                            active
                              ? isDark
                                ? "tradexGold.4"
                                : "tradexGold.8"
                              : undefined
                          }
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
                    <Stack gap={2} pl="lg" pt={4}>
                      {item.subItems.map((sub) => {
                        const subActive = isNavActive(sub.href);
                        const SubIcon = sub.icon || IconChevronRight;
                        return (
                          <NavLink
                            key={sub.label}
                            component={Link}
                            href={sub.href}
                            label={sub.label}
                            leftSection={<SubIcon size={14} stroke={1.5} />}
                            active={subActive}
                            variant="light"
                            color="tradexGold"
                            styles={{
                              root: {
                                borderRadius: "6px",
                                paddingLeft: "8px",
                                paddingRight: "8px",
                                height: "34px",
                                fontSize: "13px",
                                fontWeight: subActive ? 600 : 400,
                                color: subActive
                                  ? isDark
                                    ? "var(--mantine-color-tradexGold-4)"
                                    : "var(--mantine-color-tradexGold-8)"
                                  : undefined,
                              },
                            }}
                          />
                        );
                      })}
                    </Stack>
                  </Collapse>
                </Box>
              );
            }

            return (
              <NavLink
                key={item.label}
                component={Link}
                href={item.href || "#"}
                label={item.label}
                leftSection={<Icon size={18} stroke={1.75} />}
                active={active}
                variant="light"
                color="tradexGold"
                styles={{
                  root: {
                    borderRadius: "8px",
                    height: "38px",
                    fontWeight: active ? 600 : 500,
                    color: active
                      ? isDark
                        ? "var(--mantine-color-tradexGold-4)"
                        : "var(--mantine-color-tradexGold-8)"
                      : undefined,
                  },
                }}
              />
            );
          })}
        </Stack>
      </ScrollArea>

      <Divider />

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
            <Text size="10px" c="dimmed" fw={600}>
              TRADEX ADMIN v1.0
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

export default Sidebar;
