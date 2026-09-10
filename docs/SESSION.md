# SESSION.md — CURRENT STATE

Date: 2026-09-10  
Documentation version: **v1.4.4 R16 STAGE-C + REMOTE BUGFIX WORKFLOW**

## Product state
The product specification remains closed. CORE/pre-G0 repair **R01–R12**, bounded runtime/evidence closure **R14.1–R14.11**, planar correction **R15/R15.1**, and current reference-parity correction **R16** stay inside the already-approved B03–B16/B17 scope; they introduce **no new WHAT/WHY gameplay scope**.

Locked direction remains: 8-player live physics drawing race; one continuous player stroke controls two real rotating physical legs; no competitive power monetization; progression/meta remains outside M0 until the ordered gates allow it.

## Accepted implementation evidence
Repository-recorded human/Studio acceptance remains unchanged:
- A01 — Git/Rojo baseline — ACCEPTED.
- A02 — minimal shared/server/client roots — ACCEPTED.
- A03 — reproducible M0 test scene — ACCEPTED.
- A04 — deployment/config skeleton + Studio roots — ACCEPTED.
- B01 — pointer abstraction — ACCEPTED.
- B02 — local stroke preview — ACCEPTED.

B03–B16 code and regression specs exist in `main`, but they are **not promoted to ACCEPTED** merely because automated checks and Rojo build are green. Required Studio/physics/human evidence is still pending.

## CORE/pre-G0 integrity repair R01–R12
- **R01 Geometry Authority** — `GeometryMath` is the single pure owner of normalized-shape → mapped-points/segment-plan construction; server ShapeSpec carries that plan into `LegAssembly`. The visible wide DrawCanvas contains a square semantic DrawInputRect.
- **R02 Drawing/Network Correctness** — visual preview sampling is decoupled from bounded semantic payload sampling; obvious too-short strokes are rejected locally; accepted-result ordering follows server truth.
- **R03 Physics Contract** — complete semantic collision groups/matrix, no forward propulsion from stabilization, M0 lab under `Workspace.Runtime.Tracks`, and tunnel geometry relative to `Lane.TopY`.
- **R04 Debug Correctness** — collider count reads real `Segments` folders, cleaned-point telemetry comes from accepted ShapeSpec, stuck telemetry uses the documented +X progress window, and debug targeting prefers explicit `DebugTarget` then a human racer.
- **R05 Studio/G0 Integration** — Studio uses exactly one selectable interactive harness. Default mode is `G0`; the Studio-only `M0HumanHarness` injects a temporary Player→RacerRuntime resolver into existing `StrokeRemoteTransport`. It does not implement D05 `RacerService`.
- **R06 Documentation Consistency** — repository status/docs were reconciled to the B17/G0 hard stop without claiming Studio acceptance.
- **R07 Core Review Fixes** — exact B12 outer payload validation and abuse work-ordering, complete B16 raw/physics/motor telemetry and environment gating, plus semantic DrawInputRect ownership were tightened.
- **R08 Final Core Closure** — touch layout changes only between strokes; the normal Roblox Character is isolated from G0 physics before racer spawn; server enforces `MinUsefulLegExtent = 0.7`; anti-stall is bounded, actual-contact based, canonical-tag based and visible as `antiStallActive`.
- **R09–R12 (R10, R11, R12 explicitly retained)** — accepted-preview semantics, drawing UI bounds, long-stroke compaction, hybrid input isolation and G0 respawn isolation are CLOSED at implementation/regression level.

Historical repository evidence is retained for regression traceability:
- pre-R06 baseline: **66 passed, 0 failed**;
- R09 bounded repair: **80 passed, 0 failed**;
- R10–R12 code head `e2bedd34696bb99da43878c19d7984c9134c8bef`, run `34363706915` → **88 passed, 0 failed**;
- historical pre-R16 cursor was **B17 — G0 HUMAN_GATE — Studio PASS PENDING**.

## R14 pre-G0 runtime/evidence closure
**R14.1–R14.11 are CLOSED at implementation/contract/CI/documentation level; Studio checkpoints: HUMAN PENDING.**

The active guarantees remain: authoritative accepted preview points, Studio-only G0 presentation harness, aggregated Studio gate runner, bounded pending/network failures, same-runtime recovery, atomic redraw rollback, player-safe validation copy, pinned Rojo build in CI, and shared `StrokeTypes`/`RemoteNames` ownership.

Historical R14 code/tooling evidence is retained: head `8a6a05a31427346d2a1437820ffa759f21fca90c`, run `34387618626` → **120 passed, 0 failed**, successful **Rojo build**. B17/G0 remained HUMAN_GATE and Studio checkpoints: HUMAN PENDING.

## R15/R15.1 historical planar correction
**R15.1 IMPLEMENTED/AUTOMATED GREEN; its orientation detail is superseded by R16.1.**

