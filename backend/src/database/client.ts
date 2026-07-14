import Database from "better-sqlite3";
import { drizzle } from "drizzle-orm/better-sqlite3";
import { dirname, resolve } from "node:path";
import { mkdirSync } from "node:fs";
import { config } from "../config/env.js";
import * as schema from "./schema.js";

const path = resolve(config.DATABASE_PATH); mkdirSync(dirname(path), {recursive:true});
export const sqlite = new Database(path);
sqlite.pragma("journal_mode = WAL"); sqlite.pragma("foreign_keys = ON"); sqlite.pragma("busy_timeout = 5000");
export const db = drizzle(sqlite, {schema});

export function migrate(): void {
  sqlite.exec(`
  CREATE TABLE IF NOT EXISTS users(id TEXT PRIMARY KEY,username TEXT NOT NULL UNIQUE,email TEXT NOT NULL UNIQUE,password_hash TEXT NOT NULL,role TEXT NOT NULL,setup_completed INTEGER NOT NULL DEFAULT 0,created_at INTEGER NOT NULL,updated_at INTEGER NOT NULL,disabled INTEGER NOT NULL DEFAULT 0);
  CREATE TABLE IF NOT EXISTS sessions(id TEXT PRIMARY KEY,user_id TEXT NOT NULL REFERENCES users(id),refresh_token_hash TEXT NOT NULL,device_description TEXT,created_at INTEGER NOT NULL,expires_at INTEGER NOT NULL,revoked_at INTEGER,last_used_at INTEGER NOT NULL);
  CREATE TABLE IF NOT EXISTS servers(id TEXT PRIMARY KEY,name TEXT NOT NULL,hostname TEXT NOT NULL,operating_system TEXT NOT NULL,architecture TEXT NOT NULL,version TEXT NOT NULL,last_seen_at INTEGER,created_at INTEGER NOT NULL);
  CREATE TABLE IF NOT EXISTS metric_samples(id INTEGER PRIMARY KEY AUTOINCREMENT,server_id TEXT NOT NULL REFERENCES servers(id),timestamp INTEGER NOT NULL,resolution TEXT NOT NULL DEFAULT 'raw',public_ipv4 TEXT,cpu_percent REAL,system_utilization REAL,per_core_json TEXT,load1 REAL,load5 REAL,load15 REAL,ram_total INTEGER,ram_used INTEGER,ram_available INTEGER,ram_percent REAL,swap_total INTEGER,swap_used INTEGER,disk_total INTEGER,disk_used INTEGER,disk_available INTEGER,disk_percent REAL,disk_read_bps REAL,disk_write_bps REAL,network_rx_bps REAL,network_tx_bps REAL,uptime REAL,process_count INTEGER,temperature REAL,boot_time INTEGER);
  CREATE INDEX IF NOT EXISTS metrics_server_time_idx ON metric_samples(server_id,timestamp,resolution);
  CREATE TABLE IF NOT EXISTS watchdog_rules(id TEXT PRIMARY KEY,server_id TEXT NOT NULL,metric TEXT NOT NULL,severity TEXT NOT NULL,warning_threshold REAL,critical_threshold REAL NOT NULL,recovery_threshold REAL NOT NULL,required_duration INTEGER NOT NULL,cooldown INTEGER NOT NULL,enabled INTEGER NOT NULL DEFAULT 1,created_at INTEGER NOT NULL,updated_at INTEGER NOT NULL);
  CREATE TABLE IF NOT EXISTS alerts(id TEXT PRIMARY KEY,server_id TEXT NOT NULL,rule_id TEXT NOT NULL,severity TEXT NOT NULL,status TEXT NOT NULL,title TEXT NOT NULL,message TEXT NOT NULL,metric_value REAL,threshold_value REAL,triggered_at INTEGER NOT NULL,acknowledged_at INTEGER,resolved_at INTEGER,notification_status TEXT NOT NULL DEFAULT 'pending');
  CREATE INDEX IF NOT EXISTS alerts_status_idx ON alerts(status,triggered_at);
  CREATE TABLE IF NOT EXISTS push_devices(id TEXT PRIMARY KEY,user_id TEXT NOT NULL,token TEXT NOT NULL UNIQUE,environment TEXT NOT NULL,topic TEXT NOT NULL,device_name TEXT,last_seen_at INTEGER NOT NULL,enabled INTEGER NOT NULL DEFAULT 1);
  `);
  const userColumns = sqlite.pragma("table_info(users)") as Array<{name:string}>;
  if (!userColumns.some(column => column.name === "setup_completed")) {
    sqlite.exec("ALTER TABLE users ADD COLUMN setup_completed INTEGER NOT NULL DEFAULT 0");
  }
  const metricColumns=sqlite.pragma("table_info(metric_samples)") as Array<{name:string}>;
  if(!metricColumns.some(column=>column.name==="public_ipv4"))sqlite.exec("ALTER TABLE metric_samples ADD COLUMN public_ipv4 TEXT");
  if(!metricColumns.some(column=>column.name==="system_utilization"))sqlite.exec("ALTER TABLE metric_samples ADD COLUMN system_utilization REAL");
}
