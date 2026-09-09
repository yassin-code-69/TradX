"use client";

import { usePathname, useSearchParams } from "next/navigation";
import { Suspense, useCallback, useEffect, useRef, useState } from "react";

function ProgressBarInner() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [progress, setProgress] = useState(0);
  const [isVisible, setIsVisible] = useState(false);
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const hideTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const resetTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  const clearCompletionTimeouts = useCallback(() => {
    if (hideTimeoutRef.current) {
      clearTimeout(hideTimeoutRef.current);
      hideTimeoutRef.current = null;
    }
    if (resetTimeoutRef.current) {
      clearTimeout(resetTimeoutRef.current);
      resetTimeoutRef.current = null;
    }
  }, []);

  const clearAllTimers = useCallback(() => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    clearCompletionTimeouts();
  }, [clearCompletionTimeouts]);

  const start = useCallback(() => {
    clearAllTimers();
    setIsVisible(true);
    setProgress(15);

    timerRef.current = setInterval(() => {
      setProgress((prev) => {
        if (prev < 40) return prev + Math.random() * 15;
        if (prev < 70) return prev + Math.random() * 8;
        if (prev < 90) return prev + Math.random() * 3;
        return prev;
      });
    }, 120);
  }, [clearAllTimers]);

  const complete = useCallback(() => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    clearCompletionTimeouts();

    setProgress(100);
    hideTimeoutRef.current = setTimeout(() => {
      setIsVisible(false);
      resetTimeoutRef.current = setTimeout(() => {
        setProgress(0);
      }, 200);
    }, 250);
  }, [clearCompletionTimeouts]);

  // Complete progress on route change
  useEffect(() => {
    // Trigger on route or search params update
    void pathname;
    void searchParams;
    complete();
  }, [pathname, searchParams, complete]);

  // Clean up all timers on unmount
  useEffect(() => {
    return () => {
      clearAllTimers();
    };
  }, [clearAllTimers]);

  // Intercept all internal link clicks to immediately trigger progress bar
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      const target = (e.target as HTMLElement)?.closest("a");
      if (!target) return;

      const href = target.getAttribute("href");
      if (
        href?.startsWith("/") &&
        !href.startsWith("#") &&
        !target.hasAttribute("download") &&
        target.getAttribute("target") !== "_blank"
      ) {
        // Only start if navigating to a different URL
        const currentUrl = `${window.location.pathname}${window.location.search}`;
        if (href !== currentUrl) {
          start();
        }
      }
    };

    document.addEventListener("click", handleClick, { capture: true });
    return () => {
      document.removeEventListener("click", handleClick, { capture: true });
      clearAllTimers();
    };
  }, [start, clearAllTimers]);

  if (!isVisible && progress === 0) return null;

  return (
    <div
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        height: "3px",
        zIndex: 99999,
        pointerEvents: "none",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          height: "100%",
          width: `${progress}%`,
          background:
            "linear-gradient(90deg, #D97706 0%, #F59E0B 50%, #10B981 100%)",
          boxShadow:
            "0 0 14px rgba(245, 158, 11, 0.8), 0 0 6px rgba(16, 185, 129, 0.6)",
          transition:
            progress === 100
              ? "width 0.15s ease-out, opacity 0.25s ease-out"
              : "width 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
          opacity: isVisible ? 1 : 0,
          borderRadius: "0 2px 2px 0",
        }}
      />
    </div>
  );
}

export function TopProgressBar() {
  return (
    <Suspense fallback={null}>
      <ProgressBarInner />
    </Suspense>
  );
}

export default TopProgressBar;
