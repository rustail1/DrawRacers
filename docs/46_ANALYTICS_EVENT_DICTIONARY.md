# 46 — ANALYTICS EVENT DICTIONARY
Статус: **CANONICAL INSTRUMENTATION CONTRACT v1.3.4**.

> This file owns exact custom event names. `10` owns questions/KPIs and must not create a second event-name list. Server emits authoritative product events in a published experience where required by Roblox analytics. Keep event taxonomy bounded; current platform limits must be rechecked before release.

## Standard custom fields
Use only when needed and cardinality remains bounded:
- `DeviceClass`;
- `ExperimentVersion`;
- `PlayerSegment`.

Track/piece identifiers should be values/controlled fields only when supported by the current event/field plan; never send UserId as a custom dimension.

## FTUE funnel — exact names
`FTUE_RaceStarted → FTUE_FirstStrokeApplied → FTUE_FirstMovementAchieved → FTUE_FirstRedraw → FTUE_KeyObstacleCleared → FTUE_Finished → FTUE_NextRaceStarted`.

Each first-time step fires once/player for the relevant onboarding attempt/version.

## Core custom events — exact names
- `StrokeApplied` — value=physicsPointCount; bounded context fields only.
- `StrokeRejected` — reject reason category.
- `RacerStuck` — piece/context.
- `CheckpointPassed` — ordered checkpoint index/context.
- `RaceFinished` — placement, finishState, track context.
- `Respawned` — reason.
- `ResultsViewed` — result state.
- `RematchStarted` — delay bucket/source CTA.
- `BotHeat` — humanCount/botCount buckets.

`StrokeResult` is a **network remote**, not an analytics event. Do not use the old `StrokeAccepted` name.

## Economy
Economy source reasons: `RaceReward`, `Milestone`, `Event`, `Product`. Sink reason: `CosmeticPurchase`. Emit only after successful authoritative mutation. Use Roblox economy events where suitable; custom events do not duplicate the same transaction without a decision need.

## Monetization funnel — exact names
`OfferEligible → OfferShown → ProductPrompted → PurchaseGranted → EquippedAfterPurchase → NextRaceWithItem`.

Failure/operations:
- `PurchasePromptFailed` only for actionable product telemetry;
- receipt retry/duplicate counters are operations/debug data per `34/56` and must not double-count revenue/economy grants.

## Discovery/session linkage
Acquisition/PTR is platform-level. Downstream custom funnel uses first draw/movement/finish/next-race steps so a high-PTR creative cannot be declared a winner while product engagement collapses.

## Performance/support
Do not emit per-frame analytics. Performance lives primarily in Performance Dashboard/MicroProfiler. Game-specific incident event allowed: `ShapeBuildFallback`, rate-limited/bounded.

## Ownership rule
Every event maps to a decision in `10`. Any event with no decision owner is removed. Any exact-name change updates this file first, then instrumentation/tests.


## Queue / spectator diagnostics
- `QueueIntent` — `{source:"ARRIVAL"|"RESULTS", action:"JOIN"|"LEAVE", resultsVisibleMs?, heatId}`; source ARRIVAL is server-created.
- `SpectatorEntered` — `{reason:"LATE_JOIN"|"WAIT_NEXT", queued:boolean, heatId}`.
These diagnose rematch/late-join UX; they do not become authoritative race state.

## LiveOps exposure
Every enabled `76` event includes `LiveEventId`/exposure version on relevant session/race/economy custom fields where platform field limits permit; do not create one bespoke analytics event per event name.
