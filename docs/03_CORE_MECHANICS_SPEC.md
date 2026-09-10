# 03 — CORE MECHANICS SPEC

> PRODUCT LOCK v1.3.4: final target is an 8-player live drawing race; 2-player is an implementation/integration stage only. Product power is never sold.

> Numeric ownership is split deliberately: global physics/race/camera tuning → `16`; UI geometry → `59`; TrackPiece/launch track geometry → `60`; economy/progression → `61`; exact DrawCanvas→world/pivot/collider mapping → `73`; lifecycle time semantics → `74`; bot behavior defaults → `75`. Этот файл определяет core behavior и не создаёт второй numeric owner.

## A. Drawing input
### Allowed
- один continuous stroke на одну новую shape;
- mouse/touch;
- self-intersection допустим;
- open/closed shape допустима;
- игрок может redraw в любой момент RACING.

### Flow
`pointer down → sample Vector2 points → local preview → pointer up → clean/simplify/normalize → submit → validate → build new leg assemblies → atomic swap`.

### Invalid input
Stroke считается invalid, если после очистки остаётся меньше минимального количества полезных точек/длина ниже threshold/выходит за payload limits. Invalid input **не удаляет** рабочую shape.

## B. Stroke processing
1. Sample only when pointer moved enough.
2. Clamp to the visible wide semantic DrawInputRect.
3. Remove near-duplicates.
4. Simplify (RDP or equivalent).
5. Resample to bounded point count/segment length.
6. Per **R16.3B/`73`**, server-authoritative processing translates the cleaned stroke so the **first cleaned point** becomes `(0,0)` before physical mapping. This is translation-only: do not resize, rotate, mirror, reverse or normalize every shape to a standard radius.
7. The previous R16.3A rule that required the cleaned **bounds midpoint** / bounds center to become the pivot is superseded. Bounds are still validation/debug data but are not the mechanical-origin owner.
8. Server repeats validation/clamping and returns authoritative first-point-anchored accepted points; client shape is never trusted. A sequence-scoped client presentation anchor may keep the accepted line visually where it was drawn, but that offset never enters ShapeSpec or physics.

## C. Shape semantics
Нет распознавания «круг/L/звезда» ради movement. Реальная geometry определяет movement. Shape classification разрешён только для analytics/debug, но не заменяет physics.

## D. Leg construction
- Один stroke создаёт две duplicated leg shapes left/right по Z; exact coordinate/pivot/duplication semantics are `73`.
- Каждая leg: Hub/LegRoot + несколько welded physical collider segments per `73/65`.
- Вся welded leg — одна assembly.
- Один motor/hinge на leg.
- Visual curve может иметь больше segments, чем physics representation and is nonphysical.
- Physical collider Parts remain hidden from presentation under R16.3B; visual Parts never collide/touch/query or add mass.
- Canonical collision rule: **own Body↔Leg = no, own Leg↔Leg = no, any Racer↔Racer = no; Body/Leg↔Track = collide**. Exact matrix = `28/65`. Inner-hub segments may additionally set `CanCollide=false` per `73`, but no implementation may re-enable self/rival pushing.

## E. Rotation
Exact hinge axis, hub offsets, starting motor sign and phase construction are `73`; tuneable magnitude is `16`.
- Legs постоянно вращаются в racing state.
- Direction одинаково толкает racer вперёд.
- Left/right legs используют зафиксированный phase offset.
- Motor должен иметь достаточно torque, чтобы geometry имела значение, но не бесконечно пробивать стены.

## F. Body behavior
Racer locomotion is 2.5D. X/Y are the physical gameplay plane. Z translation is locked to the racer's lane center and is not player steering/gameplay. Under the R16.1 upright-body contract, **rotation about world Z is locked/corrected together with world X/Y rotation**; the cube does not intentionally tumble with its legs.

Cube остаётся настоящим physical body: X/Y translation remains physically free, so collisions ног с Track могут заставлять его ехать, подпрыгивать, подниматься и падать. Upright orientation correction may apply corrective torque only; it must not provide forward propulsion or vertical lift. Вращаются для locomotion только leg assemblies.

## G. Movement source
Основное forward movement создаётся collision ног с track. Разрешён очень слабый anti-stall assist только для предотвращения «валидная форма вообще не двигается на плоском полу»; assist не должен проходить препятствия вместо shape.

## H. Redraw
- Во время pointer drag старая shape продолжает работать.
- Новая форма применяется после release и server validation.
- Swap атомарный: old assemblies removed only when new assemblies ready.
- Body CFrame/linear velocity не сбрасываются.
- Rotation phase сохраняется настолько, насколько позволяет implementation.
- Redraw не ставит global slow motion в multiplayer.

## I. Obstacle read/adaptation
Core считается работающим, если разные geometry создают реально наблюдаемые trade-offs:
- rounded/wide → speed on flat;
- long → reach/gaps;
- hook/asymmetry → climbing/steps;
- compact → low clearance;
- weird multi-point → bounce/unstable but potentially useful.

Нельзя hard-code `if L then climb`.

## J. Stuck/recovery
1. Система отслеживает progress delta.
2. Сначала показывает contextual REDRAW hint.
3. Если progress долго отсутствует — checkpoint recovery по tuning.
4. Recovery даёт time disadvantage, но не завершает race.

## K. Finish
Finish засчитывается server-side только после обязательной sequence checkpoints. Placement uses the deterministic `FinishAcceptedAt → FinishSequence → SlotIndex` rule from `74`; client time never breaks ties. Reward выдаётся только сервером. Grace window, hard timeout, DNF ordering, kill-plane and requeue semantics are owned by `74_RACE_LIFECYCLE_TIMEOUT_REQUEUE_DEFAULTS.md`.

## L. Core acceptance test
Prototype проходит gate, только если playtesters без объяснения способны:
- нарисовать shape;
- увидеть причинную связь shape→movement;
- самостоятельно попробовать вторую shape после плохого результата;
- назвать хотя бы две формы с разным полезным поведением;
- не использовать одну и ту же «палку» на всех test obstacles.

Repository automation can validate the R16.3B shape/network/collider contracts, but live solver/visual acceptance remains a Roblox Studio human gate.