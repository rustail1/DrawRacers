# 69 — CONTENT / ART / AUDIO PRODUCTION EXECUTION PLAYBOOK
Статус: **NO-GUESS CONTENT WORKFLOW v1.3.4**.

Цель: `62` says WHAT to produce; this file says in what order, what file/output is expected and when an asset is accepted.

## 1. Production order
1. collision blockout only (`60/67`);
2. racer default shell;
3. UI token kit/icons (`59/62/68`);
4. TOY_WORKSHOP modular kit;
5. T01–T10 visual pass;
6. NEON_FACTORY modular kit;
7. T11–T20 visual pass;
8. 20 cosmetic assets;
9. VFX set;
10. audio/SFX/music set;
11. Garage/podium presentation scenes;
12. logo/icon/thumbnail A/B/C/video templates;
13. optimization/provenance/import audit.

Do not polish later content while core screenshot/readability asset is blocked.

## 2. Asset states
Every asset in production registry uses:
`PLANNED → BLOCKOUT → REVIEW → ACCEPTED → UPLOADED → BOUND → RELEASE_VERIFIED`.
Only `RELEASE_VERIFIED` counts as complete for `62` launch checklist.

## 3. Source file naming
Source working file names may include version suffix, but exported/runtime semantic name follows `36/62`. Registry `70` records source path/hash/license/AssetId.

## 4. Track art acceptance
For each TrackPiece visual shell:
- collision screenshot overlay exactly matches intended blockout;
- all decor non-collidable;
- silhouette readable at race camera;
- theme palette/material rules pass;
- mobile polygon/texture/shadow budget passes `57`;
- no embedded scripts/untrusted metadata;
- clean-room provenance recorded.

## 5. Cosmetic acceptance
For each Body/Ink/Trail/FinishFX ID in `62`:
- exact semantic ItemId;
- correct slot/rarity/source;
- no collider/physics change;
- readable on both themes;
- rival-clutter limit pass at 8 racers;
- Reduce/Hidden rival detail path behaves;
- preview + equipped in next heat work;
- ownership persists after rejoin;
- asset registry/provenance complete.

## 6. UI art kit acceptance
Produce only reusable components/tokens, not flattened screenshots:
- panel 9-slice/light/dark;
- primary/secondary/disabled button states;
- chip/progress/lock/status visuals;
- exact icons listed in `62`;
- font/weight mapping;
- focus/hover/pressed/pending/disabled states;
- 59 screenshot matrix passes without ad-hoc per-resolution art.

## 7. VFX acceptance
Semantic keys:
`VFX_Shape_Accept`, `VFX_Shape_Reject`, `VFX_Finish_Pop`, `VFX_Finish_Confetti`, `VFX_Finish_Spark`, `VFX_Finish_NeonBurst`, `VFX_Finish_CrownBurst`, `VFX_Podium`.
VFX are client presentation only. Lifetime/opacity/readability limits = `62`; no reward success effect before confirmation.

## 8. Audio production acceptance
Produce exact semantic keys in `47` + two loops. Each SoundId goes through registry `70`. Check:
- loop seams;
- mobile speaker legibility;
- no clipping at 8-racer load;
- semantic volume hierarchy;
- settings mute immediate;
- original/licensed provenance.

## 9. Discovery asset acceptance
A/B/C compositions are produced exactly from `62` first. Export sizes follow current Roblox upload requirement at publishing time; master composition must preserve hook at small preview. No creative is called “winner” before G6.

## 10. Import rules
On upload/bind:
- correct owner/group;
- moderation status checked;
- runtime AssetId entered in `70` only;
- no duplicate upload unless source changed materially;
- imported model inspected for scripts/constraints/collision;
- compression/LOD adjusted without changing identity/readability.

## 11. Missing/rejected asset behavior
If an optional presentation asset fails moderation late, use canonical fallback from same slot/theme or hide optional effect; never substitute a random third-party asset. If required title/icon/default racer/TrackPiece collision asset cannot ship, release is blocked until replacement is approved/provenance-safe.

## 12. Acceptance
Content production is complete only when every required `62` row is `RELEASE_VERIFIED` in `70`, T01–T20 screenshots pass, all 20 produced cosmetics bind to canonical IDs, audio/VFX resolve without missing asset warnings, and `48` clean-room/provenance PASS.