The first R15 Studio attempt failed with live `laneDeviation 5.199`, proving the finite-force Z follower was insufficient. R15.1 replaced it with the current mechanical `PlaneConstraint` lane lock. That lane-plane mechanism remains valid and owned by `RacerStabilizer`.

Historical R15.1 automated evidence is retained: head `be44304bf00391e05c7d7750609730a7368ebc87`, run `34394991926` → **125 passed, 0 failed**. Human solver/physics acceptance remained HUMAN STUDIO PENDING and B17/G0 remained PENDING.

R15/R15.1 historically left world-Z body rotation free via `PrimaryAxisParallel`; **that orientation contract is no longer current**. R16.1 supersedes it with full upright-body correction while retaining physical X/Y translation and the mechanical Z plane.

## R16 Stage A — reference mechanical parity
**R16 Stage A / R16.1–R16.4: IMPLEMENTED/AUTOMATED GREEN; Studio Gate A — HUMAN STUDIO PENDING.**

Current canonical Stage-A contract:
- **R16.1 Upright Body** — X/Y body translation remains physically free; Z translation remains mechanically lane-locked; rotation about world X: locked/corrected; rotation about world Y: locked/corrected; **rotation about world Z: locked/corrected**. Only the legs intentionally rotate for locomotion. `AlignOrientation` uses `AllAxes` with an identity attachment basis.
- **R16.2 Hub Position** — `PhysicsConfig.LegGeometry` is the sole numeric owner: `HubOffsetX = 0.0`, `HubOffsetY = -0.35`, `HubOffsetZAbs = 1.62`; runtime consumes those values symmetrically.
- **R16.3 / R16.3A One drawing → Two legs / Reference Shape Centering** — after clamp/dedupe/simplify/resample, the server translates the cleaned bounds center to `(0,0)` without scaling, mirroring or rotating. The resulting **centered authoritative shape** is the ShapeSpec returned to accepted preview and duplicated as the same XY geometry on Left/Right. Drawing the same figure at different locations inside DrawInputRect must therefore produce the same physical geometry; changing the figure size still changes physical radius.
- **R16.4 Twin-leg Phase** — both legs use the same locomotion direction; initial right-minus-left phase is `180° ±1°`; accepted redraw preserves each side's live phase rather than restarting the gait.

R16.3A explicitly supersedes the earlier raw-canvas-offset interpretation from pre-R16 doc 73. No automatic spoke from hub to first point is introduced.

Stage-A automated evidence before Stage-B work: head `81c7d84c542160f07fc4fe986df89e5aa69f8f73`; `Contract Verify` run `34448666472` → **142 passed, 0 failed**, Rokit install PASS, **Rojo build PASS**. This is repository evidence only and does not satisfy Studio physics/human acceptance.

## R16 Stage B authorization
**Stage B implementation authorized by Product Owner on 2026-09-10. Studio Gate A remains HUMAN STUDIO PENDING.**

This is a bounded process override, not a fabricated acceptance result. It authorized implementation/instrumentation work for `R16.5 → R16.7` while Stage-A live solver evidence remains pending. It does **not** authorize claiming that Stage A, Stage B, B17/G0, obstacle niches, or reference feel have passed without Roblox Studio evidence.

## R16 Stage B — feel/evidence implementation
**R16.5–R16.7: IMPLEMENTED/AUTOMATED GREEN; Studio Gate B — HUMAN STUDIO PENDING. Studio Gate A remains HUMAN STUDIO PENDING.**

Repository-level implementation now includes:
- **R16.5 Motor / Grip / Mass Feel instrumentation** — current production motor values remain `AngularVelocity=-8`, `MotorMaxTorque=35000`, `MotorMaxAcceleration=120`; existing leg material values were moved to the single `PhysicsConfig.PhysicalMaterials.LegSegment` owner without changing their numbers. `R16B` Studio harness measures `ROUND_01` only after stable contact, ignores 2 s, measures 3 s, requires +X average `4.0–7.0 studs/s`, motors enabled and `antiStallActive=false`. No motor/torque/friction value has been tuned blindly without Studio evidence.
- **R16.6 Vertical Physics evidence path** — normal locomotion remains solver-owned in Y; `RacerStabilizer` does not write body Y/CFrame/velocities and anti-stall remains X-only. The Stage-B harness records `HOOK_01` maximum Y rise on `SmallSteps` and `SMALL_ROUND_01` Y fall on `GapSmall` using bounded evidence thresholds.
- **R16.7 Reference Shape Matrix** — executable canonical shapes include `ROUND_01`, `LONG_BAR_01`, `SMALL_ROUND_01`, `HOOK_01`, `ASYM_01`, `SUBOPTIMAL_01`. The Studio harness runs identical-reset comparisons for flat/steps/gap/tunnel and reports the approved niche checks: steps `+4 studs` or one higher step, gap landing or `+2 studs`, tunnel completion or `+6 studs`, SUBOPTIMAL at least `20%` worse, plus `noUniversalWinner`.
- Studio harness selection gained `R16B`; default remains `G0`, so normal G0 behavior is not silently replaced.
- Canonical obstacle geometry was not changed during Stage-B instrumentation.

