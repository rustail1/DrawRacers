# 75 — BOT SHAPE POLICY & BEHAVIOR CATALOG
Статус: **EXACT FAIR BOT STARTING POLICY v1.3.4**.

Цель: production Bot Fill должен быть реализуем без вопроса «какую форму и когда выбирает бот?». `40` owns product constraints, `73` owns exact preset coordinates, this file owns deterministic decision policy and starting difficulty profiles.

## 1. Fairness invariant
Bots submit the same legal ShapeSpec input through `LegShapeService` and use identical racer physics. `PaceScale` never changes motor speed, torque, friction, collision radius, checkpoint rules or forward assist. It scales only think/reaction timing.

No post-GO dynamic rubber-band based on current placement.

## 2. Launch profiles
| Profile | Base reaction delay | Mistake rate per decision | PaceScale |
|---|---:|---:|---:|
| EASY | 1.00s | 0.20 | 0.92 |
| MEDIUM | 0.70s | 0.12 | 1.00 |
| HARD | 0.50s | 0.06 | 1.05 |

Effective decision delay = `BaseReactionDelay / PaceScale`.

Public missing-slot profile sequence, assigned in bot slot order and fixed for whole heat:
`[EASY, EASY, MEDIUM, MEDIUM, MEDIUM, HARD, HARD]`.
If N bots are needed, use first N entries. FTUE uses EASY for every bot except when >=4 bots are present, the last bot may be MEDIUM.

## 3. RequirementTag → preset mapping
Canonical preset IDs come only from `73`:
- `FAST_ROLL` → `ROUND_01`
- `STABLE_CONTACT` → `ROUND_01`
- `BOUNCE_CONTROL` → `ROUND_01`
- `LONG_REACH` → `LONG_BAR_01`
- `GAP_BRIDGE` → `LONG_BAR_01`
- `HOOK_CLIMB` → `HOOK_01`
- `SMALL_CLEARANCE` → `SMALL_ROUND_01`
- `TIMING_MOVING` → retain current geometrically compatible preset; timing logic controls submit moment. If current geometry is incompatible with another primary requirement on the same piece, choose that primary requirement mapping first.
- no/unknown requirement → `ROUND_01`.

A TrackPiece can expose one `PrimaryRequirementTag`; secondary tags are diagnostic. Bots never infer hidden geometry outside TrackDefinition metadata.

## 4. Exact launch TrackPiece primary tags
| PieceId | PrimaryRequirementTag | Bot preset result |
|---|---|---|
| FlatShort | FAST_ROLL | ROUND_01 |
| FlatLong | FAST_ROLL | ROUND_01 |
| MicroBumps | STABLE_CONTACT | ROUND_01 |
| RollingHills | STABLE_CONTACT | ROUND_01 |
| SmallSteps | LONG_REACH | LONG_BAR_01 |
| TallSteps | HOOK_CLIMB | HOOK_01 |
| StairUp | HOOK_CLIMB | HOOK_01 |
| StairDown | STABLE_CONTACT | ROUND_01 |
| SingleWallLow | HOOK_CLIMB | HOOK_01 |
| SingleWallHigh | HOOK_CLIMB | HOOK_01 |
| GapSmall | GAP_BRIDGE | LONG_BAR_01 |
| GapMedium | GAP_BRIDGE | LONG_BAR_01 |
| BrokenPlatforms | GAP_BRIDGE | LONG_BAR_01 |
| LowTunnelWide | SMALL_CLEARANCE | SMALL_ROUND_01 |
| LowTunnelSteps | SMALL_CLEARANCE | SMALL_ROUND_01 |
| CeilingTeeth | SMALL_CLEARANCE | SMALL_ROUND_01 |
| VValley | LONG_REACH | LONG_BAR_01 |
| NarrowPit | LONG_REACH | LONG_BAR_01 |
| AlternatingBlocks | STABLE_CONTACT | ROUND_01 |
| RampUp | STABLE_CONTACT | ROUND_01 |
| RampDownIntoGap | GAP_BRIDGE | LONG_BAR_01 |
| MovingGate | TIMING_MOVING | retain current geometry / timing policy |
| MovingPlatformGap | TIMING_MOVING | retain current compatible geometry; GAP_BRIDGE secondary |
| FinishSprint | FAST_ROLL | ROUND_01 |

These values populate `PrimaryRequirementTag` in `30`; a template/config mismatch fails content validation.

## 5. Lookahead / decision point
Bot inspects only the current piece and next piece metadata available server-side. A planned redraw decision is scheduled when racer reaches `12.0 studs` before next piece `Start` and the next PrimaryRequirementTag maps to a different canonical preset than current.

If piece approach is shorter than 12 studs, schedule at the earliest safe previous recovery/entry point. Bot never submits a redraw after passing the piece Start solely to gain impossible reaction advantage.

## 6. Mistake behavior
At each planned requirement-transition decision, seeded RNG sampled once:
- if random < profile MistakeRate, submit `SUBOPTIMAL_01` after the same reaction delay;
- otherwise submit mapped correct preset.

`SUBOPTIMAL_01` is legal and safe but not intentionally impossible. A mistake does not modify motor/physics or teleport. Seed = server heat seed + bot slot stable derivation; fixed before GO for reproducibility.

## 7. Timing-moving behavior
For `TIMING_MOVING`, bot uses identical obstacle phase state to humans. Starting policy:
- target first opening interval whose predicted center occurs after bot reaches decision zone;
- wait so current racer reaches obstacle entry near opening center;
- minimum wait obeys reaction delay;
- no knowledge of future random state beyond authoritative deterministic movement schedule already defined by TrackSnapshot.

This is a simple launch policy, not a perfect solver.

## 8. Stuck correction
Bot uses same stuck detector/recovery as humans.
- On first redraw-hint threshold, if current preset is not mapped for current PrimaryRequirementTag, schedule one corrective mapped redraw after profile reaction delay.
- If current preset is already mapped, no extra perfect rescue redraw occurs.
- Auto-respawn follows `16/74` exactly.

Per requirement transition: maximum one planned redraw + maximum one stuck correction. No per-frame/redraw spam.

## 9. Starting shape
At PREP bots submit their planned shape through the same legal path:
- if first TrackPiece has a requirement mapping, use it;
- otherwise `ROUND_01`.
Human racers do not receive this bot convenience/default shape.

## 10. Presentation / analytics
Bot markers remain `BOT #N` per `40/59`. Bot events are marked `isBot=true` and excluded from human FTUE/retention/payer metrics. A separate BotHeat diagnostic may record profile, preset decisions, mistakes, finish and stuck count.

## 11. Tuning
Bot profile constants may move only after finish-distribution review and must not create a hidden race advantage. G2/G3 guardrails:
- new human should have credible chance not to finish last;
- bot win rate is diagnostic, not a target guaranteed by dynamic adjustment;
- no profile may exceed human physical envelope.

## 12. Acceptance
PASS if a fixed HeatSeed reproduces the same bot decision/mistake sequence; profile never changes after GO; PaceScale cannot change physics; every submitted shape matches `73`; no bot can consume rewards/purchases/player status; and 1–7 missing public slots fill deterministically.
