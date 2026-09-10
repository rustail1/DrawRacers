# Draw Racers

Roblox production repository for **Draw Racers**.

## Source of truth
The current production specification is in `docs/` (v1.3.4 ZERO-QUESTION PRODUCTION HANDOFF plus recorded R16 corrections). Do not mix older history packages into implementation context.

Before implementation, read:
1. `docs/AGENTS.md`
2. `docs/FEATURE_LIST.md`
3. `docs/SESSION.md`
4. `docs/26_HANDOFF_MAP.md`
5. the exact task row in `docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`
6. only the owner specs named by that row

## Current state
**R16.3B stroke-origin/reference-parity implementation is present in `main`; repository contracts are being reconciled to that implementation. Studio Gate A — HUMAN STUDIO PENDING. Studio Gate B — HUMAN STUDIO PENDING. Studio Gate C — HUMAN STUDIO PENDING. Historical B17/G0 remains the downstream HUMAN_GATE PENDING.**

The current mechanical contract keeps X/Y translation physical, mechanically locks Z translation to the lane, and keeps the BodyCollider upright about world X/Y/Z while only the legs intentionally rotate. `PhysicsConfig.LegGeometry` owns the canonical hub offsets. **R16.3B supersedes R16.3A bounds-center semantics:** after cleanup, the server translates the shape so the **first cleaned point** is the mechanical origin `(0,0)`, without resizing, rotating or mirroring it. The visible semantic DrawInputRect is wide (`1.75:1`) but normalization remains isotropic by height. One first-point-anchored ShapeSpec is duplicated to both legs, while a sequence-scoped local presentation anchor may keep the accepted line where the player drew it. R16.4 retains the 180° twin-leg phase and redraw phase-preservation contract.

Physical leg collider boxes remain authoritative and hidden; a separate nonphysical visual layer renders the leg shape. R16FINAL is the unified Studio evidence route: automated R16 evidence runs before the interactive human G0 handoff. None of those repository/harness facts substitute for actual Studio evidence.

Historical evidence is preserved: the pre-R06 full automated baseline on GitHub Actions run `34336175789` was **66 passed, 0 failed**. R08 then closed the touch-first/G0-character/minimum-extent/bounded-anti-stall gaps; commit `3a0a32ce90f2cfcd2f37e3be430758dacc86d6d3` passed run `34349254516` at **77 passed, 0 failed**.

R09 performed another pre-G0 repository review. Its RED commit `35c4df76dd4d663e4785bcb295fda357b8c48ef9` intentionally exposed three concrete gaps and failed run `34351760319` at **77 passed, 3 failed**. The bounded repair commit `3d414556677577af6b07ff253b97041c0eb59c30` passed run `34352130204` at **80 passed, 0 failed**.

R10–R12 then closed the drawing UI, hybrid-input/preview-bound, long-stroke, and G0 Character-respawn isolation gaps. Final R10–R12 code head `e2bedd34696bb99da43878c19d7984c9134c8bef` passed run `34363706915` at **88 passed, 0 failed**.

R14.1–R14.10 closed the pre-G0 runtime/tooling gaps: authoritative shape parity, Studio G0 presentation harness, fail-closed gate runner, Default collision contract, bounded network pending/failure handling, shape-preserving G0 recovery, atomic rollback regression, validation copy, CI Rojo build, and shared StrokeTypes/RemoteNames ownership. Final code/tooling evidence head `8a6a05a31427346d2a1437820ffa759f21fca90c`, run `34387618626`: **120 passed, 0 failed** plus successful **Rojo build**. R14.11 reconciled repository status/evidence documents to that code head without promoting the human gate. **Studio checkpoints: HUMAN PENDING.**

R15.1 replaced the failed finite-force lane follower with the current mechanical `PlaneConstraint` Z lock. Its historical free-world-Z body rotation detail is superseded by R16.1. R16 Stage A/B/C then added upright-body, canonical-hub, reference-shape, comparative evidence and redraw/camera/canonical harness work. R16.3B is the current shape-origin/UI/presentation correction layered on that existing scope. Current authoritative status/evidence belongs to `docs/SESSION.md`; automated/CI/Rojo evidence never substitutes for the pending Studio solver check.

