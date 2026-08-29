"use client";

import { Stack } from "@mantine/core";
import {
  PageHeaderSkeleton,
  StatCardSkeleton,
  TableSkeleton,
} from "@/components/common/Skeletons";

export default function UsersLoading() {
  return (
    <Stack gap="lg">
      <PageHeaderSkeleton />
      <StatCardSkeleton count={4} />
      <TableSkeleton rows={8} cols={7} />
    </Stack>
  );
}
