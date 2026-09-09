# DECISION LOG — PRE-G0 RUNTIME CLOSURE R14 — 2026-09-09

Status: **IMPLEMENTATION / CI CLOSED; Studio checkpoints: HUMAN PENDING**

## Scope
R14 is a bounded pre-G0 runtime-integrity closure inside the already-authorized B03–B17 M0 scope. It adds no new WHAT/WHY gameplay feature and does not authorize C01/M0.5 or any later system.

## R14.1–R14.10 code/CI closure
- **R14.1 Shape parity** — authoritative `acceptedPoints` are returned from server ShapeSpec and the client accepted preview renders the server-authoritative points rather than a pending local candidate. The B12 Studio spec compares result points with the current authoritative ShapeSpec.
- **R14.2 G0 presentation** — a Studio-only non-physical G0 presentation harness follows the debug racer with a scriptable camera and non-colliding debug proxy. It does not introduce the future `RaceCameraController` owner.
- **R14.3 Studio gate runner** — synchronous Studio regression specs aggregate failures under `xpcall`; server gate state is `TESTING → BLOCKED/READY`; client drawing waits for `READY`. The requested injected failing-spec BLOCKED→restore→READY observation remains a Studio checkpoint and is therefore **HUMAN PENDING**.
- **R14.4 Collision Default** — collision configuration prevents `Default` geometry from physically pushing RacerBody/RacerLeg; the actual Studio physics interaction remains **HUMAN PENDING**.
- **R14.5 Network pending/failure** — pending strokes are count/time bounded; late authoritative accepts are not discarded solely because local timeout removed pending state; server transport contains processor exceptions and returns a generic safe error. Studio latency/failure feel remains **HUMAN PENDING**.
- **R14.6 Recovery** — G0 recovery watches the racer kill-Y and respawns only the racer runtime; gap/fall behavior remains a Studio checkpoint and is **HUMAN PENDING**.
- **R14.7 Atomic commit rollback** — B13 regression coverage injects a right-leg commit failure and verifies rollback cleans staged/retiring names and preserves the prior accepted assembly.
- **R14.8 Validation UX** — internal reason codes map to player-facing copy rather than exposing raw transport/validation codes; final visual/timing acceptance remains **HUMAN PENDING**.
- **R14.9 CI Rojo build** — GitHub Actions now installs the Roblox toolchain non-interactively and runs a real `Rojo build` after contract checks.
- **R14.10 Types/RemoteNames** — `StrokeTypes` owns stroke/network/debug payload types, and active client/G0 remote consumers use the shared `RemoteNames` registry rather than duplicated literals.

## Automated evidence
Final R14.1–R14.10 code/tooling evidence head: `2864661e5214db5a09e53a53b6c8da8a79365cce`.

GitHub Actions `Contract Verify` run `34377868753` completed successfully with **109 passed, 0 failed** and a successful **Rojo build** of `DrawRacersDev.rbxlx`.

This proves repository contract coverage plus Rojo project buildability. It does not run Roblox Studio physics, touch interaction, visual presentation acceptance, or the empirical product gate.

## R14.11 documentation/evidence reconciliation
`docs/README.md`, `docs/SESSION.md`, `docs/FEATURE_LIST.md`, and `21_SYSTEM_CLASS_ARCHITECTURE.md` are reconciled to the R14 state. The architecture document explicitly distinguishes TARGET architecture from current implementation authorization: `RacerService` remains D05, while M0 G0 uses the existing Studio-only injected resolver. Do not implement `RacerService` before D05.

## Gate result
**B17/G0 remains HUMAN_GATE. Studio checkpoints: HUMAN PENDING.**

There is no `ACCEPTED — B17` decision here. Local Studio verification and the six-external-tester empirical G0 protocol remain required before C01/M0.5.