These checks prove repository contracts and Rojo project buildability only when a fresh run is green. They do not prove Roblox Studio physics, touch feel, visual acceptance, or the external-tester G0 product gate.

A01–A04 and B01–B02 remain recorded ACCEPTED. B03–B16 implementation and regression specs exist in `main`, but required Studio/human evidence remains pending. **Studio Gate A/B/C remain HUMAN STUDIO PENDING; B17/G0 remains a HUMAN_GATE before C01/M0.5.**

## CORE / pre-G0 integrity repair
The repair series did not add a new product feature or pull later race/meta systems forward:

- **R01 — Geometry Authority:** one pure `GeometryMath` owner builds mapped points and the physical segment plan. Server ShapeSpec carries that authoritative plan into `LegAssembly`. R16.3B now exposes one wide semantic DrawInputRect and keeps normalization isotropic by its height.
- **R02 — Drawing/Network Correctness:** visual preview is independent from bounded semantic sampling; obvious too-short strokes are rejected before remote submission; accepted-result ordering tracks server truth even when a newer request is pending/rejected.
- **R03 — Physics Contract:** complete collision matrix, lane/orientation stabilization with no hidden +X propulsion, M0 lab under `Workspace.Runtime.Tracks`, and TopY-relative tunnel geometry. Its older free-tilt orientation detail is superseded by R16.1 upright-body parity.
- **R04 — Debug Correctness:** real collider and cleaned-point telemetry, documented +X progress-window stuck state, and explicit/human debug target selection.
- **R05 — Studio/G0 Integration:** exactly one selectable Studio interactive harness. `StudioHarnessConfig.Mode` defaults to `G0`. `M0HumanHarness` binds the existing `SubmitStroke`/`StrokeResult` path to one Studio test racer through an injected resolver; D05 `RacerService` is intentionally not implemented early.
- **R06 — Documentation consistency:** repository status docs were reconciled at the G0 hard stop without promoting Studio acceptance.
- **R07 — Core review fixes:** strict outer network payload validation/rate-ordering, complete debug metrics/environment gating, and semantic input ownership were tightened; R16.3B supersedes the old square-surface wording with the wide semantic input surface.
- **R08 — Final core closure:** touch layout is selected safely between strokes, the normal Roblox Character is isolated from G0 racer physics, minimum useful leg extent is enforced server-side, and bounded anti-stall uses canonical contact/tag semantics with G0 telemetry.
- **R09 — Pre-G0 consistency review:** accepted-shape presentation stores semantic coordinates so responsive layout changes cannot distort the accepted preview; exact touch ValidationToast/DrawHint layout tokens are applied; an obstacle `RequirementTag` overrides recovery assist; spawned racers remove the empty template-only `RuntimeAttachments` helper after its attachments move to `BodyCollider`.
- **R10–R12 — bounded bug sweep:** accepted-thickness/ghost/toast/input-family behavior, hybrid-input bounds, long-stroke compaction, and retired Character isolation are regression-covered.
- **R14.1–R14.11 — runtime/evidence closure:** server-authoritative accepted geometry reaches the client, Studio harness gating is fail-closed, network/recovery/rollback/validation contracts are bounded, CI performs a real Rojo build, shared type/remote registries own those contracts, and repository evidence docs are reconciled to the final code/tooling head.
- **R15.1 — mechanical lane-plane foundation:** X/Y remain physical while a `PlaneConstraint` mechanically locks lateral Z. The historical free-Z orientation behavior is not current.
- **R16.1 — Upright Body:** body rotation about world X/Y/Z is locked/corrected with `AlignOrientation` AllAxes while X/Y translation remains physical and Z remains lane-plane locked.
- **R16.2 — Hub Position:** canonical symmetric hub offsets are owned only by `PhysicsConfig.LegGeometry`.
- **R16.3/R16.3B — one drawing → two first-point-anchored authoritative legs:** server cleanup anchors the shape to the first cleaned point by translation only; size is not normalized away; one authoritative ShapeSpec drives both legs. The previous bounds-center pivot rule is superseded.
- **R16.3B presentation split:** physical colliders stay hidden/authoritative, visible leg geometry is nonphysical, accepted preview may reapply only a local sequence-scoped presentation anchor, and the wide 1.75:1 input surface remains isotropic.
- **R16.4 — Twin-leg Phase:** both legs use the same locomotion direction, start 180° apart, and redraw preserves each side's live phase.