Latest Stage-B automated code evidence before Stage-C work: head `2197882e4c641e7c1d17a6dfc538f23fd1a521e6`; `Contract Verify` run `34451426807` → **145 passed, 0 failed**, Rokit install PASS, **Rojo build PASS**. These are repository/build facts only. They do not prove the live Roblox solver meets the speed/niche thresholds.

## R16 Stage C authorization
**R16 Stage C implementation authorized by Product Owner on 2026-09-10. Studio Gate A and Studio Gate B remain HUMAN STUDIO PENDING.**

The Product Owner explicitly requested that repository implementation continue through **R16.8–R16.10** before the next Roblox Studio launch. This bounded override authorizes code/tests/evidence harness work only. It does not retroactively pass Studio Gate A, Studio Gate B, Studio Gate C, B17/G0, reference feel, obstacle niches, or live solver behavior.

## R16 Stage C — redraw/camera/canonical-pass implementation
**R16.8–R16.10: IMPLEMENTED/AUTOMATED GREEN; Studio Gate C — HUMAN STUDIO PENDING. Studio Gate A — HUMAN STUDIO PENDING. Studio Gate B — HUMAN STUDIO PENDING.**

Repository-level implementation now includes:
- **R16.8 Redraw parity** — B14 performs 10 redraws while the racer has live motion state, proving each accepted redraw advances ShapeVersion, leaves exactly two leg models, removes retiring state, preserves body CFrame/linear/angular velocities at commit time, and preserves each side's live phase within `5°`.
- **R16.9 Reference camera/presentation** — the Studio G0 presentation camera uses the approved side-oriented framing; the observer Roblox Character is hidden for the test presentation and its transparency is restored on teardown. The debug body proxy remains anchored, non-colliding, non-touching, non-querying and massless, so presentation does not enter racer physics.
- **R16.10 Canonical obstacle pass harness** — selectable Studio mode `R16C` reuses the exact Stage-B evidence path, verifies all unchanged canonical pieces `FlatShort`, `SmallSteps`, `SingleWallLow`, `GapSmall`, `LowTunnelWide`, adds explicit Wall evidence with HOOK/LONG_BAR, and performs 10 Heartbeat-spaced live redraws through the authoritative `LegShapeService` path. The final harness observes the existing lab and does not create or rewrite obstacle Parts.
- Default Studio harness mode remains `G0`; `R16C` is an explicit evidence mode, not a production movement owner.

Final R16.10 code/tooling evidence before this documentation reconciliation: head `3838a994f5b5164b64f3cdee934e5bc84f7be7a4`; `Contract Verify` run `34454820796` → **149 passed, 0 failed**, Rokit install PASS, **Rojo build PASS**. These facts prove repository contracts/buildability only; they do not prove Roblox solver or visual acceptance.

## Current implementation/evidence cursor
**R16 Stage C implementation is repository-complete through R16.10. Studio Gate A — HUMAN STUDIO PENDING. Studio Gate B — HUMAN STUDIO PENDING. Studio Gate C — HUMAN STUDIO PENDING. B17/G0 remains HUMAN_GATE PENDING.**

The next Roblox Studio launch is intentionally a combined evidence pass after R16.10, matching the Product Owner override. No Studio gate is silently marked PASS by automation.

### Studio Gate A evidence still required
Verify current `main` locally:
- Studio Play reaches `[StudioGate] TOTAL 13 PASS / 0 FAIL` then `READY` with no red DrawRacers runtime error;
- B10 upright/lane regression passes under the live Roblox solver;
- normal `laneDeviation <=0.03`; unexplained excursion `>0.08` is FAIL;
- body normal angular deviation `<=1°`; injected strong-contact disturbance stays `<=3°` and returns to `<=1°` within `0.25 s`;
- body still moves/rises/falls in X/Y from real physics rather than a scripted position lock;
- hubs remain symmetric/fixed at the configured offsets and the body does not continuously scrape flat solely because of axle placement;
- one accepted drawing visibly creates exactly two matching physical legs;
- the same-size shape drawn at different DrawInputRect positions recenters to the same accepted/physical geometry, while different drawn sizes remain different sizes;
- left/right gait is visually consistent with the recorded 180° phase contract and redraw does not visibly reset phase;
- observer Roblox Character remains non-participating in racer physics.

