# 02 — FULL GDD — IMPLEMENTATION-READY PRODUCT v1.3.4

## Genre
Competitive casual physics racing / drawing locomotion.

## Platform
Roblox. Mobile-first, PC fully supported. Console drawing UX — post-MVP experiment.

## Product fantasy
Восемь кастомных cube racers одновременно едут по одинаковому испытанию. Единственное прямое управление — рисование формы движителя. Странные формы могут оказаться умнее очевидных; соседские решения видны и создают соревнование/комедию.

## Final heat format
- Target heat capacity: **8 racers**.
- 1-player и 2-player режимы существуют только как prototype/testing/fill cases, не как конечная продуктовая identity.
- Race target: 30–45 sec.
- Initial draw/countdown: короткий, без обязательного modal tutorial.
- Results: 3–5 sec до доступного instant rematch/requeue.
- Одна TrackDefinition для heat; lane geometry эквивалентна.
- Racer-to-racer collisions disabled.
- Server-authoritative checkpoint/finish/reward validation.

## Minute-to-minute
1. Camera показывает racer + upcoming geometry + часть rivals.
2. DrawCanvas доступен во время race.
3. Player one-stroke рисует shape.
4. Shape очищается/валидируется и становится двумя physical legs.
5. Hinge motors вращают legs.
6. Physics geometry реально меняет locomotion.
7. Player читает следующий obstacle и tempo rivals.
8. Redraw при необходимости.
9. Finish → placement → reward/status → Next Race.

## Core success condition
Игрок должен ощущать, что проигрыш/выигрыш связан с его decision/timing/shape, а не скрытым stat, монетизацией или хаотичным сетевым толчком.

## Fail states
Hard game-over нет.
- fall → last safe checkpoint + time loss;
- stuck → contextual redraw hint, потом recovery/respawn;
- invalid stroke → current functional shape остаётся;
- disconnect → текущий heat продолжается без отката;
- DNF timeout → reduced participation reward if valid activity.

## Session design
Игрок должен быстро возвращаться в core:
`join → race → results → one-tap next race`.

Garage/collection не обязаны открываться между каждым heat; reward summary должен быть компактным. Cosmetic unlock/equip показывается контекстно, но не блокирует rematch.

Стартовый session target: серия коротких races проектируется на ~10–15 минут естественного play. Soft-launch data уточняет pacing/thresholds, но не меняет зафиксированный session loop без Decision Log.

## Depth map
### First 5 min
Round/fast shape, long/reach, hook/climb, small/tunnel, redraw.
### 20 min
Timing redraw, two requirements in sequence, reading rival solutions.
### Day 2
New track families/surface combinations, mastery milestones.
### Week
Recognize obstacle grammar, optimize shape quickly, visible status/collections.
### Month
Seasonal rotations/challenges, high mastery tracks, collection/status identity.

Новые глаголы не требуются, чтобы создать depth.

## Meta
### Coins
Earned from valid race completion + placement + milestones. Spend on cosmetic ownership.
### Collection
Bodies/inks/trails/finish FX/victory presentation.
### Status
Wins/podiums/mastery/season rank/badges.
### Access
Harder course pools/challenge sets through mastery, never paid race advantage.

## Competition fairness
Forbidden competitive advantages:
- paid speed;
- torque/grip/friction;
- draw radius;
- body/collider advantage;
- redraw cooldown advantage;
- paid obstacle skip in public competitive race.

## Social layer
Other racers must create at least one of these values:
- comparison;
- pressure;
- learning/copying;
- comedy;
- status display.

If they are merely background avatars, multiplayer design failed.

## Matchmaking/fill
Development milestones могут запускаться ниже 8 racers. **До публичного cold-start release Bot Fill обязателен** для недоукомплектованных heats по `40_BOT_FILL_SPEC.md`. Боты используют честные physics/track rules, не получают скрытого boost и никогда не используют teleport rubber-band.

## Content strategy
Authored modular TrackPieces first. Procedural/endless — later scope; он разрешён только после прохождения authoring/solvability acceptance из `04/42`, чтобы не дублировать новую игровую систему.

## Monetization role
Cosmetic/status expression after value is understood. Shop is browse surface, not the strategy. First offer is contextual after several races/garage interaction.

## LiveOps role
LiveOps refreshes track combinations/themes/collections/tournaments using existing systems. Weekly content should mostly be data/assets, not new architecture.

## Release principle
Нельзя маскировать дефектную реализацию core количеством cosmetics, quests, seasons или monetization. Любой слой сначала проходит собственный DoD/QA.
