# SESSION.md — CURRENT STATE

Date: 2026-09-10  
Documentation version: **v1.3.4 EXECUTION CONSISTENCY FREEZE**

## Product state
The product specification remains closed. CORE/pre-G0 repair **R01–R12** plus bounded runtime/evidence closure **R14.1–R14.11** stay inside the already-approved B03–B16/B17 scope; they introduce **no new WHAT/WHY** gameplay scope.

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
- **R03 Physics Contract** — complete semantic collision groups/matrix, 25° free-tilt stabilization window with no forward propulsion, M0 lab under `Workspace.Runtime.Tracks`, and tunnel geometry relative to `Lane.TopY`.
- **R04 Debug Correctness** — collider count reads real `Segments` folders, cleaned-point telemetry comes from accepted ShapeSpec, stuck telemetry uses the documented 2.5 s +X progress window, and debug targeting prefers explicit `DebugTarget` then a human racer.
- **R05 Studio/G0 Integration** — Studio uses exactly one selectable interactive harness. Default mode is `G0`; the Studio-only `M0HumanHarness` injects a temporary Player→RacerRuntime resolver into existing `StrokeRemoteTransport`. It does not implement D05 `RacerService`.
- **R06 Documentation Consistency** — repository status/docs were reconciled to the B17/G0 hard stop without claiming Studio acceptance.
- **R07 Core Review Fixes** — exact B12 outer payload validation and abuse work-ordering, complete B16 raw/physics/motor telemetry and environment gating, plus semantic DrawInputRect ownership were tightened.
- **R08 Final Core Closure** — touch layout changes only between strokes; the normal Roblox Character is isolated from G0 physics before racer spawn; server enforces `MinUsefulLegExtent = 0.7`; anti-stall is bounded, actual-contact based, canonical-tag based and visible as `antiStallActive`.
- **R09 Pre-G0 Consistency Review — CLOSED at implementation/regression level** — accepted preview state is semantic rather than layout-pixel state; exact doc-59 touch ValidationToast/DrawHint tokens reflow with DrawCanvas; obstacle `RequirementTag` overrides recovery assist; spawned racers discard the empty template-only `RuntimeAttachments` helper after moving its attachments onto `BodyCollider`.
- **R10 Drawing UI Contract Repair — CLOSED** — accepted preview thickness uses pointer family only while drawing and current layout family otherwise; `EmptyGhost` stays hidden after first pointer-down; `ValidationToast` auto-hides within 2.0 s and excludes `DrawHint`; unsupported `LastInputType` values do not force desktop layout.
- **R11 Hybrid Input / Preview Bounds — CLOSED** — LastInputType changes during a live stroke no longer overwrite stroke-owned layout intent, and live preview point/Frame growth is bounded using the existing stroke cap with compaction.
- **R12 Long-Stroke / G0 Respawn Isolation — CLOSED** — semantic sampling compacts instead of freezing at 96 points so later stroke geometry still contributes, and G0 Character respawn isolation no longer restores collision/query/touch on a retired Character.

