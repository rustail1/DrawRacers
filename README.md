# Draw Racers

Roblox production repository for **Draw Racers**.

## Source of truth
The current production specification is in `docs/` (v1.3.4 ZERO-QUESTION PRODUCTION HANDOFF). Do not mix older history packages into implementation context.

Before implementation, read:
1. `docs/AGENTS.md`
2. `docs/FEATURE_LIST.md`
3. `docs/SESSION.md`
4. `docs/26_HANDOFF_MAP.md`
5. the exact task row in `docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`
6. only the owner specs named by that row

## Current state
**R01–R05 CORE audit repair is implemented in `main`; the next permitted item is B17/G0 HUMAN_GATE.**

The pre-R06 full automated baseline on GitHub Actions run `34336175789` is **66 passed, 0 failed**. This proves the repository contract suite only; it does not substitute for Roblox Studio/physics/human evidence.

A01–A04 and B01–B02 remain recorded ACCEPTED. B03–B16 implementation and regression specs exist in `main`, but required Studio evidence remains pending. **B17/G0 is a hard stop before C01/M0.5.**

## CORE audit repair
The bounded repair did not add a new product feature or pull later race/meta systems forward:

- **R01 — Geometry Authority:** one pure `GeometryMath` owner builds mapped points and the physical segment plan. Server ShapeSpec carries that authoritative plan into `LegAssembly`. The wide player-facing DrawCanvas contains a square semantic DrawInputRect so screen aspect ratio cannot stretch physical X/Y shape semantics.
- **R02 — Drawing/Network Correctness:** visual preview is independent from bounded semantic sampling; obvious too-short strokes are rejected before remote submission; accepted-result ordering tracks server truth even when a newer request is pending/rejected.
- **R03 — Physics Contract:** complete collision matrix, soft/free-tilt stabilization with no hidden +X propulsion, M0 lab under `Workspace.Runtime.Tracks`, and TopY-relative tunnel geometry.
- **R04 — Debug Correctness:** real collider and cleaned-point telemetry, documented +X progress-window stuck state, and explicit/human debug target selection.
- **R05 — Studio/G0 Integration:** exactly one selectable Studio interactive harness. `StudioHarnessConfig.Mode` defaults to `G0`. `M0HumanHarness` binds the existing `SubmitStroke`/`StrokeResult` path to one Studio test racer through an injected resolver; D05 `RacerService` is intentionally not implemented early.

Decision record: `docs/DECISION_LOG_CORE_AUDIT_REPAIR_2026-09-09.md`.

## Toolchain
Rokit manages Rojo. From the repository root:

```powershell
rokit install
rojo --version
rojo build -o DrawRacersDev.rbxlx
rojo serve
python verify.py
```

Then connect the Rojo Studio plugin to the local server shown by `rojo serve`.

## M0 implementation layers
### B03–B05 — Stroke processing
Deterministic clamp/dedupe, DrawInputRect-centered normalization, RDP simplification, open-polyline resampling, length/bounds validation and malformed/non-finite coverage.

### B06–B10 — Physical locomotion foundation
Canonical 3×3×3 racer body, physical leg assemblies at canonical hubs, hinge motors, two-leg phase, collision policy and lane/orientation stabilization. No hidden forward race power.

### B11–B12 — Server authority/network boundary
`LegShapeService` validates semantic stroke intent and owns ShapeSpec/version progression. Exact semantic remotes are `SubmitStroke` and `StrokeResult`; client data cannot author world geometry, CFrame, segment plans, ShapeVersion or rewards.

### B13–B14 — Atomic redraw/security stress
Replacement legs stage before commit; invalid/failed redraw preserves the previous accepted physical shape; repeated malformed/stale/rate/size abuse is covered by regressions.

### B15–B16 — Canonical lab/debug
The M0 lab contains the canonical flat/steps/wall/gap/tunnel representatives. DEV/STAGING/Studio debug telemetry exposes shape/segment/speed/motor/stuck/lane/checkpoint/progress information.

## B17/G0 local Studio gate
Default Studio mode is `G0`. After current `main` is synced, a Play session should run the synchronous B03–B16 specs and then leave one interactive human G0 racer.

Expected evidence includes:
- no red DrawRacers runtime error;
- `[DrawRacers][B16] debug tuning panel tests PASS`;
- `[DrawRacers][G0] human harness ready`;
- drawing in DrawInputRect produces server-accepted physical legs and locomotion;
- redraw while moving swaps the accepted shape without body teleport/velocity reset;
- debug cleaned-point/collider values update from the actual accepted shape;
- M0 lab is under `Workspace.Runtime.Tracks`.

Do not mark B17/G0 PASS from CI alone. No C01, multiplayer slice, meta, economy, shop or later phase begins before recorded human-gate evidence.

## Working loop
`ChatGPT/GitHub change → git pull --ff-only → Rojo → Studio playtest → PASS/FAIL evidence → next allowed item`

Before pulling remote changes, run `git status` and do not overwrite uncommitted local work.
