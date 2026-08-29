"use client";

import { Card, SimpleGrid, Skeleton, Stack } from "@mantine/core";
import {
  PageHeaderSkeleton,
  StatCardSkeleton,
  TableSkeleton,
} from "@/components/common/Skeletons";

const PREVIEW_DRAW_KEYS = ["draw_skel_1", "draw_skel_2", "draw_skel_3"];

export default function DashboardLoading() {
  return (
    <Stack gap="xl">
      <PageHeaderSkeleton />
      <StatCardSkeleton count={6} />

      {/* Live active draws preview skeleton */}
      <SimpleGrid cols={{ base: 1, md: 3 }} spacing="md">
        {PREVIEW_DRAW_KEYS.map((drawKey) => (
          <Card
            key={drawKey}
            p="lg"
            radius="md"
            withBorder
            bg="var(--surface-card, var(--mantine-color-default))"
          >
            <Stack gap="sm">
              <Skeleton height={20} width="60%" radius="sm" />
              <Skeleton height={48} radius="md" />
              <Skeleton height={16} width="80%" radius="sm" />
              <Skeleton height={30} radius="md" mt="xs" />
            </Stack>
          </Card>
        ))}
      </SimpleGrid>

      {/* Queues and Tables */}
      <SimpleGrid cols={{ base: 1, lg: 2 }} spacing="lg">
        <TableSkeleton rows={4} cols={4} />
        <TableSkeleton rows={4} cols={4} />
      </SimpleGrid>

      <TableSkeleton rows={5} cols={7} />
    </Stack>
  );
}