## R14 pre-G0 runtime/evidence closure
**R14.1–R14.11 are CLOSED at implementation/contract/CI/documentation level; Studio checkpoints: HUMAN PENDING.**
- **R14.1 Shape parity** — server returns authoritative accepted ShapeSpec points and client accepted preview uses them.
- **R14.2 G0 presentation** — Studio-only non-physical camera/proxy harness is wired without introducing the future race camera owner.
- **R14.3 Studio gate runner** — synchronous specs aggregate failures and gate the interactive harness/client as `TESTING → BLOCKED/READY`; the injected failing-spec BLOCKED→restore→READY observation remains a Studio human checkpoint.
- **R14.4 Collision Default** — Default group geometry cannot push RacerBody/RacerLeg by collision-matrix contract; Studio physics confirmation remains pending.
- **R14.5 Network pending/failure** — pending requests are count/time bounded, late authoritative accepts remain eligible, and server processor exceptions fail safely.
- **R14.6 Recovery** — G0 kill-Y recovery resets the **same RacerRuntime** to canonical spawn, zeroes assembly velocity, and preserves authoritative `ShapeSpec`/`ShapeVersion`; gap/fall observation remains pending in Studio.
- **R14.7 Atomic commit rollback** — regression coverage includes partial commit failure and post-commit motor-enable failure; both preserve the prior accepted assembly and remove staged/retiring leakage.
- **R14.8 Validation UX** — true geometry errors show `DRAW A DIFFERENT SHAPE`; transport/technical limits show `TRY AGAIN`; internal reason codes remain debug-only.
- **R14.9 CI Rojo build** — CI installs the pinned Roblox toolchain and executes a real Rojo build after contract checks.
- **R14.10 Types/RemoteNames** — `StrokeTypes` owns the stroke/network/ShapeSpec boundary types used by active runtime modules, while active remote consumers and B12 Studio coverage use `RemoteNames` rather than duplicate literals.
- **R14.11 Docs/evidence reconciliation** — root/status/decision docs are aligned to the final verified R14 code/tooling evidence while preserving the B17 human hard stop.

Decision records: `DECISION_LOG_CORE_AUDIT_REPAIR_2026-09-09.md`, `DECISION_LOG_PRE_G0_REVIEW_R07_R09_2026-09-09.md`, `DECISION_LOG_PRE_G0_BUG_SWEEP_R10_R12_2026-09-09.md`, and `DECISION_LOG_PRE_G0_RUNTIME_CLOSURE_R14_2026-09-09.md`.

## Automated evidence
Historical evidence is intentionally retained:
- R01–R05 code/test head: GitHub Actions `Contract Verify` run `34336175789` → **66 passed, 0 failed**.
- R06 repository status reconciliation: commit `1269336b6754a7f9ea3172a1b99cddfe8fa276f7`, run `34337310421` → **68 passed, 0 failed**.
- R08 closure head: commit `3a0a32ce90f2cfcd2f37e3be430758dacc86d6d3`, run `34349254516` → **77 passed, 0 failed**.
- R09 RED: commit `35c4df76dd4d663e4785bcb295fda357b8c48ef9`, run `34351760319` → **77 passed, 3 failed**, exposing all three newly recorded gaps.
- R09 bounded repair: commit `3d414556677577af6b07ff253b97041c0eb59c30`, run `34352130204` → **80 passed, 0 failed**.
- R10 RED: commit `1a49337ae6a5cce144f666fb7178822bb7cdff15` exposed four drawing UI contract gaps; repair commit `83b532c60824cb3302ee16da91357ad4fe2e584f` closed them.
- R11/R12 follow-up bug sweep completed on final code head `e2bedd34696bb99da43878c19d7984c9134c8bef`; run `34363706915` → **88 passed, 0 failed**.
- R14.1–R14.10 final code/tooling evidence head `8a6a05a31427346d2a1437820ffa759f21fca90c`; GitHub Actions `Contract Verify` run `34387618626` → **120 passed, 0 failed**, with successful **Rojo build** of `DrawRacersDev.rbxlx`.
- R14.11 evidence-drift RED commit `0d8a6b85b5184bc053275d3441daa103af3e22c2`; run `34388536445` → **119 passed, 1 failed**, with the single failure proving status/evidence docs were stale against the final code/tooling head.

The current GitHub workflow runs `python verify.py` contract/static checks and then a real Rojo project build. It still does **not** execute Roblox Studio physics, touch interaction, presentation acceptance, or external-player acceptance, and therefore cannot satisfy B17/G0 by itself.

## Current implementation/evidence cursor
**B17 — G0 HUMAN_GATE — Studio PASS PENDING.**

**Studio checkpoints: HUMAN PENDING.**

The repository remains intentionally stopped at the M0 human gate. `StudioHarnessConfig.Mode` defaults to `G0`, so a local Studio Play session can exercise the real M0 path:

