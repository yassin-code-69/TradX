import { createTheme, type MantineColorsTuple } from "@mantine/core";

// Deep Navy brand palette (0=lightest, 9=darkest midnight navy)
export const tradexNavy: MantineColorsTuple = [
  "#F8FAFC", // 0 - slate 50
  "#F1F5F9", // 1 - slate 100
  "#E2E8F0", // 2 - slate 200
  "#CBD5E1", // 3 - slate 300
  "#94A3B8", // 4 - slate 400
  "#64748B", // 5 - slate 500
  "#334155", // 6 - slate 700
  "#1E293B", // 7 - slate 800
  "#0F172A", // 8 - slate 900
  "#070B14", // 9 - midnight navy
];

// Luxury Gold / Warm Amber accent palette
export const tradexGold: MantineColorsTuple = [
  "#FFFDF5", // 0
  "#FEF3C7", // 1
  "#FDE68A", // 2
  "#FCD34D", // 3
  "#FBBF24", // 4
  "#F59E0B", // 5 - amber 500
  "#D97706", // 6 - luxury gold / amber 600
  "#B45309", // 7 - deep gold / amber 700
  "#92400E", // 8
  "#78350F", // 9
];

// Deep Navy Dark Mode surface palette (0=text ... 8=background, 9=deepest)
export const tradexDark: MantineColorsTuple = [
  "#F8FAFC", // 0 - text in dark mode
  "#E2E8F0", // 1 - secondary text / high contrast
  "#CBD5E1", // 2 - dimmed text
  "#94A3B8", // 3 - muted text / placeholders
  "#334155", // 4 - subtle borders / highlights
  "#1E293B", // 5 - card & element borders
  "#17233D", // 6 - elevated backgrounds / hover
  "#0D1424", // 7 - card / modal surface
  "#070B14", // 8 - page background (deep midnight navy)
  "#04060C", // 9 - deepest black navy
];

// Success Emerald palette
export const tradexEmerald: MantineColorsTuple = [
  "#ECFDF5",
  "#D1FAE5",
  "#A7F3D0",
  "#6EE7B7",
  "#34D399",
  "#10B981",
  "#059669",
  "#047857",
  "#065F46",
  "#064E3B",
];

// Crimson Danger palette
export const tradexCrimson: MantineColorsTuple = [
  "#FEF2F2",
  "#FEE2E2",
  "#FECACA",
  "#FCA5A5",
  "#F87171",
  "#EF4444",
  "#DC2626",
  "#B91C1C",
  "#991B1B",
  "#7F1D1D",
];

