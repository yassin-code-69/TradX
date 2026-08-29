"use client";

import { ResultsView } from "@/components/results/ResultsView";

export default function PublishResultsPage() {
  return <ResultsView initialTab="ALL" autoOpenPublish={true} />;
}
