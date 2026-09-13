# CORE REPAIR V2 DECISION LOG — G0 VIDEO CONTRACT CHANGE

Feature: M0 mechanical core / drawing-to-locomotion contract  
Date: 2026-09-14  
Owner: Product + Mechanical Core  
Status: **DIRECTION APPROVED / DETAILED SPEC REVIEW PENDING**

## Problem / WHY

The first real G0 gameplay video after MR-01..MR-06 is a **human-gate FAIL** even though repository automation is green. The recording shows repeated fall/recovery episodes, visible body roll, oversized rotating arcs for long/asymmetric strokes, poor causal readability between the canvas and the physical pivot, and camera follow continuing below the useful track view.

This means the implementation is internally consistent with the current written contract, but parts of that contract are wrong for the intended game feel. In particular, the current combination of first-point-hidden pivot semantics, one shared central axle, Z-separated duplicate legs, fixed `-8 rad/s` motor speed, soft upright alignment, and destructive hub-to-tip physical redraw does not produce the intended creature-like two-leg locomotion.

This is therefore a **CONTRACT_CHANGE**, not a numeric bugfix.

## Scope gate

Core drawing/leg locomotion is already present and is the current M0/G0 gate. This decision changes only the mechanical core and the minimum presentation/recovery behavior required to expose it honestly.

In scope:
- DrawCanvas mechanical pivot semantics;
- canonical shape origin semantics;
- per-leg drive/pivot ownership;
- pair synchronization;
- leg speed control;
- upright stabilization;
- redraw collision handoff;
- G0 camera/recovery containment;
- tests/docs needed to make those owners exact.

Out of scope:
- race meta, matchmaking, rewards, economy, monetization;
- track catalog redesign;
- rider/cosmetics redesign unless a later human video proves a separate defect;
- scripted shape recognition or obstacle-specific movement cheats.

## Decision / WHAT

The mechanical core will be rebuilt around **two visible fixed pivots in the gameplay XY plane** instead of one shared central axle.

Canonical flow becomes:

`DrawingController -> CanonicalLegShape -> LegShapeService -> RacerRuntime -> LegPairAssembly -> 2 x LegDriveAssembly -> 2 x LegAssembly`

Key product behavior:
1. The draw surface exposes a fixed pivot marker. A gameplay stroke must begin near that marker. The pivot is no longer hidden inside first-point translation.
2. Canonical shape coordinates stay pivot-local. The canonical builder may snap a valid first sample to `(0,0)`, but it must not translate the entire drawing by an arbitrary first-point offset.
3. The cube has two mechanical pivots on its visible left/right edges in the side-view gameplay plane: body-local X `-BodySize.X/2` and `+BodySize.X/2`, both at Y=0/Z=0.
4. Each side has one independent `LegDriveAssembly` containing one hinge motor. `LegPairAssembly` owns only pair coordination, the 180-degree phase relationship, speed target and redraw transaction.
5. `LegAssembly` remains geometry-only. It does not own motors, phase policy, network state, recovery destination or camera behavior.
6. Motor speed is extent-aware: the target is bounded leg-tip linear speed, not one fixed angular velocity for every shape.
7. Body orientation is arcade-upright. Leg torque may move the body in X/Y but must not visibly tumble the cube as normal locomotion.
8. Redraw becomes a staged visual + atomic physical transaction. Old physical geometry stays active until the new geometry has a collision-safe mounting offset and is ready to commit. No temporary removal of all useful support.
9. Authoritative ShapeVersion is published only after physical commit succeeds. A pending redraw cannot be superseded by another submit.
10. Camera remains presentation-only and may clamp its vertical follow floor so a failed racer can fall without dragging the whole camera under the course. Recovery remains a gameplay/runtime decision, not a camera decision.

## Superseded mechanical decisions

For the mechanical core only, this decision supersedes the conflicting parts of:
- `DECISION_LOG_R16_3B_STROKE_ORIGIN_REFERENCE_PARITY_2026-09-10.md` — first-point translation as the hidden mechanical origin;
- `DECISION_LOG_R17_SHARED_AXLE_CAMERA_FIDELITY_2026-09-11.md` — one shared axle / one motor / Z-separated side sockets;
- `DECISION_LOG_R17_OPPOSED_LEG_PHASE_2026-09-12.md` where it assumes the shared-axle physical topology.

