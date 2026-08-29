"use client";

import { Card, SimpleGrid, Skeleton, Stack } from "@mantine/core";
import { PageHeaderSkeleton } from "@/components/common/Skeletons";

const SETTINGS_GATEWAY_KEYS = [
  "gateway_skel_1",
  "gateway_skel_2",
  "gateway_skel_3",
  "gateway_skel_4",
];

export default function SettingsLoading() {
  return (
    <Stack gap="lg">
      <PageHeaderSkeleton />

      <Skeleton height={40} width={340} radius="md" />

      <SimpleGrid cols={{ base: 1, md: 2 }} spacing="md">
        {SETTINGS_GATEWAY_KEYS.map((pmKey) => (
          <Card
            key={pmKey}
            p="md"
            radius="md"
            withBorder
            bg="var(--surface-card, var(--mantine-color-default))"
          >
            <Stack gap="sm">
              <Skeleton height={24} width="50%" radius="sm" />
              <Skeleton height={50} radius="md" />
              <Skeleton height={40} radius="md" />
              <Skeleton height={20} width="80%" radius="sm" />
            </Stack>
          </Card>
        ))}
      </SimpleGrid>
    </Stack>
  );
}
