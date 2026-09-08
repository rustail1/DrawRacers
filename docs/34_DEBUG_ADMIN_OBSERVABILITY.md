# 34 — DEBUG, ADMIN & OBSERVABILITY
Статус: **DEVELOPER OPERATIONS v1.3.4**.

## Debug overlay (Studio/staging only)
Shows raceId/phase, local checkpoint, progress, shape point counts raw/simplified/physics, motor state, body velocity, respawn reason, authority mode, ping/server frame summary where available.

## Visual toggles
`ShowLegColliders`, `ShowLanePlane`, `ShowCheckpointZones`, `ShowTrackSockets`, `ShowBotIntent`, `ShowCameraTarget`.

## Test commands
Debug commands exist as developer-only module/UI, not public chat parsing: start heat, spawn N bots, force trackId, reset racer, grant test cosmetic in staging, simulate DataStore failure, malformed stroke test.

## Feature flags
Every risky rollout has config flag: ServerAuthorityMode, BotsEnabled, OfferEnabled, NewTrackPool, NewFTUEVariant. Flags have safe defaults.

## Logging
Structured prefix `[Race] [Data] [Net] [Monetization] [Analytics]`. Expected rejected client input is rate-limited logging, not console spam.

## Production monitoring
Creator Dashboard Error Report + Performance Dashboard + Analytics + Safety dashboard. Each release note records place version and config revision to correlate regressions.

Required custom operational counters/alerts: receipt retries/failures, duplicate receipt confirmations, profile load/save failures, profile serialized size warning, 8-player server-frame threshold failures, join-to-control timeout, shape build fallback. Threshold owners are `56/57`.
