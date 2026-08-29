"use client";

import { UsersView } from "@/components/users/UsersView";

export default function BlockedUsersPage() {
  return <UsersView filter="BLOCKED" />;
}
