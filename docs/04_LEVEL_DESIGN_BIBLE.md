# 04 — LEVEL DESIGN BIBLE

> PRODUCT LOCK v1.3.4: final target is an 8-player live drawing race; 2-player is an implementation/integration stage only. Product power is never sold.

## 1. Design goal
Трасса — не набор случайных кубиков. Это последовательность **вопросов к geometry**. Каждый meaningful section должен создавать понятный locomotion trade-off.

## 2. TrackPiece design requirements
The list below is the **design information each piece must express**. Exact serialized fields/casing are owned by `30_CONTENT_CONFIG_SCHEMAS.md`; physical hierarchy/pivots are owned by `42_TRACKPIECE_AUTHORING_GUIDE.md`; **exact starting dimensions, hard launch ranges and the first 20 TrackDefinitions are owned by `60_TRACKPIECE_PARAMETER_CATALOG.md`**. Do not invent per-piece dimensions outside `60` during implementation.

Каждый piece содержит:
- `Id`;
- `Model`;
- `StartAttachment/Pivot`;
- `EndAttachment`;
- `Length`;
- `DifficultyTier`;
- `RequirementTags`;
- `PunishTags`;
- `ParameterRanges`;
- `CheckpointPolicy`;
- `SafeRespawnMarker` при необходимости;
- decoration anchors отдельно от collision geometry.

## 3. Requirement tags
- `FAST_ROLL`
- `LONG_REACH`
- `HOOK_CLIMB`
- `SMALL_CLEARANCE`
- `STABLE_CONTACT`
- `GAP_BRIDGE`
- `BOUNCE_CONTROL`
- `REDRAW_WINDOW`
- `TIMING_MOVING`

Punish tags используют противоположности: `PUNISH_LARGE`, `PUNISH_SHORT`, `PUNISH_UNSTABLE`, etc.

## 4. Initial TrackPiece library (24)
1. FlatShort — baseline speed.
2. FlatLong — pure comparison section.
3. MicroBumps — stability read.
4. RollingHills — rounded/stable geometry.
5. SmallSteps — introduce reach.
6. TallSteps — hook/long.
7. StairUp — repeated climb contacts.
8. StairDown — stability after climb.
9. SingleWallLow — first clear climb question.
10. SingleWallHigh — long/hook mastery.
11. GapSmall — reach.
12. GapMedium — stronger reach.
13. BrokenPlatforms — repeated reach contacts.
14. LowTunnelWide — compact form.
15. LowTunnelSteps — compact + climb conflict.
16. CeilingTeeth — punish huge radius.
17. VValley — reach out of depression.
18. NarrowPit — long lever.
19. AlternatingBlocks — rhythm/change of contact.
20. RampUp — traction.
21. RampDownIntoGap — transition challenge.
22. MovingGate — timing, not new control verb.
23. MovingPlatformGap — timing + reach.
24. FinishSprint — readable final comparison.

Later families only after core acceptance: friction surfaces, conveyor, ice, sticky, crushers. Они должны усиливать существующий draw/read verb, а не добавлять отдельную minigame.

## 5. Composition grammar
### Rule A — no universal shape
В одном race должно быть минимум 2 meaningful requirement changes. Тестовый canonical run должен показывать, что shape, лучшая в первой секции, заметно хуже хотя бы в одной следующей.

### Rule B — readability before punishment
Игрок должен увидеть requirement до контакта или иметь безопасное место для первого опыта.

### Rule C — redraw cadence
Не ставить обязательные geometry switches каждые 2–3 секунды. Цель cadence см. tuning.

### Rule D — recovery space
После трудной секции оставлять короткий стабилизирующий участок, особенно в FTUE/early tiers.

### Rule E — identical fairness
Все lanes строятся из одного ordered ResolvedTrackSnapshot. **Launch T01–T20 use exact numeric geometry with no random variant** (`22/60`); all lanes share identical moving-obstacle phase. Future validated variants, if introduced by Decision Log, resolve once per heat and then clone identically.

### Rule F — avoid impossible adjacency
Generator/authoring validator запрещает комбинации, где safe exit предыдущего piece пересекается с collision следующего или где required clearance физически меньше minimum supported body/leg envelope.

## 6. First 20 authored levels/races
1. Flat + finish: draw→move.
2. Flat + micro bumps: stable round.
3. SmallSteps: long/reach.
4. Low wall: hook/climb.
5. LowTunnel: small form.
6. Flat→Steps: first natural redraw.
7. Steps→LowTunnel: big→small redraw.
8. Flat→GapSmall: speed→reach.
9. Gap→Flat: reach→speed.
10. Wall→Tunnel: hook→compact.
11. RollingHills→Steps.
12. VValley→Flat sprint.
13. SmallSteps→Gap.
14. TunnelSteps: compromise geometry.
15. AlternatingBlocks.
16. TallSteps→LowTunnel.
17. RampUp→Gap.
18. MovingGate introduction.
19. MovingPlatformGap introduction.
20. Mixed mastery: 4 requirement changes, still readable.

T01–T05 are **DEV/STAGING training/reference tracks**, useful for isolated teaching/playtests but not the production first-join sequence. Production FTUE is T06 only (`08/41/60/61`). After it, the player enters public multiplayer pools. Exact IDs/order/parameters are `60`.

## 7. Procedural/endless — NOT MVP
Разрешается только после того, как authored tracks дают данные о completion/redraw/fail. Generator использует grammar, а не pure random:
- difficulty budget;
- no same RequirementTag >2 meaningful pieces подряд;
- require at least N tag transitions;
- guaranteed recovery segments;
- validated parameter ranges;
- deterministic seed shared by all lanes;
- offline validator runs many seeds and rejects impossible topology.

## 8. Level metrics
Для каждого track сохранять:
- completion rate;
- median finish time;
- median redraw count;
- stuck/respawn count by piece;
- placement spread;
- first-fail piece;
- dominant shape analytics only if classification is reliable.
