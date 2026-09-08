# 05 — MULTIPLAYER RACE DESIGN — IMPLEMENTATION LOCK v1.3.4

## Product decision
**Final heat = up to 8 real racers.**

2-player is a development/integration stage for the same locked social race. It is not the final mode identity.

## Phase A — 2-player networked rival slice
Acceptance objective: implement the locked rival experience with readable pressure/comparison and correct network authority before scaling to 8.

Required:
- 2 isolated lanes;
- same track definition;
- visible relative progress;
- rival shape visible;
- server-authoritative start/checkpoints/finish;
- fast rematch;
- no store/meta distractions.

Acceptance signal: rival is readable, his shape/outcome can be perceived, and rematch flow works without damaging own-track readability. Если это не выполняется, исправляются camera/HUD/spacing/feedback/networking до масштабирования.

## Phase B — 8-player vertical slice
Acceptance objective: масштабировать тот же locked experience до целевого heat, сохранив читаемость, честность и performance.

Required:
- 8 lane slots;
- readable local racer + nearby rivals;
- authoritative placement;
- no physical inter-player collision;
- podium/results;
- mobile performance profile;
- fill integration seam/stub; production Bot Fill is implemented later but is mandatory before public cold-start release.

## Heat state machine
`QUEUE/READY → LINEUP → INITIAL_DRAW/COUNTDOWN → RACING → FINISH_WINDOW → RESULTS → REQUEUE`.

## Start
- Track built before lineup.
- Racers frozen until GO.
- DrawCanvas can be used during short countdown.
- No valid shape at GO = racer remains stationary + strong draw hint. No secretly optimal default wheel/StarterShape. Exact shape lifetime is `73`; timing/requeue lifecycle is `74`.

## Lane rules
- Same gameplay X/Y geometry.
- Lanes offset in Z.
- Other racers and their legs are non-collidable.
- Decorative geometry never influences race physics.
- Lane lock prevents drift while retaining bounce/tilt.

## Social visibility
Camera prioritizes local racer. Product requirement: player should frequently perceive 2–4 nearby rivals or clear simplified representations.

Must be able to answer during play:
- who is ahead?
- what strange thing did nearby racer draw?
- did their solution work?
- did I just overtake someone?

## Placement authority
Server tracks ordered checkpoints + valid progress and allocates deterministic server-only finish acceptance time/sequence per `74`. Client placement/timestamps are presentation/prediction only and never break ties.

## Rewards
All valid finishers progress. Placement increases Coins/status, but last place must still feel able to progress. DNF can receive reduced participation reward only after sufficient valid activity.

## Bots/fill
Реализуется после базового real-player race, но **обязателен до public cold-start release**. Product contract — `40_BOT_FILL_SPEC.md`; exact launch profile/shape policy — `75_BOT_SHAPE_POLICY_BEHAVIOR_CATALOG.md`.
Rules:
- valid preset shapes;
- human-like reaction delay/errors;
- no teleport catch-up;
- no hidden impossible physics boost;
- bot identity distinguishable if product/policy requires.

## Leave/reconnect
MVP:
- leaver forfeits heat placement/reward;
- remaining racers continue;
- no mid-heat real-player replacement.

## Friends/parties
Post-vertical-slice. Reuse same heat rules. Private servers may be monetized later; public progression must not gain exploitable unfair benefits.

## Anti-grief
No racer collision, weapons, world drawing, lane blocking or opponent shape editing. Drawing creates restricted locomotion geometry only.

## 20+ players
Do not increase one heat beyond readability. Bigger servers may host queue/lobby/multiple heats; race camera remains designed around max 8 active racers.
