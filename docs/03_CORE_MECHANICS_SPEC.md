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
2. Clamp to DrawCanvas.
3. Remove near-duplicates.
4. Simplify (RDP or equivalent).
5. Resample to bounded point count/segment length.
6. Preserve canonical DrawCanvas-centered pivot/scale mapping exactly as `73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md`; do **not** recenter/resize by stroke bounds.
7. Server repeats validation/clamping; client shape is never trusted.

## C. Shape semantics
Нет распознавания «круг/L/звезда» ради movement. Реальная geometry определяет movement. Shape classification разрешён только для analytics/debug, но не заменяет physics.

## D. Leg construction
- Один stroke создаёт две duplicated leg shapes left/right по Z; exact coordinate/pivot/duplication semantics are `73`.
- Каждая leg: Hub/LegRoot + несколько welded physical collider segments per `73/65`.
- Вся welded leg — одна assembly.
- Один motor/hinge на leg.
- Visual curve может иметь больше segments, чем physics representation.
- Canonical collision rule: **own Body↔Leg = no, own Leg↔Leg = no, any Racer↔Racer = no; Body/Leg↔Track = collide**. Exact matrix = `28/65`. Inner-hub segments may additionally set `CanCollide=false` per `73`, but no implementation may re-enable self/rival pushing.

## E. Rotation
Exact hinge axis, hub offsets, starting motor sign and phase construction are `73`; tuneable magnitude is `16`.
- Legs постоянно вращаются в racing state.
- Direction одинаково толкает racer вперёд.
- Left/right legs используют зафиксированный phase offset.
- Motor должен иметь достаточно torque, чтобы geometry имела значение, но не бесконечно пробивать стены.

## F. Body behavior
Racer locomotion is 2.5D. X/Y are the physical gameplay plane. Z translation is locked to the racer's lane center and is not player steering/gameplay; rotation around world Z remains physical and free; out-of-plane X/Y rotation is constrained.

Cube остаётся настоящим physical body внутри этой плоскости: collisions ног с Track могут заставлять его подпрыгивать, падать, наклоняться и кувыркаться вокруг world Z. Planar stabilizer не имеет права добавлять intentional +X race speed.

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
