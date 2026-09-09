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
**R01–R12 bounded CORE/pre-G0 integrity repair plus R14.1–R14.11 runtime/evidence closure are implemented in `main`; the next permitted item remains B17/G0 HUMAN_GATE. Studio checkpoints: HUMAN PENDING.**

Historical evidence is preserved: the pre-R06 full automated baseline on GitHub Actions run `34336175789` was **66 passed, 0 failed**. R08 then closed the touch-first/G0-character/minimum-extent/bounded-anti-stall gaps; commit `3a0a32ce90f2cfcd2f37e3be430758dacc86d6d3` passed run `34349254516` at **77 passed, 0 failed**.

R09 performed another pre-G0 repository review. Its RED commit `35c4df76dd4d663e4785bcb295fda357b8c48ef9` intentionally exposed three concrete gaps and failed run `34351760319` at **77 passed, 3 failed**. The bounded repair commit `3d414556677577af6b07ff253b97041c0eb59c30` passed run `34352130204` at **80 passed, 0 failed**.

R10–R12 then closed the drawing UI, hybrid-input/preview-bound, long-stroke, and G0 Character-respawn isolation gaps. Final R10–R12 code head `e2bedd34696bb99da43878c19d7984c9134c8bef` passed run `34363706915` at **88 passed, 0 failed**.

R14.1–R14.10 closed the pre-G0 runtime/tooling gaps: authoritative shape parity, Studio G0 presentation harness, fail-closed gate runner, Default collision contract, bounded network pending/failure handling, shape-preserving G0 recovery, atomic rollback regression, validation copy, CI Rojo build, and shared StrokeTypes/RemoteNames ownership. Final code/tooling evidence head `8a6a05a31427346d2a1437820ffa759f21fca90c`, run `34387618626`: **120 passed, 0 failed** plus successful **Rojo build**. R14.11 reconciles repository status/evidence documents to that code head without promoting the human gate.

These checks prove repository contracts and Rojo project buildability. They do not prove Roblox Studio physics, touch feel, visual acceptance, or the external-tester G0 product gate.

A01–A04 and B01–B02 remain recorded ACCEPTED. B03–B16 implementation and regression specs exist in `main`, but required Studio/human evidence remains pending. **B17/G0 is a hard stop before C01/M0.5.**

## CORE / pre-G0 integrity repair
The repair series did not add a new product feature or pull later race/meta systems forward:

- **R01 — Geometry Authority:** one pure `GeometryMath` owner builds mapped points and the physical segment plan. Server ShapeSpec carries that authoritative plan into `LegAssembly`. The wide player-facing DrawCanvas contains a square semantic DrawInputRect so screen aspect ratio cannot stretch physical X/Y shape semantics.
- **R02 — Drawing/Network Correctness:** visual preview is independent from bounded semantic sampling; obvious too-short strokes are rejected before remote submission; accepted-result ordering tracks server truth even when a newer request is pending/rejected.
- **R03 — Physics Contract:** complete collision matrix, soft/free-tilt stabilization with no hidden +X propulsion, M0 lab under `Workspace.Runtime.Tracks`, and TopY-relative tunnel geometry.
- **R04 — Debug Correctness:** real collider and cleaned-point telemetry, documented +X progress-window stuck state, and explicit/human debug target selection.
- **R05 — Studio/G0 Integration:** exactly one selectable Studio interactive harness. `StudioHarnessConfig.Mode` defaults to `G0`. `M0HumanHarness` binds the existing `SubmitStroke`/`StrokeResult` path to one Studio test racer through an injected resolver; D05 `RacerService` is intentionally not implemented early.
- **R06 — Documentation consistency:** repository status docs were reconciled at the G0 hard stop without promoting Studio acceptance.
- **R07 — Core review fixes:** strict outer network payload validation/rate-ordering, complete debug metrics/environment gating, and square semantic input ownership were tightened.
- **R08 — Final core closure:** touch layout is selected safely between strokes, the normal Roblox Character is isolated from G0 racer physics, minimum useful leg extent is enforced server-side, and bounded anti-stall uses canonical contact/tag semantics with G0 telemetry.
- **R09 — Pre-G0 consistency review:** accepted-shape presentation stores semantic coordinates so responsive layout changes cannot distort the accepted preview; exact touch ValidationToast/DrawHint layout tokens are applied; an obstacle `RequirementTag` overrides recovery assist; spawned racers remove the empty template-only `RuntimeAttachments` helper after its attachments move to `BodyCollider`.
- **R10–R12 — bounded bug sweep:** accepted-thickness/ghost/toast/input-family behavior, hybrid-input bounds, long-stroke compaction, and retired Character isolation are regression-covered.
- **R14.1–R14.11 — runtime/evidence closure:** server-authoritative accepted geometry reaches the client, Studio harness gating is fail-closed, network/recovery/rollback/validation contracts are bounded, CI performs a real Rojo build, shared type/remote registries own those contracts, and repository evidence docs are reconciled to the final code/tooling head.

Decision records include `docs/DECISION_LOG_CORE_AUDIT_REPAIR_2026-09-09.md`, `docs/DECISION_LOG_PRE_G0_REVIEW_R07_R09_2026-09-09.md`, `docs/DECISION_LOG_PRE_G0_BUG_SWEEP_R10_R12_2026-09-09.md`, and `docs/DECISION_LOG_PRE_G0_RUNTIME_CLOSURE_R14_2026-09-09.md`.

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
The M0 lab contains the canonical flat/steps/wall/gap/tunnel representatives. DEV/STAGING/Studio debug telemetry exposes shape/segment/speed/motor/stuck/anti-stall/lane/checkpoint/progress information.

## B17/G0 local Studio gate
Default Studio mode is `G0`. After current `main` is synced, a Play session should run the synchronous B03–B16 specs through the R14.3 gate runner and then leave one interactive human G0 racer only if the gate reaches READY.

Expected local evidence includes:
- no red DrawRacers runtime error;
- injected one-spec failure produces BLOCKED, restoring it produces READY;
- `[DrawRacers][B16] debug tuning panel tests PASS`;
- `[DrawRacers][G0] human harness ready` only after READY;
- drawing in DrawInputRect produces server-accepted physical legs and locomotion;
- accepted preview matches the authoritative accepted shape;
- redraw while moving swaps the accepted shape without body teleport/velocity reset;
- Default/Character geometry cannot push RacerBody/RacerLeg;
- gap/fall below recovery threshold resets the same racer to canonical spawn while preserving authoritative ShapeSpec/ShapeVersion;
- pending/network failure does not accumulate unbounded requests;
- validation shows player-facing copy and bounded toast behavior;
- debug cleaned-point/collider values update from the actual accepted shape;
- `antiStallActive` is bounded to flat/recovery contact and is false on obstacle/airborne cases;
- M0 lab is under `Workspace.Runtime.Tracks`.

After local technical Studio smoke, empirical G0 still follows `docs/55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md`: six unique external testers and all fixed PASS criteria. Do not mark B17/G0 PASS from CI alone.

## Working loop
`ChatGPT/GitHub change → git pull --ff-only → Rojo build/serve → Studio playtest → PASS/FAIL evidence → next allowed item`

Before pulling remote changes, run `git status` and do not overwrite uncommitted local work.