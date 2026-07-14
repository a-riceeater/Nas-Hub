# Development plan

## Completed foundation

- Custom Next.js/Node server, strict TypeScript, validated environment, structured logs, SQLite WAL schema
- Argon2id administrator/login flow, rotating hashed refresh sessions, revocation, generic failures, rate limiting
- Local collection, REST current/history/health, authenticated versioned WebSocket stream
- Default duration/hysteresis watchdog rules, deduplication, acknowledgment, automatic resolution
- SwiftUI login, Keychain tokens, refresh-capable API client, reconnecting WebSocket, live dashboard, bounded CPU chart, alerts and settings
- Push permission/device-token hooks and backend push-device schema

## Next

1. Add APNs JWT/HTTP2 provider and feed watchdog create/recovery events to it.
2. Materialize one-minute and one-hour aggregates and choose resolution by time range.
3. Complete watchdog rules (missing metrics, load/core ratio, disk bytes/growth, temperature) and APIs.
4. Add integration tests against a temporary SQLite database and iOS protocol mocks.
5. Add multi-server authorization before remote agents.