If only `HubOffsetY=-0.35` fails hub calibration while the rest of Stage A passes, the R16 design permits the explicit bounded `-0.75 / -0.35 / 0.0` comparison before any motor-value change is accepted.

### Studio Gate B evidence still required
Use the Studio-only `R16B` evidence path, directly or via the Stage-C `R16C` aggregate, and record:
- `[DrawRacers][R16.5] ROUND_01 FlatShort ...` with speed `4.0–7.0`, motors enabled and anti-stall false;
- `[DrawRacers][R16.6] HOOK_01 SmallSteps ...` proving real positive Y rise;
- `[DrawRacers][R16.6] SMALL_ROUND_01 GapSmall ...` proving real gravity-driven Y fall;
- `[DrawRacers][R16.7] matrix ...` with steps/gap/tunnel/suboptimal/noUniversalWinner all true.

If R16.5 speed is outside target, tune only the next permitted family in order: AngularVelocity → torque/acceleration only if needed → leg grip → body material only if still required. Re-run the same measurement after each single-family change. Do not alter obstacle geometry to manufacture a pass.

### Studio Gate C evidence now required
Run the Studio-only `R16C` harness on current `main` and record:
- `[DrawRacers][R16C] final reference-parity harness ready`;
- Stage-B evidence lines from R16.5–R16.7 without runtime errors;
- R16.10 Wall evidence showing at least one approved Wall shape completes the canonical wall trial;
- R16.10 live-redraw evidence after 10 redraws with `movingRedrawPassed=true` and positive progress;
- final `[DrawRacers][R16.10] canonical pass ... PASS`;
- visually, side-view framing keeps the racer readable and the Roblox observer is absent from the reference shot;
- then return to normal `G0` mode for the human feel check: upright body, physical X/Y motion, mechanical Z lock, reference-like leg behavior, redraw continuity and no DrawRacers runtime errors.

A failure in any one of these items keeps the corresponding gate PENDING and opens only a bounded R16 repair. It does not authorize unrelated M0.5/multiplayer/meta work.

## R16.11 documentation/evidence freeze
**R16.11 must not freeze before Studio Gate C is actually recorded from Roblox Studio evidence.**

R16.11 may synchronize final numbers, selected tuning values, screenshots/log evidence and gate status only after the combined Studio pass. Until then, R16.11 remains pending and the current docs intentionally preserve Studio Gate A/B/C as HUMAN STUDIO PENDING.

## Empirical G0 still required
R16 completion itself does not pass B17. `55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md` still requires the fixed G0 evidence, including **6 unique external testers**. A local developer playtest is necessary technical evidence but is not the six-tester empirical gate.

## Development execution workflow — ACTIVE
A repository-process decision was approved on 2026-09-10 for the current ChatGPT-driven workflow. This does **not** change gameplay scope or R16 gate state.

Current execution topology:

```text
ChatGPT remote GitHub main
-> user git pull on PC
-> Rojo (`default.project.json`)
-> Roblox Studio human acceptance
-> evidence back to ChatGPT
```

Bugfixes now default to `INVESTIGATE / PLAN ONLY` under `BUGFIX_PROTOCOL.md`. No GitHub write occurs until the user approves the bounded plan. After approval, the plan becomes the scope contract; implementation uses meaningful RED→GREEN, regression/full verification, diff audit, direct-main commit and fresh CI. `/review` follows `REVIEW_PROTOCOL.md` and is read-only. `AI_WORKFLOW_QUICKSTART.md` owns the copy/paste prompts and local PowerShell/Rojo handoff.

Remote GitHub execution cannot assert that the user's local `C:\Dev\DrawRacers` worktree is clean. The user checks/protects local changes before pull. One task must not be concurrently implemented by remote GitHub and a local coding agent.

Decision owner: `DECISION_LOG_REMOTE_GITHUB_BUGFIX_WORKFLOW_2026-09-10.md`.

## Audit notes / remaining risk
Current layering remains aligned with the architecture: Bootstrap is composition root; `LegShapeService` owns authoritative shape processing; `RacerRuntime` owns body/legs/stabilizer/anti-stall lifetime; `StrokeRemoteTransport` remains transport-only; no early D05 `RacerService` exists.

The dominant unresolved risk is live Roblox Studio solver/feel evidence. CI and static contracts prove ownership/buildability but cannot prove measured speed, obstacle niches, camera readability or human acceptance.

## HARD STOP
No C01, M0.5, multiplayer, meta, economy, shop, or later implementation may begin until the ordered R16 Studio evidence is completed and B17/G0 is explicitly recorded PASS or the Product Owner records another bounded gate decision.

## Next permitted task
**Run one combined Roblox Studio evidence pass on current main: first `R16C` for Stage-B/Stage-C measurements, then restore `G0` for the human reference-feel check. Record PASS/FAIL evidence; only bounded R16 repair or R16.11 evidence freeze may follow.**
