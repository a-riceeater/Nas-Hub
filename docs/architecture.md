# Architecture

The custom HTTP server routes `/api/v1` to focused API services, `/ws` upgrades to the authenticated WebSocket hub, and all other traffic to Next.js. Auth uses Argon2id passwords, short-lived HS256 access JWTs, and rotating opaque refresh tokens whose SHA-256 digests are stored in SQLite.

`MetricCollector` performs a non-overlapping `systeminformation` sample, emits a live event, and periodically persists it. The WebSocket hub broadcasts subscribed events; the watchdog independently consumes the same event and maintains duration state, deduplicated active alerts, hysteresis-based recovery, and persistent history. Maintenance removes expired raw points. The schema already represents servers separately so remote agents can be introduced later.

On iOS, `AppState` coordinates repositories without putting network work in views. `APIClient` refreshes tokens, `KeychainStore` protects them, and `WebSocketManager` owns live reconnection. Dashboard cards observe the latest metric, Charts observes the bounded history array, and background transitions close the socket because APNs—not a background WebSocket—is the reliable alert channel.

