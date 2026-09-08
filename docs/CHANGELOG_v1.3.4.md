# CHANGELOG v1.3.4 — EXECUTION CONSISTENCY FREEZE

Date: **2026-09-03**  
Status: **final documentation-consistency pass before implementation**.

This revision does not add a new gameplay pillar. It closes cross-document execution ambiguities found after the previous final-audit pass so a programmer/Codex can follow one dependency-safe path from empty repository to public release without inventing parallel temporary systems.

## 1. Bootstrap order fixed
- `SESSION` now matches `README/25/52/66`: **A01 → A02 → A03 → A04 → B01**.
- A04 deployment/config skeleton is mandatory before gameplay code can depend on environment/ID data.

## 2. M2 dependency graph rebuilt
The previous E-series allowed FTUE work before all systems FTUE actually consumes. Canonical order is now:

`E00 STAGING provisioning → E01 8 lanes → E02 T01–T10 → E03 readability → E04 PlayerDataService → E05 RewardService → E06 AnalyticsAdapter → E07 canonical BotRacerController foundation → E08 confirmed Results → E09 CosmeticService → E10 FTUE/routing → E11 Garage → E12 feedback → E13 settings → E14 performance/security gate`.

Consequences:
- no temporary FTUE save model;
- no temporary reward path;
- no uninstrumented FTUE funnel;
- no FTUE-only bot implementation;
- no FTUE acceptance before confirmed reward UI and Ink_Sky presentation exist.

`F05` extends the same E07 bot controller into public cold-start fill; it cannot create a second bot family.

## 3. Collision policy made singular
Canonical collision invariant across `03/11/28/65/73`:
- `RacerBody ↔ RacerBody = no`;
- `RacerBody ↔ RacerLeg = no`, including own assembly;
- `RacerLeg ↔ RacerLeg = no`;
- any racer body/leg ↔ another racer body/leg = no;
- `RacerBody/RacerLeg ↔ Track = collide`;
- Decoration is non-gameplay collision; Trigger is query/overlap only.

The previous ambiguous self-collision wording is removed.

## 4. Near-simultaneous finish ordering frozen
`74` now owns the exact valid-finish order:

`FinishAcceptedAt ASC → FinishSequence ASC → SlotIndex ASC`.

- values are server-only;
- client timestamps never break ties;
- `FinishSequence` is allocated once in the serialized finish-accept path;
- duplicate finish touches are idempotent;
- accepted placement is immutable for the heat.

`03/05/15/22` consume this rule.

## 5. FTUE DNF economy exploit closed
Canonical rule in `61`, consumed by `08/31/44/66`:
- T06 FTUE DNF = **0 persistent Coins**;
- **0 MP**;
- no FirstHeatBonus;
- no FirstTrackClear;
- no Tutorial completion;
- no cosmetic entitlement mutation.

Only the first authoritative T06 finish can commit FTUE reward/progression. Its starting reward is exactly the normal placement row + applicable first-valid-completion/first-T06-clear bonuses + MP finish/first-clear + Ink_Sky entitlement/equip in the same authoritative grant path.

## 6. Release reference repaired
`64` contained a stale release tuple that pointed at a nonexistent audit document. PROD public enable now requires **`35 + 57 + 78 PASS`** and the malformed nested-backtick sentence is corrected.

## 7. Numeric ownership wording repaired
`03` no longer claims every number lives in `16`. Canonical numeric ownership is explicitly split:
- global physics/race/camera → `16`;
- UI geometry → `59`;
- TrackPiece/tracks → `60`;
- economy/progression → `61`;
- shape/pivot/collider mapping → `73`;
- lifecycle semantics → `74`;
- bot behavior defaults → `75`.

## 8. Production handoff separated from history
The **production ZIP contains only current documents**. `_HISTORY` is kept in a separate archive and is not part of routine Codex/programmer ingestion. `manifest.json.current_documents` is the only allowed production-context list.

## 9. Final owner/audit
- The previous final audit is archived outside the production handoff.
- Current final audit: `78_FINAL_EXECUTION_CONSISTENCY_AUDIT_v1.3.4.md`.

## Result
v1.3.4 closes the known documentation-level dependency/contract contradictions discovered after the previous revision. Remaining unknowns are empirical implementation/live outcomes (feel, measured performance, PTR, retention, conversion, revenue) and already have starting defaults, measurement contracts, gates and rollback rules; they are not missing WHAT/WHY design decisions.
