# 57 — RELEASE PERFORMANCE & DEVICE MATRIX
Статус: **OBJECTIVE PERFORMANCE ACCEPTANCE CONTRACT v1.3.4**.

These are project release thresholds, not Roblox platform limits. Exact model substitution is allowed only with a recorded device of the same or weaker class; a powerful desktop cannot substitute for a mobile gate.

## Minimum reference matrix
| Class | Reference device / equivalent | Required stage |
|---|---|---|
| Android low | Samsung Galaxy A15 4G, 4 GB RAM or demonstrably equivalent/weaker supported Android | M2 + pre-release |
| Android mid | Samsung Galaxy A35 5G, 6 GB or equivalent | M2 + pre-release |
| iOS low | iPhone 11 | pre-release |
| iOS mid | iPhone 13 / SE-class equivalent or stronger same generation class | pre-release |
| Windows low | 4-core laptop CPU around i5-8250U class, 8 GB RAM, Intel UHD 620-class iGPU | M2 + pre-release |
| Dev/mid desktop | current development PC | every milestone, **not** a substitute for constrained devices |

If an exact reference model is unavailable, record model, RAM, SoC/GPU, OS and why it is equivalent. At least one real Android and one real iOS device are required before PROD release.

## Client frame-time gates during an active 8-racer heat
Measure after a warm-up heat, with full baseline UI/VFX and worst allowed leg complexity.
- Android low / Windows low: **p95 frame time <=33.3 ms**; no sustained >50 ms period longer than 2 seconds attributable to the game.
- Android mid / iOS low: **p95 <=25 ms**.
- iOS mid / dev-mid desktop: target **p95 <=20 ms**.
- Any reproducible freeze >500 ms during valid redraw/race flow is a blocker.

## Server gate
8-racer worst-case 30-heat soak:
- p95 server frame/step time <=20 ms where measurable;
- no sustained >33.3 ms interval longer than 2 seconds caused by Draw Racers systems;
- no finish/checkpoint divergence;
- no monotonic instance/memory growth.

## Redraw/network responsiveness
- local stroke preview begins same frame/next rendered frame; no network round-trip needed for preview;
- shape submit→authoritative `StrokeResult` **p95 <=250 ms** in a 100 ms simulated RTT test;
- at 200 ms simulated RTT, redraw may be slower but must not freeze camera/input and must preserve atomic old-shape-until-accept behavior;
- stale/rejected request never removes the current valid shape.

## Memory / leak gate
Run 30 heats without server restart. Ignore first 5 warm-up heats. Across heats 6–30:
- no monotonic growth trend from orphan racers/legs/connections/TrackRuntime;
- end-of-soak live-instance count returns to a stable band after each reset;
- memory growth attributable to game systems should remain <=20% from the post-warm-up baseline. If tooling shows a clear positive leak slope even below 20%, fail and investigate.

## Join/load + place-routing gate
Published two-place STAGING (`23/41`), cold client, normal broadband/Wi-Fi:
- **new profile:** experience join in EntryFTUEPlace → first controllable/drawable T06 state target p95 <=10 s; **release blocker >15 s** unless an independently confirmed platform incident explains the sample;
- **returning completed profile:** experience join in EntryFTUEPlace → controllable RacePlace state target p95 <=12 s; **release blocker >18 s**;
- direct RacePlace first-timer edge case must redirect to EntryFTUEPlace without ever entering a public roster;
- successful FTUE finish → RacePlace transition must not duplicate rewards/tutorial grants even across teleport retry;
- no giant lobby preload or fake splash delay may hide a failure.

## Error/reliability gate
- session lease acquisition/handoff from `31` must pass the persistence concurrency matrix in `24`;
- zero unresolved P0/P1;
- zero recurring server/client exception on the core race path in the 30-heat soak;
- soft-launch game-attributable join/load failure target <2% once >=200 sessions are available; sustained >=2% requires investigation before acquisition scale.

## Physics budget gate
- default <=14 collider segments/leg; normal target 8–12;
- 8 racers roughly <=220 dynamic collision parts before intentionally dynamic TrackPieces;
- no per-point motors;
- visual smoothness may not increase collision count.

## PASS rule
M2 can pass with Android low + Android mid + Windows low plus Studio 8-client tests. **PROD release requires the full matrix including at least one real iOS device.** Any missing required class is `NOT TESTED`, not PASS.

Attach MicroProfiler/Performance Dashboard snapshots or exported measurements to the release record.
