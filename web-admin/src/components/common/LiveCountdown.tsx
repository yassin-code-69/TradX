"use client";

import { Group, Text, useComputedColorScheme } from "@mantine/core";
import { IconClock } from "@tabler/icons-react";
import { memo, useSyncExternalStore } from "react";
import { formatTimeRemaining } from "@/lib/formatters";

// Shared singleton clock manager: single 1000ms timer shared across all countdown subscribers
let intervalId: ReturnType<typeof setInterval> | null = null;
let currentTick = Date.now();
const listeners = new Set<() => void>();

function startClock() {
  if (intervalId !== null) return;
  intervalId = setInterval(() => {
    currentTick = Date.now();
    listeners.forEach((listener) => {
      listener();
    });
  }, 1000);
}

function stopClock() {
  if (intervalId !== null) {
    clearInterval(intervalId);
    intervalId = null;
  }
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  if (listeners.size === 1) {
    startClock();
  }
  return () => {
    listeners.delete(listener);
    if (listeners.size === 0) {
      stopClock();
    }
  };
}

function getSnapshot() {
  return currentTick;
}

function getServerSnapshot() {
  return 0;
}

/**
 * Singleton clock hook synchronized to a global 1-second interval tick.
 * Automatically starts the interval on the first subscriber and cleans it up when zero subscribers remain.
 */
export function useSharedClock() {
  return useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
}

interface LiveCountdownProps {
  targetDate: string;
  showIcon?: boolean;
  prefix?: string;
}

export const LiveCountdown = memo(function LiveCountdown({
  targetDate,
  showIcon = true,
  prefix = "Closes in:",
}: LiveCountdownProps) {
  // Sync to centralized singleton clock
  useSharedClock();
  const remainingText = formatTimeRemaining(targetDate);
  const computedColorScheme = useComputedColorScheme("dark", {
    getInitialValueInEffect: true,
  });
  const isDark = computedColorScheme === "dark";

  return (
    <Group justify="space-between" wrap="nowrap" gap="xs">
      {prefix && (
        <Group gap={6} wrap="nowrap">
          {showIcon && (
            <IconClock
              size={15}
              color={isDark ? "#fad045" : "#d97706"}
              style={{ flexShrink: 0 }}
            />
          )}
          <Text size="xs" c="dimmed">
            {prefix}
          </Text>
        </Group>
      )}
      <Text
        size="xs"
        fw={700}
        ff="monospace"
        c={isDark ? "yellow.3" : "yellow.8"}
        className="font-tabular"
      >
        {remainingText}
      </Text>
    </Group>
  );
});

export default LiveCountdown;
