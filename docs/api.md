# API

All successful REST responses are `{ "data": ... }`; failures are `{ "error": { "code", "message" } }`. Send `Authorization: Bearer <accessToken>` except for login, refresh, and system health.

- `POST /api/v1/auth/login` — `{identifier,password,deviceDescription?}`
- `PATCH /api/v1/auth/me` — update username/email and optionally password with the current password
- `POST /api/v1/setup` — complete first-login setup and assign the local server name
- `POST /api/v1/auth/refresh` and `/logout` — `{refreshToken}`
- `GET /api/v1/auth/me`, `/servers`, `/servers/local/health`
- `GET /api/v1/servers/local/metrics/current`
- `GET /api/v1/servers/local/metrics/history?start=<ms>&end=<ms>&maxPoints=300`
- `GET /api/v1/alerts`; `POST /api/v1/alerts/:id/acknowledge`
- `GET /api/v1/watchdog/rules`
- `POST /api/v1/push/devices`
- `GET /api/v1/system/health`

Connect to `/ws?token=<accessToken>`, then send `{"version":1,"type":"subscribe","serverId":"local"}`. Live messages use `{"version":1,"type":"metrics.update","timestamp":"ISO-8601","serverId":"local","data":{...}}`. Clients must reject unknown protocol versions, respond to transport ping/pong, reconnect with backoff, refresh REST state after reconnect, and keep rendered history bounded.
