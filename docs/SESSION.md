# SESSION.md — CURRENT STATE

Date: 2026-09-09  
Documentation version: **v1.3.4 EXECUTION CONSISTENCY FREEZE**

## Product state
The product specification remains closed. The CORE audit repair **R01–R05** is a bounded implementation-integrity pass inside the already-approved B03–B16 scope; it introduces **no new WHAT/WHY** gameplay scope.

Locked direction remains: 8-player live physics drawing race; one continuous player stroke controls two real rotating physical legs; no competitive power monetization; progression/meta remains outside M0 until the ordered gates allow it.

## Accepted implementation evidence
Repository-recorded human/Studio acceptance remains unchanged:
- A01 — Git/Rojo baseline — ACCEPTED.
- A02 — minimal shared/server/client roots — ACCEPTED.
- A03 — reproducible M0 test scene — ACCEPTED.
- A04 — deployment/config skeleton + Studio roots — ACCEPTED.
- B01 — pointer abstraction — ACCEPTED.
- B02 — local stroke preview — ACCEPTED.

B03–B16 code and regression specs exist in `main`, but they are **not promoted to ACCEPTED** merely because automated checks are green. Required Studio/physics/human evidence is still pending.

## CORE audit repair R01–R05
The post-B16 architecture/bug audit found concrete implementation inconsistencies and repaired them without crossing B17/G0:

- **R01 Geometry Authority** — `GeometryMath` is the single pure owner of normalized-shape → mapped-points/segment-plan construction; server ShapeSpec carries that plan into `LegAssembly`. The visible wide DrawCanvas now contains a **square semantic DrawInputRect**, preserving isotropic X/Y drawing semantics instead of stretching shapes by UI aspect ratio.
- **R02 Drawing/Network Correctness** — visual preview sampling is decoupled from bounded semantic payload sampling; obvious too-short strokes are rejected locally; accepted-result ordering follows server truth rather than only the newest submitted sequence.
- **R03 Physics Contract** — complete semantic collision groups/matrix, 25° free-tilt stabilization window with no forward propulsion, M0 lab under `Workspace.Runtime.Tracks`, and tunnel geometry relative to `Lane.TopY`.
- **R04 Debug Correctness** — collider count reads real `Segments` folders, simplified-point telemetry comes from accepted ShapeSpec, stuck telemetry uses the documented 2.5 s +X progress window, and debug targeting prefers explicit `DebugTarget` then a human racer.
- **R05 Studio/G0 Integration** — Studio uses exactly one selectable interactive harness. Default mode is `G0`; the Studio-only `M0HumanHarness` injects a temporary Player→RacerRuntime resolver into the existing `StrokeRemoteTransport`. It does **not** implement or pull forward D05 `RacerService`.

Decision record: `DECISION_LOG_CORE_AUDIT_REPAIR_2026-09-09.md`.

## Automated evidence
The full R01–R05 code/test head was verified by GitHub Actions `Contract Verify` run `34336175789`:
- command: `python verify.py`
- result: **66 passed, 0 failed**.

R06 adds documentation-consistency checks on top of that baseline. Studio/Rojo runtime evidence is not available to GitHub Actions and must not be fabricated.

## Current implementation/evidence cursor
**B17 — G0 HUMAN_GATE — Studio PASS PENDING.**

The repository is intentionally stopped at the M0 human gate. `StudioHarnessConfig.Mode` defaults to `G0`, so a local Studio Play session can exercise the real M0 path:

`DrawInputRect → DrawingController → SubmitStroke → StrokeRemoteTransport → LegShapeService → authoritative ShapeSpec → atomic physical legs → locomotion → redraw`.

### Studio evidence still required
Before any B03–B16 task is promoted beyond its evidence requirements, verify current `main` locally:
- normal Rojo sync/build has no project error;
- Studio Play runs B03–B16 specs with no red DrawRacers runtime error;
- `[DrawRacers][B16] debug tuning panel tests PASS` appears;
- `[DrawRacers][G0] human harness ready` appears;
- only one interactive G0 racer/harness remains after synchronous specs;
- drawing creates server-accepted physical legs and movement;
- redraw while moving changes the accepted physical shape without teleporting/resetting body state;
- debug `simplifiedPoints` and `colliderSegments` report real nonzero values after a valid shape;
- M0 lab exists under `Workspace.Runtime.Tracks`, not as a second top-level gameplay root.

## HARD STOP
**B17/G0 remains a HUMAN_GATE.** No C01, M0.5, multiplayer, meta, economy, shop, or later implementation may begin until G0 is explicitly recorded PASS or the Product Owner records a bounded rework/scope decision allowed by the gate protocol.

## Next permitted task
**B17 — G0 HUMAN_GATE only.**
