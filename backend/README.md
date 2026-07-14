# Backend

The custom Node entry point owns both Next.js and `ws`; do not start it with `next dev` directly. Configuration is validated at startup. REST is under `/api/v1`, WebSocket is `/ws?token=<access-token>`, and the public diagnostic endpoint is `/api/v1/system/health`.

When accessing the development server through another LAN address or hostname, add it to the comma-separated `DEV_ALLOWED_ORIGINS` value in `.env`. Bare hosts and full URLs are accepted, for example `DEV_ALLOWED_ORIGINS=10.0.0.74,https://nashub.example.com`.

Use `npm run dev`, `npm run build`, `npm start`, `npm test`, and `npm run create-admin`. Back up the SQLite database with a WAL-aware SQLite backup tool while the service is running.
