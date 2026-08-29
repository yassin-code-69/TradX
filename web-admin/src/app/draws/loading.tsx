"use client";

import { Stack } from "@mantine/core";
import {
  PageHeaderSkeleton,
  StatCardSkeleton,
  TableSkeleton,
} from "@/components/common/Skeletons";

export default function DrawsLoading() {
  return (
    <Stack gap="lg">
      <PageHeaderSkeleton />
      <StatCardSkeleton count={4} />
      <TableSkeleton rows={6} cols={8} />
    </Stack>
  );
}
