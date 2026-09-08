# 55 — EMPIRICAL PRODUCT GATE PROTOCOL
Статус: **HUMAN/PLAYER ACCEPTANCE CONTRACT v1.3.4**.

Purpose: remove “fun enough?”, “social enough?” and “do players want more?” as open-ended questions. The product direction is locked; this file fixes how evidence is collected, what counts as PASS, how many rework cycles are allowed, and when Product Owner escalation is mandatory. Numbers below are **project acceptance hypotheses**, not universal Roblox benchmarks.

## Global rules
- “External tester” = not the person who implemented the tested behavior and not coached on the expected answer.
- One tester may appear in several gates, but a gate must include the minimum unique tester count stated below.
- Observe behavior before asking opinion. Record build/device/track and raw counts.
- **Max implementation rework cycles per gate: 3.** A cycle must change the owner layer, not merely rerun identical content.
- After 3 failed cycles, Product Owner must record exactly one decision: `CONTINUE WITH KNOWN RISK`, `SCOPE CHANGE`, `PIVOT`, or `STOP`. No silent endless tuning.
- P0/P1 bug, data loss, exploit or performance failure can fail a gate regardless of survey score.

## G0 — M0 physical causality / redraw
Minimum: **6 unique external testers** on the five-obstacle lab.
Method: first attempt with only control instruction (“draw the wheel/leg”), then free retry.
PASS when all are true:
1. >=5/6 can explain at least two observed shape→movement differences without being told the answer.
2. >=4/6 voluntarily redraw at least once in response to obstacle geometry.
3. >=5/6 complete the basic flat + at least three non-flat obstacle cases without implementer intervention after first instruction.
4. zero reproducible P0 physics explosions/teleports from valid bounded strokes.
5. canonical shape telemetry shows visibly different behavior on at least four shape classes.
Owner on fail: `03/16/21` physics/input/stabilization; then repeat G0.

## G1 — M0.5 adaptation / anti-universal-shape
Minimum: **8 unique external testers**, mixed 30–45s route.
PASS when all are true:
1. >=6/8 make >=2 voluntary redraws for geometry reasons.
2. >=6/8 can correctly verbalize why at least one redraw helped.
3. no single canonical shape remains competitively viable across >70% of obstacle requirement families in the comparison protocol.
4. typical successful run is not redraw spam (>6 applies in a 30–45s route is a failure signal unless a specific track is intentionally authored that way).
Owner on fail: `04/16/42`, then physics only if level grammar cannot create differentiation.

## G2 — M1 social-value crossover
Minimum: **8 unique testers**, run as four pairs. Each tester completes two solo-equivalent races and two rival-visible races on matched tracks.
PASS when all are true:
1. >=6/8 prefer the rival-visible version for tension/fun or learning.
2. >=6/8 can identify at least one rival solution/failure without losing track of their own next obstacle.
3. own-obstacle failure rate attributable to visual obstruction is not >20% worse than solo-equivalent baseline.
4. no fairness/finish-authority/network P0/P1.
Owner on fail: `05/08/29` presentation first, `22/33` network/perf if measured. The 8-player product target remains locked unless Product Owner escalates after 3 cycles.

## G3 — M2 eight-player readability / fairness / performance
Minimum: **3 complete 8-slot sessions**, **8 unique external humans** total; at least 4 test runs on mobile reference classes from `57`. Bots may fill missing slots only after at least one all-human 8-player session has been run.
PASS when all are true:
1. >=80% post-race responses rate own racer + next obstacle readability >=4/5.
2. >=80% can state current/approximate placement during race without opening a separate menu.
3. rival shapes remain visible but do not cover the local decision surface in recorded clips.
4. `57` M2 thresholds PASS.
5. zero P0/P1, stable finish order/checkpoints, no racer-vs-racer collision.
Owner on fail: camera/HUD/LOD → physics/network → content density, in that order.

## G4 — repeat-session / novelty decay
Pre-soft-launch minimum: **8 unique external testers** with no forced rewards between races.
Pre-soft-launch PASS: >=6/8 voluntarily start at least a third race in the same session; median completed races >=3.
Soft-launch decision rule after >=500 new users: compare finish→requeue, races/session and D1 against the experience's own week-1 baseline and Creator Analytics benchmark/peer context when available. A sustained regression across two cohorts is REWORK even if acquisition is high. Do not invent a “good D1” from competitor visits.
Owner: `08/06/44` session/FTUE/meta; core identity changes still require Product Owner decision.

## G5 — free cosmetic/status desire before paid offer
Minimum: **8 unique external testers** after at least three races and with several free cosmetics/status examples visible.
PASS when all are true:
1. >=6/8 notice at least one other player's body/ink/trail/status without prompting.
2. >=5/8 voluntarily preview or equip a non-default free item.
3. zero cosmetic changes alter collider/motor/readability fairness.
Soft-launch guardrail: do not scale paid offers while free cosmetic preview/equip interaction is collapsing; diagnose presentation/value first.
Owner: `43/44/29/47`; monetization packaging only after free value is visible.

## G6 — discovery creative comprehension
Prelaunch: test at least **3 materially different creative hypotheses** from `38`; each must show the actual game, not a fabricated scene.
Comprehension check: minimum **12 external viewers**; >=10/12 must answer the one-frame promise substantially as “draw a shape/wheel/leg to race/pass obstacles.”
Platform experiment: when traffic permits, use Roblox's current experiment/analytics tooling; require enough impressions/conversions for the platform/statistical tool to distinguish a winner. If no winner, iterate creative rather than changing core automatically. Downstream first-draw/first-finish/second-heat guardrails must not worsen for a higher-PTR asset.
Owner: `38/46`; market precedent `54` is context, not a PTR guarantee.

## G7 — content/LiveOps production scalability
After config infrastructure exists, one developer/content author must produce:
- one new TrackDefinition from existing TrackPieces;
- one TrackPiece variant within schema;
- one cosmetic item/collection entry;
- one event/rotation config;
without adding a new top-level service or modifying unrelated gameplay code.
PASS if all four go from source asset/config to STAGING using documented pipeline and QA in <=1 working day total, excluding art creation time.
Owner on fail: `30/36/42/09` tooling/schema; procedural generation is still later-only until this bottleneck is measured.

## Gate record template
```text
Gate: G0..G7
Build / commit:
Date:
Unique testers / device distribution:
Tracks / variants:
Raw observations:
Metric counts:
P0/P1 bugs:
PASS / REWORK / ESCALATE:
Rework cycle: 0/1/2/3
Owner layer to change:
Decision Log link if escalated:
```
