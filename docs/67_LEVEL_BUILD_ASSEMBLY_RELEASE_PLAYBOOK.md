# 67 — LEVEL BUILD: BLOCKOUT → 8 LANES → ART → RELEASE
Статус: **EXACT LEVEL PRODUCTION PLAYBOOK v1.3.4**.

Цель: level designer/Codex должен собирать launch уровни без самостоятельного изобретения workflow. `04` owns grammar, `42` authoring rules, `60` exact dimensions/T01–T20, `65` instance structure, `62` art themes.

## 1. One TrackPiece production procedure
For each of 24 canonical pieces:
1. create template with exact structure from `65`;
2. build collision-only geometry from the **exact top-profile/interval recipe** in `60` using Default values;
3. set Start at local origin facing +X; End at exact exit plane;
4. add checkpoint only if catalog marks it;
5. add recovery floor/respawn where required by `42/60`;
6. set attributes/RequirementTag;
7. run static validator: IDs, bounds, anchored state, collision groups, Start/End orientation, no forbidden scripts;
8. run five canonical-shape traversal test from `03/55`;
9. only after collision PASS add theme visual shell from `62`;
10. rerun silhouette/collision screenshot and performance check.

Art may never be used to rescue unreadable collision. Fix collision/readability owner first.

## 2. Piece snapping
TrackService composes pieces using the full rigid transform `previous.End → next.Start`, including **Y elevation** from ramps/stairs/valleys and forward orientation. `Start` local Y=0; `End.Y` is exactly the recipe endpoint from `60`. Therefore a Flat piece after RampUp continues at the ramp exit elevation automatically. Manual world-space eyeballing is forbidden for production definitions. TrackDefinition stores PieceId + parameter override, not arbitrary scene CFrames.

## 3. Lane construction
One resolved lane is built first. Lanes 2–8 are exact translated copies at Z centers from `16`. Never hand-edit lane 3 etc. Fairness acceptance: same PieceIds, same numeric overrides, same moving-obstacle phase rule and same start/finish X.

## 4. T01–T20 build order
Build and validate in this order:
`T01 → T02 → T03 → T04 → T05 → T06 → T07 → T08 → T09 → T10 → T11..T20`.

Why: first ten cover launch onboarding/readability grammar; later ten expand mastery without introducing new systems. Exact definitions and overrides = `60` only.

## 5. Per-track blockout acceptance
Before theme art:
- no impossible adjacency;
- next obstacle readable before current commitment window;
- at least one safe redraw/recovery zone around planned transitions;
- ordered checkpoint sequence monotonic in +X;
- no checkpoint can be reached by falling from unrelated geometry;
- finish only valid after all required checkpoints;
- canonical intended shapes show different tradeoffs;
- track can complete with legal shape bounds;
- no single canonical shape dominates all requirement changes in G1 protocol.

## 6. Moving obstacle authoring
Moving piece behavior is config-driven. Template contains anchors/geometry; movement script/system is shared. Parameters (period/amplitude/phase) come from `60/TrackDefinition`. All 8 lanes receive identical deterministic phase for a heat unless `60` explicitly specifies mirrored presentation; no random lane advantage.

## 7. Recovery placement
Recovery anchors go after failure-prone sections, never ahead of unpassed checkpoint. Respawn puts body at documented height and retains accepted shape per `16/28`. Respawn cannot shortcut a TrackPiece.

## 8. Theme pass
T01–T10 = `TOY_WORKSHOP`; T11–T20 = `NEON_FACTORY` per `62`. Theme pass sequence:
`collision locked → edge readability → background kit → non-collision props → lights → VFX anchors → audio ambience → screenshot pass`.
No theme-specific physics.

## 9. Camera readability pass
For each T01–T20 capture local-racer view at every major requirement transition on desktop + touch reference devices. Upcoming collision silhouette must remain above/around DrawCanvas exclusion zone (`59`). If blocked, move non-gameplay decor first; do not silently change obstacle geometry outside `60` tuning process.

## 10. 8-player readability pass
Run 8 racers with intentionally different legal shapes. PASS when local track silhouette remains readable, rival geometry is informative rather than full-screen clutter, and progress strip resolves distant rivals. Use Rival Shape Detail settings from `59/37`.

## 11. Naming/package
Runtime TrackId exactly `T01...T20` canonical names from `60`. Template name `Piece_<PieceId>`. No duplicate copy like `T06_final_v4` in production registry; source working files may have versions, runtime owner does not.

## 12. Regression after tuning
Any change to a shared TrackPiece default reruns every T01–T20 definition that references it. Use dependency report from TrackConfig validator. A track-specific override reruns that track + canonical shape comparison only unless shared behavior changed.

## 13. Release acceptance per track
A launch TrackId is RELEASE READY only if:
- schema validation PASS;
- blockout traversal PASS;
- intended-shape tradeoff PASS;
- checkpoint/finish/recovery exploit pass;
- 8-lane equality hash/geometry check PASS;
- camera screenshots PASS;
- theme art/provenance PASS;
- performance budget PASS;
- no P0/P1 QA;
- TrackDefinition committed/versioned.

## 14. Deliverable
The level team hands off **data + validated TrackPiece templates**, never a monolithic manually scripted map. `TrackService` must be able to rebuild the same T01–T20 from definitions in a clean server.
