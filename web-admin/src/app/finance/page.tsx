import { Center, Loader } from "@mantine/core";
import { Suspense } from "react";
import { FinanceView } from "@/components/finance/FinanceView";

export default function FinancePage() {
  return (
    <Suspense
      fallback={
        <Center h={400}>
          <Loader color="yellow" />
        </Center>
      }
    >
      <FinanceView />
    </Suspense>
  );
}