Security/network authority, 2.5D X/Y gameplay, lane Z lock, shape-driven collision locomotion, raw semantic input, and server-authoritative ShapeSpec remain intact.

## Alternatives considered

1. **Tune the existing shared axle only.** Rejected: it may reduce violence but does not fix hidden pivot readability or the visual/physical topology that makes the legs read like a wheel/motorcycle.
2. **Keep one shared axle but move the two side copies in X.** Rejected: one rigid axle cannot make two independent rotations around two different X pivots.
3. **Use scripted/kinematic fake legs or obstacle-specific movement.** Rejected: it weakens the core promise that actual player-drawn geometry causes movement.
4. **Twin fixed pivots + two bounded motors + pair synchronization.** Chosen: it matches the intended side-view creature-leg read while preserving real collision-driven locomotion and clear module ownership.

## Why chosen

The twin-pivot design fixes the observed defects at their common root rather than layering special cases on the old topology. It also produces clean ownership boundaries:
- canonical math owns shape semantics;
- drive owns one physical pivot/motor;
- pair owns only cross-leg policy;
- leg owns only geometry;
- runtime owns racer lifecycle/transaction publication;
- service owns network/security authority;
- camera owns presentation only.

## Constraints / invariants

- Server remains authoritative over accepted ShapeSpec/version.
- SubmitStroke remains semantic raw input; client does not send Instances/CFrames/motor state.
- One accepted stroke still defines the common geometry used by both legs.
- Two drive roots are persistent for the racer lifetime; normal redraw does not replace motors/pivots.
- Right drive target phase is left + 180 degrees; correction is bounded and never implemented by body teleport or per-frame CFrame snapping.
- Body X/Y remain physical. Z remains lane-constrained.
- Redraw never resets body CFrame/linear velocity/angular velocity solely because a shape changed.
- No obstacle-specific movement code.
- No human Studio PASS may be inferred from repository tests/build.

## Numbers

Exact numeric values remain owned by `16_BALANCE_TUNING.md`. CORE REPAIR v2 will introduce starting hypotheses there only after detailed spec approval. Initial engineering targets for review are:
- smaller leg world scale than current 4.8/6.9;
- bounded target tip speed rather than fixed `-8 rad/s`;
- 180-degree pair relationship with bounded correction;
- short redraw transaction comfortably below the existing client result timeout.

These are tuning hypotheses, not acceptance claims.

## Acceptance criteria

- [ ] DrawCanvas shows the real gameplay pivot and off-pivot starts are rejected consistently client/server.
- [ ] Canonical builder no longer hides screen placement by translating the full shape to its first point.
- [ ] Exactly two persistent drive hinges exist, one per visible X-side pivot; no production shared central axle remains.
- [ ] Both legs use the same canonical geometry and maintain the intended 180-degree relation without CFrame chasing.
- [ ] Long shapes rotate materially slower than short shapes under the tip-speed cap.
- [ ] Normal flat play does not visibly roll/tumble the cube.
- [ ] Redraw keeps old physical support until a safe atomic commit; no launch/teleport/velocity reset.
- [ ] ShapeVersion/result success is published only after the new physical geometry is committed.
- [ ] Camera does not follow a failed racer deep below the track.
- [ ] Full repository contracts + Rojo build pass on the exact implementation HEAD.
- [ ] Fresh human G0 video passes the explicit CORE REPAIR v2 Studio checklist.

## Measurement

Primary evidence is G0 human Studio video plus debug telemetry:
- recovery count on flat;
- body roll error;
- left/right phase error;
- actual motor angular velocities and effective leg extent;
- redraw commit/reject reason;
- flat speed and obstacle traversal observations.

## Result after implementation

Pending. This decision authorizes design/planning only until the detailed CORE REPAIR v2 spec is reviewed.

## Follow-up / rollback condition

If twin-pivot real-physics locomotion still cannot produce stable, understandable flat movement after bounded speed/upright tuning, stop adding patches and re-open the locomotion architecture before building later race/meta systems. Do not restore the old shared-axle contract merely to regain green static tests.
