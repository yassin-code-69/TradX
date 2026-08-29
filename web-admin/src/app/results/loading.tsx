"use client";

import { Stack } from "@mantine/core";
import {
  PageHeaderSkeleton,
  StatCardSkeleton,
  TableSkeleton,
} from "@/components/common/Skeletons";

export default function ResultsLoading() {
  return (
    <Stack gap="lg">
      <PageHeaderSkeleton />
      <StatCardSkeleton count={4} />
      <TableSkeleton rows={6} cols={9} />
    </Stack>
  );
}
