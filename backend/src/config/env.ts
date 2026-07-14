import { z } from "zod";

const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3000), HOST: z.string().default("0.0.0.0"),
  DATABASE_PATH: z.string().default("./data/server-monitor.sqlite"),
  ACCESS_TOKEN_SECRET: z.string().min(32).default("development-only-secret-change-me-now"),
  ACCESS_TOKEN_TTL_MINUTES: z.coerce.number().positive().default(15),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().positive().default(30),
  METRIC_COLLECTION_INTERVAL_MS: z.coerce.number().min(500).default(1000),
  METRIC_PERSIST_INTERVAL_MS: z.coerce.number().min(1000).default(5000),
  METRIC_RAW_RETENTION_HOURS: z.coerce.number().positive().default(24),
  APNS_ENABLED: z.enum(["true", "false"]).default("false").transform(v => v === "true"),
  APNS_ENVIRONMENT: z.enum(["development", "production"]).default("development"),
  APNS_TEAM_ID: z.string().optional(), APNS_KEY_ID: z.string().optional(),
  APNS_BUNDLE_ID: z.string().optional(), APNS_PRIVATE_KEY_PATH: z.string().optional(),
  TRUSTED_ORIGINS: z.string().default("http://localhost:3000").transform(v => v.split(",").map(s => s.trim()))
});
export type Config = z.infer<typeof schema>;
export const config = schema.parse(process.env);

