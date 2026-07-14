# Nas Hub

Nas Hub is a native-first monitoring platform for one Linux host. A Next.js/Node process collects system metrics into SQLite, evaluates watchdog rules, serves authenticated REST and WebSocket APIs, and powers the SwiftUI iPhone client.

## Run the backend

Prerequisites: Node.js 22+, npm, and Linux for production metric collection.

```bash
cd backend
cp .env.example .env
# Replace ACCESS_TOKEN_SECRET with: openssl rand -base64 48
npm install
npm run db:migrate
npm run create-admin
npm run dev
```

Production: set `NODE_ENV=production`, use a strong secret, then run `npm run build && npm start`. Put the process behind Caddy or nginx with HTTPS/WebSocket forwarding; do not expose an HTTP login on the internet. SQLite data is written under `backend/data` by default.

## Run the iOS app

1. Open `Nas Hub.xcodeproj` in Xcode 16 or newer.
2. Select the **Nas Hub** target and your development team under Signing & Capabilities.
3. Run on an iOS 18 simulator or device.
4. Enter the backend URL and administrator credentials. A physical phone uses the Linux machine's LAN address, not `localhost`.
5. For production, use an HTTPS URL and configure Push Notifications as described in [docs/push-notifications.md](docs/push-notifications.md).

The server URL is remembered in preferences; credentials are stored only in Keychain. Current limitations include a single local server, raw history rather than materialized rollups, no web account session, and an APNs mock until Apple credentials are provided. The next recommended task is production APNs delivery plus one-minute/hourly metric rollups and fully downsampled history queries.