`DrawInputRect → DrawingController → SubmitStroke → StrokeRemoteTransport → LegShapeService → authoritative ShapeSpec → atomic physical legs → locomotion → redraw`.

### Studio evidence still required
Verify current `main` locally before any B03–B16 implementation is promoted:
- `git pull --ff-only`, `python verify.py`, and normal Rojo build/sync complete without project errors;
- Studio Play runs B03–B16 specs with no red DrawRacers runtime error;
- the Studio gate runner visibly reaches `READY` when all specs pass;
- for the R14.3 injection check, temporarily force one Studio spec to fail, verify gate state becomes `BLOCKED` and the interactive G0 harness/client drawing do not start, then restore the spec and verify `READY`;
- `[DrawRacers][B16] debug tuning panel tests PASS` appears;
- `[DrawRacers][G0] human harness ready` appears only after the gate is READY;
- only one interactive G0 racer/harness remains after synchronous specs;
- the normal Roblox Character is observer-only and cannot push/block the racer, including after Character respawn;
- drawing creates server-accepted physical legs and movement;
- accepted preview shape matches the authoritative server-accepted geometry;
- redraw while moving changes the accepted physical shape without teleporting/resetting body state;
- a sub-0.7 useful leg extent is rejected and leaves the old accepted shape intact;
- accepted preview remains semantically stable across layout changes between strokes and uses the current layout thickness after Touch/Desktop switching;
- after the first pointer-down `EmptyGhost` does not return on cancel/reject;
- validation feedback disappears within about 2 seconds, a newer validation is not cleared by an older timer, and `ValidationToast` does not overlap `DrawHint`;
- validation messages show player-facing copy rather than internal reason-code strings;
- unsupported input families such as Gamepad do not force DrawHUD into desktop layout, and LastInputType changes do not reflow a stroke in progress;
- a long/noisy stroke beyond the raw-point cap continues to incorporate later geometry through bounded compaction rather than freezing at the first 96 samples;
- touch layout uses the doc-59 DrawCanvas/ValidationToast/DrawHint positions and never reflows in-progress drawing;
- pending/network failure behavior does not accumulate unbounded requests and recovers after delayed/failed responses;
- Default/normal Character geometry cannot physically push RacerBody/RacerLeg;
- falling through the gap below `RecoveryKillY` resets the same racer to canonical spawn, preserves the accepted shape/version, and preserves the normal Character observer state;
- debug `simplifiedPoints`, `physicsPoints` and `colliderSegments` report real nonzero values after a valid shape;
- `antiStallActive` is bounded on flat/recovery contact and immediately false on obstacle/unknown collidable/airborne cases;
- M0 lab exists under `Workspace.Runtime.Tracks`, not as a second top-level gameplay root.

### Empirical G0 still required
After the local technical smoke, `55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md` still owns product acceptance: **6 unique external testers** and every fixed G0 criterion must PASS. A local developer playtest is useful evidence but is not the six-tester empirical gate.

## Audit notes / remaining risk
The R01–R12 repository pass plus R14 closure found no reason to introduce a new top-level service, manager, race system, or data owner. Current M0 layering remains aligned with `21`: Bootstrap is composition root; `LegShapeService` owns authoritative shape processing; `RacerRuntime` owns body/legs/stabilizer/anti-stall lifetime; `StrokeRemoteTransport` remains transport-only; no early D05 `RacerService` exists.

The known R09–R12 and R14.1–R14.11 implementation/documentation findings are CLOSED at repository level. The remaining gate risk is runtime/human evidence, not an open known repository defect from those findings.

CI includes Rojo buildability, but it cannot replace Roblox Studio execution or the human G0 test.

## HARD STOP
**B17/G0 remains a HUMAN_GATE.** No C01, M0.5, multiplayer, meta, economy, shop, or later implementation may begin until G0 is explicitly recorded PASS or the Product Owner records a bounded rework/scope decision allowed by the gate protocol.

## Next permitted task
**B17 — G0 HUMAN_GATE only.**