# DECISION LOG — PRE-G0 RUNTIME CLOSURE R14 — 2026-09-09

Status: **IMPLEMENTATION / CI / DOCUMENTATION CLOSED; Studio checkpoints: HUMAN PENDING**

## Scope
R14 is a bounded pre-G0 runtime-integrity closure inside the already-authorized B03–B17 M0 scope. It adds no new WHAT/WHY gameplay feature and does not authorize C01/M0.5 or any later system.

## R14.1–R14.11 closure
- **R14.1 Shape parity** — authoritative `acceptedPoints` are returned from server ShapeSpec and the client accepted preview renders the server-authoritative points rather than a pending local candidate. The B12 Studio spec compares result points with the current authoritative ShapeSpec.
- **R14.2 G0 presentation** — a Studio-only non-physical G0 presentation harness follows the debug racer with a scriptable camera and non-colliding debug proxy. It does not introduce the future `RaceCameraController` owner.
- **R14.3 Studio gate runner** — synchronous Studio regression specs aggregate failures under `xpcall`; server gate state is `TESTING → BLOCKED/READY`; client drawing waits for `READY`. The requested injected failing-spec BLOCKED→restore→READY observation remains a Studio checkpoint and is therefore **HUMAN PENDING**.
- **R14.4 Collision Default** — collision configuration prevents `Default` geometry from physically pushing RacerBody/RacerLeg; the actual Studio physics interaction remains **HUMAN PENDING**.
- **R14.5 Network pending/failure** — pending strokes are count/time bounded; late authoritative accepts are not discarded solely because local timeout removed pending state; server transport contains processor exceptions and returns a generic safe error. Studio latency/failure feel remains **HUMAN PENDING**.
- **R14.6 Recovery** — kill-Y recovery resets the same G0 RacerRuntime to canonical spawn, zeroes assembly velocities and preserves the authoritative `ShapeSpec`/`ShapeVersion`; gap/fall observation remains **HUMAN PENDING**.
- **R14.7 Atomic commit rollback** — B13 regression coverage injects both a partial commit failure and a post-commit motor-enable failure, verifying rollback preserves the previous accepted legs and removes partial staged/retiring state.
- **R14.8 Validation UX** — genuine geometry failures map to `DRAW A DIFFERENT SHAPE`; transport/technical/limit failures map to `TRY AGAIN`; internal reason codes remain debug output. Final visual/timing acceptance remains **HUMAN PENDING**.
- **R14.9 CI Rojo build** — GitHub Actions installs the pinned Roblox toolchain non-interactively and runs a real `Rojo build` after contract checks.
- **R14.10 Types/RemoteNames** — `StrokeTypes` is consumed on active stroke/network/ShapeSpec runtime boundaries; active remote consumers and B12 Studio coverage use the shared `RemoteNames` registry rather than duplicated literals.
- **R14.11 Docs/evidence reconciliation** — root README, docs README, SESSION, FEATURE_LIST and this decision record are reconciled to the final verified code/tooling evidence while retaining the B17/G0 human hard stop. `21_SYSTEM_CLASS_ARCHITECTURE.md` continues to mark its tree as TARGET architecture and explicitly keeps `RacerService` at D05 with the M0 Studio-only injected resolver.

## Automated evidence
Final R14 code/tooling evidence head: `8a6a05a31427346d2a1437820ffa759f21fca90c`.

GitHub Actions `Contract Verify` run `34387618626` completed successfully with **120 passed, 0 failed** and a successful **Rojo build** of `DrawRacersDev.rbxlx`.

R14.11 stale-evidence RED commit `0d8a6b85b5184bc053275d3441daa103af3e22c2`, run `34388536445`, completed with **119 passed, 1 failed**. The single expected failure was the R14.11 status/evidence test, proving the repository docs still referenced the older R14 head/evidence before reconciliation.

This automated evidence proves repository contract coverage plus Rojo project buildability. It does not run Roblox Studio physics, touch interaction, visual presentation acceptance, or the empirical product gate.

## Architecture boundary
The architecture document explicitly distinguishes TARGET architecture from current implementation authorization: `RacerService` remains D05, while M0 G0 uses the existing Studio-only injected resolver. **Do not implement RacerService before D05.**

## Gate result
**B17/G0 remains HUMAN_GATE. Studio checkpoints: HUMAN PENDING.**

B17 is not accepted by this decision. Local Studio verification and the six-external-tester empirical G0 protocol remain required before C01/M0.5.