import pino from "pino";
import { config } from "../config/env.js";
export const log = pino(config.NODE_ENV === "development" ? { transport: { target: "pino-pretty" } } : {});

