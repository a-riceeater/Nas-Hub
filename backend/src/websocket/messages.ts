import { z } from "zod";
import { metricSchema } from "../metrics/types.js";
export const clientMessageSchema=z.discriminatedUnion("type",[z.object({version:z.literal(1),type:z.literal("subscribe"),serverId:z.string()}),z.object({version:z.literal(1),type:z.literal("ping")})]);
export const metricMessageSchema=z.object({version:z.literal(1),type:z.literal("metrics.update"),timestamp:z.string(),serverId:z.string(),data:metricSchema});

