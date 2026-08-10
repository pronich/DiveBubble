import type { NextConfig } from "next";
import { APP_LINKS_LIVE, APP_STORE_URL, GOOGLE_PLAY_URL } from "./src/config/appLaunch";

const nextConfig: NextConfig = {
  // /app_launch is the universal QR-code target: same URL on every printed/shared code,
  // routed to the right store by User-Agent at request time so it never needs reprinting.
  // No UA match (desktop, unknown bots) falls through to app_launch/page.tsx. Gated behind
  // APP_LINKS_LIVE so the redirect only goes live once both stores are ready together.
  async redirects() {
    if (!APP_LINKS_LIVE) return [];

    return [
      {
        source: "/app_launch",
        has: [{ type: "header", key: "user-agent", value: ".*(iPhone|iPad|iPod).*" }],
        destination: APP_STORE_URL,
        permanent: false,
      },
      {
        source: "/app_launch",
        has: [{ type: "header", key: "user-agent", value: ".*Android.*" }],
        destination: GOOGLE_PLAY_URL,
        permanent: false,
      },
    ];
  },
};

export default nextConfig;
