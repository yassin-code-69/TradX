/**
 * Financial and Date formatting utilities for TRADEX Web Admin.
 * Authority: All financial values in TRADEX are minor units (Poisha, 1 BDT = 100 Poisha).
 */

export function minorToBDT(minor: number | string | bigint): number {
  return Number(minor) / 100;
}

export function bdtToMinor(bdt: number | string): number {
  return Math.round(Number(bdt) * 100);
}

export function formatBDT(
  minor?: number | string | bigint | null,
  options?: { compact?: boolean },
): string {
  if (minor === undefined || minor === null) {
    return "৳0.00";
  }
  const bdt = minorToBDT(minor);
  if (options?.compact && Math.abs(bdt) >= 1_000_000) {
    return `৳${(bdt / 1_000_000).toFixed(2)}M`;
  }
  if (options?.compact && Math.abs(bdt) >= 1_000) {
    return `৳${(bdt / 1_000).toFixed(1)}K`;
  }
  return `৳${bdt.toLocaleString("en-BD", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`;
}

export function formatNumber(num: number): string {
  return (num || 0).toLocaleString("en-US");
}

export function formatDateTime(isoString: string): string {
  if (!isoString) return "-";
  try {
    const d = new Date(isoString);
    return d.toLocaleString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      hour12: true,
    });
  } catch {
    return isoString;
  }
}

export function formatDateOnly(isoString: string): string {
  if (!isoString) return "-";
  try {
    const d = new Date(isoString);
    return d.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  } catch {
    return isoString;
  }
}

export function formatTimeOnly(isoString: string): string {
  if (!isoString) return "-";
  try {
    const d = new Date(isoString);
    return d.toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: true,
    });
  } catch {
    return isoString;
  }
}

export function formatTimeAgo(isoString: string): string {
  if (!isoString) return "-";
  try {
    const diffMs = Date.now() - new Date(isoString).getTime();
    const diffSec = Math.floor(diffMs / 1000);
    if (diffSec < 60) return `${diffSec}s ago`;
    const diffMin = Math.floor(diffSec / 60);
    if (diffMin < 60) return `${diffMin}m ago`;
    const diffHr = Math.floor(diffMin / 60);
    if (diffHr < 24) return `${diffHr}h ago`;
    const diffDays = Math.floor(diffHr / 24);
    return `${diffDays}d ago`;
  } catch {
    return isoString;
  }
}

export function formatTimeRemaining(targetIso: string): string {
  if (!targetIso) return "00:00:00";
  const target = new Date(targetIso).getTime();
  const now = Date.now();
  const diff = target - now;

  if (diff <= 0) return "Closed";

  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((diff % (1000 * 60)) / 1000);

  if (days > 0) {
    return `${days}d ${hours.toString().padStart(2, "0")}h ${minutes.toString().padStart(2, "0")}m`;
  }
  return `${hours.toString().padStart(2, "0")}h ${minutes.toString().padStart(2, "0")}m ${seconds.toString().padStart(2, "0")}s`;
}

export function padLotteryNumber(num: string | number, length: number): string {
  return String(num || "").padStart(length, "0");
}

export function getStatusColor(status: string): string {
  switch (status.toUpperCase()) {
    case "ACTIVE":
    case "APPROVED":
    case "COMPLETED":
    case "OPEN":
    case "VERIFIED":
    case "WON":
      return "teal";
    case "PENDING":
    case "PROCESSING":
    case "SCHEDULED":
      return "yellow";
    case "SUSPENDED":
      return "orange";
    case "REJECTED":
    case "BLOCKED":
    case "FAILED":
    case "CANCELLED":
    case "LOST":
      return "red";
    default:
      return "gray";
  }
}

export function getDrawTypeColor(type: string): string {
  switch (type.toUpperCase()) {
    case "MEGA":
      return "yellow";
    case "DAILY":
      return "teal";
    case "HOURLY":
      return "blue";
    default:
      return "gray";
  }
}

export function getDrawStatusColor(status: string): string {
  return getStatusColor(status);
}

export function getTicketStatusColor(status: string): string {
  return getStatusColor(status);
}