export const theme = createTheme({
  primaryColor: "tradexGold",
  primaryShade: { light: 6, dark: 5 },
  white: "#FFFFFF",
  black: "#070B14",
  colors: {
    tradexNavy,
    tradexGold,
    dark: tradexDark,
    emerald: tradexEmerald,
    crimson: tradexCrimson,
  },
  fontFamily:
    "var(--font-geist-sans), 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
  fontFamilyMonospace:
    "var(--font-geist-mono), 'JetBrains Mono', 'Fira Code', monospace",
  headings: {
    fontFamily:
      "var(--font-geist-sans), 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
    fontWeight: "700",
    sizes: {
      h1: { fontSize: "28px", lineHeight: "1.3" },
      h2: { fontSize: "22px", lineHeight: "1.35" },
      h3: { fontSize: "18px", lineHeight: "1.4" },
      h4: { fontSize: "16px", lineHeight: "1.45" },
      h5: { fontSize: "14px", lineHeight: "1.5" },
      h6: { fontSize: "12px", lineHeight: "1.5" },
    },
  },
  defaultRadius: "md",
  cursorType: "pointer",
  other: {
    gold500: "#F59E0B",
    gold600: "#D97706",
    surfaceLight: "#F8FAFC",
    cardLight: "#FFFFFF",
    textLight: "#0F172A",
    borderLight: "#E2E8F0",
    surfaceDark: "#070B14",
    cardDark: "#0D1424",
    textDark: "#F8FAFC",
    borderDark: "#1E293B",
  },
  components: {
    Button: {
      defaultProps: {
        radius: "md",
      },
      styles: {
        root: {
          fontWeight: 600,
          letterSpacing: "0.01em",
          transition: "all 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
        },
      },
    },
    ActionIcon: {
      defaultProps: {
        radius: "md",
      },
      styles: {
        root: {
          transition: "all 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
        },
      },
    },
    Card: {
      defaultProps: {
        radius: "lg",
        withBorder: true,
        padding: "md",
      },
      styles: {
        root: {
          backgroundColor: "var(--surface-card, var(--mantine-color-default))",
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
          color: "var(--mantine-color-text)",
          backdropFilter: "blur(12px)",
          WebkitBackdropFilter: "blur(12px)",
          transition:
            "background-color 0.25s ease, border-color 0.25s ease, box-shadow 0.25s ease, transform 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
        },
      },
    },
    Paper: {
      defaultProps: {
        radius: "md",
      },
      styles: {
        root: {
          backgroundColor: "var(--surface-card, var(--mantine-color-default))",
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
          color: "var(--mantine-color-text)",
          transition: "background-color 0.25s ease, border-color 0.25s ease",
        },
      },
    },
    TextInput: {
      defaultProps: {
        radius: "md",
      },
      styles: {
        input: {
          backgroundColor: "var(--surface-card, var(--mantine-color-default))",
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
          color: "var(--mantine-color-text)",
          transition:
            "border-color 0.2s ease, box-shadow 0.2s ease, background-color 0.2s ease",
        },
      },
    },
    PasswordInput: {
      defaultProps: {
        radius: "md",
      },
      styles: {
        input: {
          backgroundColor: "var(--surface-card, var(--mantine-color-default))",
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
          color: "var(--mantine-color-text)",
          transition:
            "border-color 0.2s ease, box-shadow 0.2s ease, background-color 0.2s ease",
        },
      },
    },
    NumberInput: {
      defaultProps: {
        radius: "md",
      },
      styles: {
        input: {
          backgroundColor: "var(--surface-card, var(--mantine-color-default))",
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
          color: "var(--mantine-color-text)",
          fontVariantNumeric: "tabular-nums",
          transition:
            "border-color 0.2s ease, box-shadow 0.2s ease, background-color 0.2s ease",
        },
      },
    },
    Select: {
      defaultProps: {
        radius: "md",
      },
      styles: {
        input: {
          backgroundColor: "var(--surface-card, var(--mantine-color-default))",
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
          color: "var(--mantine-color-text)",
          transition:
            "border-color 0.2s ease, box-shadow 0.2s ease, background-color 0.2s ease",
        },
        dropdown: {
          backgroundColor:
            "var(--surface-card-elevated, var(--mantine-color-default))",
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
          boxShadow: "0 10px 30px -5px rgba(0, 0, 0, 0.3)",
        },
      },
    },
    Badge: {
      defaultProps: {
        radius: "sm",
      },
      styles: {
        root: {
          fontWeight: 700,
          textTransform: "uppercase",
          letterSpacing: "0.04em",
          fontVariantNumeric: "tabular-nums",
          transition:
            "background-color 0.2s ease, border-color 0.2s ease, color 0.2s ease",
        },
      },
    },
    Modal: {
      defaultProps: {
        radius: "lg",
        centered: true,
        overlayProps: {
          backgroundOpacity: 0.65,
          blur: 10,
        },
      },
      styles: {
        content: {
          backgroundColor:
            "var(--surface-card-elevated, var(--mantine-color-default))",
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
          borderWidth: "1px",
          borderStyle: "solid",
          boxShadow: "0 30px 60px -12px rgba(0, 0, 0, 0.45)",
          backdropFilter: "blur(16px)",
          WebkitBackdropFilter: "blur(16px)",
          transition: "background-color 0.25s ease, border-color 0.25s ease",
        },
        header: {
          backgroundColor: "transparent",
          borderBottom:
            "1px solid var(--surface-border, var(--mantine-color-default-border))",
          paddingBottom: "14px",
          transition: "border-color 0.25s ease",
        },
        title: {
          fontWeight: 700,
          fontSize: "16px",
          color: "var(--mantine-color-text)",
        },
        body: {
          paddingTop: "18px",
          color: "var(--mantine-color-text)",
        },
      },
    },
    Table: {
      defaultProps: {
        striped: true,
        highlightOnHover: true,
      },
      styles: {
        table: {
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
          color: "var(--mantine-color-text)",
        },
        thead: {
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
        },
        th: {
          color: "var(--mantine-color-dimmed)",
          fontWeight: 700,
          fontSize: "11px",
          textTransform: "uppercase",
          letterSpacing: "0.06em",
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
          padding: "12px 14px",
        },
        td: {
          borderColor:
            "var(--surface-border, var(--mantine-color-default-border))",
          padding: "12px 14px",
          fontSize: "13px",
          color: "var(--mantine-color-text)",
        },
      },
    },
  },
});

export default theme;