Decision records include `docs/DECISION_LOG_CORE_AUDIT_REPAIR_2026-09-09.md`, `docs/DECISION_LOG_PRE_G0_REVIEW_R07_R09_2026-09-09.md`, `docs/DECISION_LOG_PRE_G0_BUG_SWEEP_R10_R12_2026-09-09.md`, `docs/DECISION_LOG_PRE_G0_RUNTIME_CLOSURE_R14_2026-09-09.md`, `docs/DECISION_LOG_R16_PRE_STUDIO_CLOSURE_2026-09-10.md`, and `docs/DECISION_LOG_R16_3B_STROKE_ORIGIN_REFERENCE_PARITY_2026-09-10.md`.

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
Deterministic rectangle clamp/dedupe, DrawInputRect semantic coordinates, RDP simplification, open-polyline resampling, length/bounds validation and malformed/non-finite coverage. R16.3B server authority translates the first cleaned point to `(0,0)` without resizing before physical mapping. The bounds midpoint is no longer required to be the hub.

### B06–B10 — Physical locomotion foundation
Canonical 3×3×3 racer body, physical leg assemblies at canonical hubs, hinge motors, two-leg phase, collision policy and **upright** lane/orientation stabilization. X/Y translation remains physical, Z is mechanically lane-locked, and the body is corrected upright about world X/Y/Z. No hidden forward race power.

### B11–B12 — Server authority/network boundary
`LegShapeService` validates semantic stroke intent and owns ShapeSpec/version progression. Exact semantic remotes are `SubmitStroke` and `StrokeResult`; accepted results carry the server-authoritative first-point-anchored points. The request payload schema remains sequence+points only. Client data cannot author world geometry, CFrame, segment plans, ShapeVersion or rewards.

### B13–B14 — Atomic redraw/security stress
Replacement legs stage before commit; invalid/failed redraw preserves the previous accepted physical shape; repeated malformed/stale/rate/size abuse is covered by regressions.

### B15–B16 — Canonical lab/debug
The M0 lab contains the canonical flat/steps/wall/gap/tunnel representatives. DEV/STAGING/Studio debug telemetry exposes shape/segment/speed/motor/stuck/anti-stall/lane/checkpoint/progress information. The debug panel is presentation-only and hidden by default behind F3.

## R16FINAL local Studio gate
Default Studio mode remains `G0`. For the unified R16.3B evidence pass, select the Studio-only `R16FINAL` mode locally, run Play, and wait for the full synchronous R16 evidence sequence before the human G0 handoff.

Expected local evidence includes:
- no red DrawRacers runtime error;
- `[StudioGate] TOTAL 13 PASS / 0 FAIL` and `READY`;
- R16.5–R16.10 evidence completes without a failure and R16FINAL reaches `[DrawRacers][R16FINAL] HUMAN G0 READY`;
- body remains upright, X/Y physical and Z mechanically lane-locked;
- one accepted drawing creates exactly two matching physical legs with the recorded 180° phase behavior;
- first accepted point is the mechanical hub origin while moving the raw drawing around the wide DrawInputRect does not change its first-point-relative physics geometry;
- changing drawn size changes physical size;
- visible leg presentation follows the accepted drawing while physical collider boxes remain hidden;
- redraw while moving does not reset the body or gait phase;
- observer Roblox Character remains non-participating in racer physics.

**Do not mark Studio Gate A, B, C or B17/G0 PASS from CI or repository inspection.** R16.11 may freeze only after actual Studio Gate C evidence is recorded. B17/G0 then follows `docs/55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md` and remains the external human product gate before M0.5.

## Working loop
`ChatGPT/GitHub change → git pull --ff-only → Rojo build/serve → Studio playtest → PASS/FAIL evidence → next allowed item`

Before pulling remote changes, run `git status` and do not overwrite uncommitted local work.