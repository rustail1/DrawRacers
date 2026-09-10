# R16 PRE-STUDIO CLOSURE P0–P6

Date: 2026-09-10

This decision log records repository-level closure work only. It does not fabricate Roblox Studio or external-tester acceptance.

## Closure sequence

- **P0 — plan/contract reconciliation**: implementation plan reflects R16.3A shape-local centering, the current upright attachment basis, and the Product Owner authorization to continue Stage B/C implementation while human Studio gates remain pending.
- **P1 — B10 real-time recovery evidence**: upright recovery uses real elapsed Heartbeat time for the `<=0.25 s` acceptance window instead of a fixed iteration count.
- **P2 — isolated flat benchmark**: R16 flat-speed evidence runs on the dedicated `R16FlatBenchmark`, isolated from canonical course obstacles and without recovery-surface assist.
- **P3 — real fall recovery evidence**: G0 recovery records an actual trigger below `RecoveryKillY` and verifies ShapeSpec/ShapeVersion preservation across same-runtime recovery.
- **P4 — full reference matrix**: shared Studio-only `R16TrialRunner` owns deterministic spawn/contact/reset/measurement; all six canonical shapes are measured, and `noUniversalWinner` is derived from the intersection of real per-piece winner sets.
- **P5 — Wall positive/negative proof**: Wall requires at least one suitable shape (`HOOK_01` or `LONG_BAR_01`) to complete and requires legal negative control `SUBOPTIMAL_01` not to complete under the same runner/reset/window. P5.1 preserves the dedicated `WallContactTimeout` through the shared runner.
- **P6 — repository status closure**: owner status docs record P0–P6 and the final automated/toolchain result while keeping all human gates pending.

## Automated closure evidence

Closure code/status head `3e6ddaa723c3ddffea7fec6d3a255350dcd65541`; `Contract Verify` run `34467371410` completed SUCCESS with **158 passed, 0 failed**, Rokit/toolchain installation PASS, and **Rojo build PASS**. This evidence is repository/tooling evidence only.

## Gate state

**Studio Gate A — HUMAN STUDIO PENDING**  
**Studio Gate B — HUMAN STUDIO PENDING**  
**Studio Gate C — HUMAN STUDIO PENDING**  
**B17/G0 — HUMAN_GATE PENDING**

`AUTOMATED GREEN` in this closure means repository contracts/toolchain only. It is not a Studio PASS, not a solver-feel PASS, and not B17/G0 acceptance.

## R16.11

**R16.11 must not freeze before Studio Gate C is actually recorded from Roblox Studio evidence.** It may only reconcile final live numbers, selected tuning, screenshots/logs, and gate status after the combined Studio evidence pass. No Studio Gate A/B/C status may be promoted to PASS from CI alone.