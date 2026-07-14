import type { NextConfig } from "next";

function normalizeDevOrigin(value: string): string {
  const trimmed = value.trim();
  if (!trimmed.includes("://")) return trimmed.replace(/\/$/, "");
  try {
    return new URL(trimmed).host;
  } catch {
    return trimmed;
  }
}

const configuredDevOrigins = process.env.DEV_ALLOWED_ORIGINS
  ?.split(",")
  .map(normalizeDevOrigin)
  .filter(Boolean) ?? [];

const config: NextConfig = {
  poweredByHeader: false,
  allowedDevOrigins: ["10.0.0.74", "nashub.ehomeonline.xyz", ...configuredDevOrigins],
};

export default config;
