# R14 Pre-G0 Runtime Closure Design

Date: 2026-09-09
Status: APPROVED FOR IMPLEMENTATION
Owner: Product Owner / engineering handoff

## Goal
Close the remaining pre-G0 runtime integrity gaps without pulling C01/M0.5, D05 RacerService, D09 RaceCameraController, CosmeticService, or later production systems ahead of the locked implementation order.

## Scope
R14 is reliability work inside the existing M0/B17 boundary. It adds no new gameplay verb, progression, economy, monetization, multiplayer mode, or production camera/cosmetic subsystem.

Execution order is fixed:
1. R14.1 Shape parity
2. R14.2 G0 presentation
3. R14.3 Studio gate runner
4. R14.4 Default collision hardening
5. R14.5 Network pending/failure bounds
6. R14.6 G0 recovery
7. R14.7 Atomic commit rollback
8. R14.8 Validation UX
9. R14.9 CI Rojo build
10. R14.10 Types/RemoteNames cleanup
11. R14.11 Documentation/evidence reconciliation

Human Studio checkpoints remain required where specified. Automation must not mark B17/G0 PASS.

## R14.1 — Authoritative accepted-shape parity
The server is the final owner of cleaned semantic shape geometry. The client may sample and pre-process for bandwidth, but after a successful SubmitStroke the accepted DrawCanvas preview must be rebuilt from semantic points returned by the authoritative server ShapeSpec, not from the locally cached pending candidate.

`StrokeResult` accepted payload gains bounded `acceptedPoints: Array<{x:number,y:number}>`. These points are exactly `ShapeSpec.normalizedPoints`. Rejected results do not return accepted geometry and preserve the previous accepted preview.

Observable invariant:
`accepted DrawCanvas shape == ShapeSpec.normalizedPoints == source points used by GeometryMath for physical legs`.

## R14.2 — Studio-only G0 presentation
Add a Studio-only G0 presentation harness instead of implementing production D09/D09-adjacent systems early. It follows the `DebugTarget` racer with a simple camera look-ahead and adds a non-colliding visible debug body proxy so the physical racer remains readable before CosmeticService exists.

The harness must never alter racer CFrame, velocity, mass, collision, ShapeVersion, or authoritative state.

## R14.3 — Studio spec gate runner
B03–B16 Studio specs run through one aggregate runner. A failed spec produces an explicit BLOCKED state and prevents G0 harness startup. The client DrawHUD does not accept G0 drawing while the Studio gate is TESTING/BLOCKED. Failures are reported clearly instead of leaving a half-alive client with no working server transport.

## R14.4 — Default collision hardening
Only canonical Track collision may drive racer locomotion. `Default` must not collide with RacerBody or RacerLeg. Existing Track↔RacerBody and Track↔RacerLeg collision remains enabled.

## R14.5 — Bounded pending/network failure behavior
Client pending stroke state is bounded by count and lifetime. Missing responses expire without deleting the last accepted shape. Server transport catches unexpected processor failures, logs the server failure, and emits a bounded generic server error for a request whose sequence can be safely echoed.

This is transport hardening, not a gameplay retry mechanic.

## R14.6 — Studio-only G0 recovery
The G0 harness watches only its active racer. Falling below a configured M0 recovery Y destroys/recreates that one RacerRuntime at the canonical G0 spawn. Production checkpoint/recovery services remain later work.

## R14.7 — Atomic redraw commit rollback
Atomic redraw must survive not only staging/build failure but also a failure during the commit/enable phase. On commit failure, staged assemblies are destroyed, old leg names/state are restored, ShapeVersion is unchanged, and body CFrame/linear/angular velocity remain unchanged.

## R14.8 — Validation UX boundary
Internal reject codes remain available in logs/debug. The player-facing G0 toast uses bounded human-readable copy for geometry/input retry versus transport/server retry. Do not introduce the full localization system early.

## R14.9 — CI Rojo build
GitHub Actions continues running `python verify.py` and additionally installs the pinned Rokit/Rojo toolchain and executes `rojo build`. This validates the Rojo project tree/build but does not replace Roblox Studio physics/human testing.

## R14.10 — Types and RemoteNames cleanup
Use shared type definitions for the stroke remote payload/result and actual ShapeSpec debug fields. Consumers use `RemoteNames.SubmitStroke` / `RemoteNames.StrokeResult` instead of duplicating string literals where practical. This cleanup may not change observable behavior.

## R14.11 — Documentation and evidence reconciliation
Reconcile architecture/status docs to the real R14 implementation/evidence. `21` must explicitly state that its service/controller tree is target architecture, not permission to instantiate future task owners early. RacerService remains D05. B17/G0 remains PENDING until the required Studio and external tester evidence exists.

## Testing policy
Each behavioral task uses RED→GREEN TDD. Existing Python contract checks must stay green. Studio specs are strengthened for runtime invariants where possible. Human Studio checkpoints are recorded as PENDING until the user runs them; they are never inferred from CI.

## Non-goals
- no C01 TrackPiece production work;
- no D05 RacerService;
- no production RaceCameraController;
- no CosmeticService;
- no production checkpoint/progress system;
- no economy/profile/reward work;
- no B17/G0 automatic PASS.
