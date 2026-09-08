# 27 — ROBLOX PLATFORM SNAPSHOT — 2026-09

Назначение: зафиксировать платформенные предпосылки, на которые опирается архитектура. Это **не вечный source of truth API** — перед реализацией чувствительной платформенной функции разработчик должен перепроверить актуальную Creator Hub документацию.

## Confirmed relevant platform capabilities

### Server Authority
- Full release announced July 9, 2026.
- `Workspace.AuthorityMode` exists and accepts `Enum.AuthorityMode.Server` / `Automatic` in current API reference.
- Product architecture therefore targets server-authoritative competitive racer physics, validated during M1.

### Network ownership/security
- Roblox distributed physics may assign unanchored assembly ownership to clients in automatic mode.
- Client-owned physics carries security risk; critical movement must be validated and server authority is preferred for this competitive racer.

### Client/server boundary
- Every client-triggered server action must validate context/permission, type/value bounds and rate.
- This directly applies to `SubmitStroke`, equip requests and requeue requests.

### Physics
- Roblox supports rigid-body assemblies, constraints/motors and collision filtering.
- This is sufficient for the chosen `welded leg assembly + HingeConstraint motor` architecture.

### Remote communication
- RemoteEvents are appropriate for discrete one-way requests/events.
- UnreliableRemoteEvents exist for non-critical continuously changing data, but the project does not use them unless profiling proves a need.

### Studio testing
- Studio supports client/server view and multi-client server tests; mandatory from M1.

### Analytics
- Roblox supports economy, funnel and custom events through AnalyticsService.
- Current docs state up to 3 custom fields; custom events are sent from server in published games.

### Persistence
- DataStoreService/UpdateAsync remain the base platform primitive for persistent state. The project wraps persistent writes behind one PlayerDataService.

## Architecture consequences
1. Server decides race/finish/reward.
2. Client sends bounded stroke intent.
3. Physical motion is not replicated by custom per-frame reliable CFrame remotes.
4. Analytics gateway is server-side.
5. Published/private test environment is required for some platform behavior validation.
6. Before M1 and before monetization release, re-check current Roblox docs because platform APIs/policies can change.

## Official sources checked for this snapshot
- Roblox Creator Hub: Network ownership, movement validation, and physics.
- Roblox Creator Hub: Securing the client-server boundary.
- Roblox Creator Hub: Physics / Assemblies.
- Roblox Creator Hub: Remote events and callbacks.
- Roblox Creator Hub: Studio testing modes.
- Roblox Creator Hub: Analytics event types/custom events.
- Roblox Creator Hub: Data stores.
- Roblox Developer Forum: Full Release — Server Authority, July 9, 2026.


## Verification notes / provenance
Current Creator Hub remains source of truth. Performance target uses Roblox default 60 FPS/16.67ms frame context and requires profiling/monitoring; DataStore calls can fail and must be wrapped/reconciled; UI should be adaptive/mobile-first; localization supports automatic translation; AnalyticsService events are server-side for published experiences; safety guidance explicitly recommends limiting reach/lifetime of player-created content, which informs `39_PLAYER_SAFETY_DRAWING_MODERATION.md`.
