import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // SPA rewrites for login-free member statement deep links
  async rewrites() {
    return [
      {
        source: "/statement/:token",
        destination: "/statement/:token",
      },
    ];
  },
};

export default nextConfig;
