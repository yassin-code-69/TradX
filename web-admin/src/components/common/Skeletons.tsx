"use client";

import { Card, Group, SimpleGrid, Skeleton, Stack, Table } from "@mantine/core";

const SKELETON_COL_KEYS = [
  "col_alpha",
  "col_beta",
  "col_gamma",
  "col_delta",
  "col_epsilon",
  "col_zeta",
  "col_eta",
  "col_theta",
  "col_iota",
  "col_kappa",
];

const SKELETON_ROW_KEYS = [
  "row_1",
  "row_2",
  "row_3",
  "row_4",
  "row_5",
  "row_6",
  "row_7",
  "row_8",
  "row_9",
  "row_10",
  "row_11",
  "row_12",
];

export function TableSkeleton({
  rows = 5,
  cols = 6,
}: {
  rows?: number;
  cols?: number;
}) {
  const visibleCols = SKELETON_COL_KEYS.slice(0, cols);
  const visibleRows = SKELETON_ROW_KEYS.slice(0, rows);

  return (
    <Card
      p="md"
      radius="md"
      withBorder
      bg="var(--surface-card, var(--mantine-color-default))"
    >
      <Stack gap="md">
        <Group justify="space-between">
          <Skeleton height={34} width={280} radius="md" />
          <Group gap="xs">
            <Skeleton height={34} width={130} radius="md" />
            <Skeleton height={34} width={130} radius="md" />
          </Group>
        </Group>

        <Table verticalSpacing="sm">
          <Table.Thead>
            <Table.Tr>
              {visibleCols.map((colKey) => (
                <Table.Th key={colKey}>
                  <Skeleton height={14} width="70%" radius="sm" />
                </Table.Th>
              ))}
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {visibleRows.map((rowKey) => (
              <Table.Tr key={rowKey}>
                {visibleCols.map((colKey, c) => (
                  <Table.Td key={`${rowKey}_${colKey}`}>
                    <Skeleton
                      height={18}
                      width={c === 0 ? "85%" : "60%"}
                      radius="sm"
                    />
                  </Table.Td>
                ))}
              </Table.Tr>
            ))}
          </Table.Tbody>
        </Table>

        <Group justify="space-between" pt="xs">
          <Skeleton height={16} width={180} radius="sm" />
          <Skeleton height={30} width={220} radius="md" />
        </Group>
      </Stack>
    </Card>
  );
}

const STAT_CARD_KEYS = [
  "stat_kpi_1",
  "stat_kpi_2",
  "stat_kpi_3",
  "stat_kpi_4",
  "stat_kpi_5",
  "stat_kpi_6",
];

export function StatCardSkeleton({ count = 4 }: { count?: number }) {
  const visibleCards = STAT_CARD_KEYS.slice(0, count);

  return (
    <SimpleGrid cols={{ base: 1, sm: 2, lg: count }} spacing="md">
      {visibleCards.map((cardKey) => (
        <Card
          key={cardKey}
          p="md"
          radius="md"
          withBorder
          bg="var(--surface-card, var(--mantine-color-default))"
        >
          <Group justify="space-between" mb="xs">
            <Skeleton height={14} width="50%" radius="sm" />
            <Skeleton height={28} width={28} radius="md" />
          </Group>
          <Skeleton height={28} width="75%" radius="sm" my={8} />
          <Skeleton height={12} width="40%" radius="sm" />
        </Card>
      ))}
    </SimpleGrid>
  );
}

export function PageHeaderSkeleton() {
  return (
    <Group justify="space-between" align="flex-end">
      <Stack gap={6}>
        <Skeleton height={12} width={160} radius="sm" />
        <Skeleton height={26} width={260} radius="sm" />
        <Skeleton height={14} width={380} radius="sm" />
      </Stack>
      <Group gap="sm">
        <Skeleton height={36} width={120} radius="md" />
        <Skeleton height={36} width={140} radius="md" />
      </Group>
    </Group>
  );
}
