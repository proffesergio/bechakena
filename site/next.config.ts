import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Keep resolution identical in the checkout and the source-only submission.
  turbopack: { root: __dirname },
  output: "export",
  trailingSlash: true,
  images: { unoptimized: true },
  poweredByHeader: false,
};

export default nextConfig;
