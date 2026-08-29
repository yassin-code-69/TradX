"use client";

import { Stack } from "@mantine/core";
import {
  PageHeaderSkeleton,
  StatCardSkeleton,
  TableSkeleton,
} from "@/components/common/Skeletons";

export default function GlobalLoading() {
  return (
    <Stack gap="xl">
      <PageHeaderSkeleton />
      <StatCardSkeleton count={4} />
      <TableSkeleton rows={6} cols={6} />
    </Stack>
  );
}
