import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  reactCompiler: true,
  experimental: {
    optimizePackageImports: [
      "@mantine/core",
      "@mantine/hooks",
      "@mantine/dates",
      "@mantine/notifications",
      "@mantine/modals",
      "@tabler/icons-react",
    ],
  },
};

export default nextConfig;
