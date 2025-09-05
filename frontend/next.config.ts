import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */ // next.config.js
  // next.config.js

  images: {
    // domains: ["assets.cticket.vn"],
    remotePatterns: [
      {
        protocol: "https",
        hostname: "assets.cticket.vn",
        port: "",
        pathname: "/**",
      },
    ],
  },
};

export default nextConfig;
