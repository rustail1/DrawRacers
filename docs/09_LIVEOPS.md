# 09 — LIVEOPS & CONTENT SCALE — v1.3.4

## Principle
Launch starts diagnosis. LiveOps should produce fresh combinations from systems already built; it must not require a new gameplay architecture every week.

## Extension surfaces
### Core
New TrackPieces, obstacle parameter presets, surface combinations, race pacing, authored TrackDefinitions.

### Social/session
Course rotations, weekly competitive challenges, tournament windows, friend/social goals after demand appears.

### Meta/persist
New collections, mastery milestones, status badges, seasonal rank rewards.

### Monetization
New cosmetic themes/bundles using existing preview/equip/grant infrastructure.

## Content that should require no new code after infrastructure
- TrackDefinition composition;
- obstacle parameter presets;
- track visual theme/material set;
- cosmetic definitions;
- reward tables;
- mastery/season objectives;
- rotation schedules;
- fair currency multipliers;
- localized event messaging.

## Event constructor
Exact config fields and referenced set schemas live **only** in `30_CONTENT_CONFIG_SCHEMAS.md`. Conceptually an event may select a course pool/rotation, fair rule modifiers, reward/objective sets, cosmetic collection, visual theme, localized messages and an optional clearly segregated leaderboard mode.

Rule modifiers must preserve competitive fairness unless an explicitly approved event is segregated into a special non-standard mode.

## Best-fit recurring formats
1. **Seasonal course rotation / tournament** — directly refreshes core.
2. **Theme + cosmetic collection + matching track presentation** — connects expression to play.
3. **Community race-completion/time goal** — social participation without inventing a new game.

Creator/admin spectacle only after community traction; do not build infrastructure because a format is fashionable.

## Six-month direction (not promise)
### Month 1
Stability, FTUE, physics/network tuning, first content refresh.
### Month 2
New obstacle pack + themed collection + weekly rotation.
### Month 3
Season/tournament layer if rematch/return behavior supports it.
### Month 4
Second course family + social/friend improvements based on data.
### Month 5
Community goal/live window experiment.
### Month 6
Major content pack only if core/product KPIs justify continued investment.

## Small-team capacity rule
Early live default:
- 45% planned content/experiments;
- 35% fixes/performance/networking;
- 20% UX/FTUE/quality.

Shift toward content only after stability.

## Measurement contract
Every update starts with:
`Signal → Problem hypothesis → Change → Primary metric → Guardrails → Segment → Method → Review date → Success criterion → Keep/Iterate/Rollback`.

## Feedback discipline
Player request is a signal, not task. Diagnose pain with observation + data before choosing solution.


## Launch content buffer owner
The concrete Day 0–30 launch buffer is frozen in `76_FIRST_30_DAYS_LIVEOPS_CONTENT_BUFFER.md`. H05 is not complete until those configs/objectives/rewards instantiate in STAGING data-only and rollback to the canonical `61` baseline without a code deploy.
