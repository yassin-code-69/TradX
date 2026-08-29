"use client";

import { TicketsView } from "@/components/tickets/TicketsView";

export default function ActiveTicketsPage() {
  return <TicketsView filter="ACTIVE" />;
}
