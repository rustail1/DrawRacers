# DECISION LOG — PRE-G0 BUG SWEEP R10–R12 — 2026-09-09

Status: **IMPLEMENTATION / REGRESSION CLOSED; B17/G0 remains pending**.

## Scope decision
This was a bounded defect sweep of the already implemented A01–B16 / B17 preparation surface. It adds **no new WHAT/WHY** gameplay, progression, multiplayer, economy, monetization, or content scope. It does not authorize C01 or any later phase.

## R10 — drawing UI contract repair
Closed four observable/client defects in `DrawingController`:
- accepted-shape stroke thickness now follows the active pointer family only while drawing and the current layout family otherwise;
- the empty ghost remains permanently hidden after the first pointer-down for the heat;
- ValidationToast and DrawHint are mutually exclusive and validation feedback auto-hides within the doc-59 2.0 s bound;
- unsupported `LastInputType` values no longer force desktop layout.

TDD evidence: RED commit `1a49337ae6a5cce144f666fb7178822bb7cdff15`, then repair commit `83b532c60824cb3302ee16da91357ad4fe2e584f`.

## R11 — hybrid input / preview complexity repair
Closed two additional client defects:
- LastInputType changes during an active stroke no longer overwrite the stroke-owned pending layout family; layout switching occurs only between strokes;
- live preview points/Frame instances are bounded using the existing `MaxRawPoints` budget and compacted instead of growing without limit.

TDD evidence: RED commit `ce58f8ef2541300f31b971ed4454c85ce5107a7a`, then repair commit `2ffa76bc14fd3263c1aff6e479367de469790297`.

## R12 — long-stroke fidelity / G0 respawn isolation repair
Closed two additional defects:
- semantic sampling no longer freezes after reaching the 96-point cap; samples are compacted and later parts of a long/noisy stroke continue to influence the bounded payload before normal clamp/dedupe/RDP/resample processing;
- a new Roblox Character spawn in the G0 harness no longer restores collisions on the retired Character. Retired and current Character parts remain observer-only until harness/player teardown.

TDD evidence: RED commit `f31e4ebc954510d95788d479cb40d35103cd0889`; respawn repair `6a6f59b89b032babfa5e6f398fe36195c09c0845`; final R12 code head `e2bedd34696bb99da43878c19d7984c9134c8bef`.

## Verification evidence
Fresh GitHub Actions `Contract Verify` run `34363706915` on code head `e2bedd34696bb99da43878c19d7984c9134c8bef` completed successfully with **88 passed, 0 failed**.

This is static/contract evidence only. It does not execute Roblox Studio physics or human product acceptance.

## Gate decision
**B17/G0 remains pending.** Local Studio smoke and the empirical G0 protocol are still required. No C01 work begins merely because R10–R12 are regression-green. Any new player-visible runtime defect found during Studio/G0 returns to bounded repair before the gate can be accepted.
