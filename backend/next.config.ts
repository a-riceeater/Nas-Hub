import type { NextConfig } from "next";

const configuredDevOrigins = process.env.DEV_ALLOWED_ORIGINS
  ?.split(",")
  .map((origin) => origin.trim())
  .filter(Boolean) ?? [];

const config: NextConfig = {
  poweredByHeader: false,
  allowedDevOrigins: ["10.0.0.74", ...configuredDevOrigins],
};

export default config;
