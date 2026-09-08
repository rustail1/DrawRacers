# 00 — PROJECT BIBLE — IMPLEMENTATION-READY PRODUCT LOCK v1.3.4

## 1. Product statement
**Draw Racers** — короткая fair-competitive physics-race игра для Roblox. До 8 игроков одновременно автоматически движутся по параллельным эквивалентным дорожкам. Игрок управляет не газом и не прыжком, а **формой двух вращающихся ног/колёс**, которую рисует мышью или пальцем. Нарисованная геометрия реально сталкивается с трассой.

Игрок читает препятствие, рисует/оставляет форму, наблюдает физический результат, сравнивает темп с rivals и перерисовывает shape, когда трасса или соревновательная ситуация требуют адаптации.

## 2. Product promise
> Нарисуй своё движение. Увидь, как оно реально работает. Адаптируйся быстрее остальных и приди первым.

## 3. Player fantasy
«Я придумал странное колесо, оно неожиданно сработало, сосед придумал ещё более безумную форму, я понял его решение, быстро переделал своё и обогнал его прямо перед финишем».

## 4. Target audience lock
Основная целевая аудитория продукта: **9–13 лет**, Roblox-native casual/obby/physics players. Это дизайн-решение, опирающееся на рыночные/референсные сигналы из `01`/`SOURCE_MAP`; оно не является обещанием конкретного retention или коммерческого результата.

Design consequences:
- действие → быстрый видимый результат;
- ошибка должна быть смешной/понятной, а не абстрактной;
- сравнение с peers видно прямо в race;
- управление mobile-first;
- персонализация должна быть заметна другим;
- короткие rounds + быстрый rematch.

Вторичная аудитория: 14–17 casual physics/obby players. После релиза аналитика может уточнить фактический состав аудитории, но это не блокирует и не меняет текущий дизайн.

## 5. Product pillars
### P1 — DRAW IS LOCOMOTION
Рисунок не выбирает preset и не даёт стат. Он становится движителем.

### P2 — READ → ADAPT → OVERTAKE
Хорошая трасса заставляет менять решение. Универсальная shape, проходящая почти всё, считается дефектом level grammar.

### P3 — SOCIAL PHYSICS COMEDY
Другие players — источник информации, давления и зрелища: чужие формы, фейлы, неожиданные успехи и overtakes.

### P4 — FAST REMATCH
Гонка короткая. Results не должны становиться стеной между игроком и следующим core loop.

### P5 — FAIR COMPETITION
Платёж не меняет chance-to-win при одинаковом skill.

### P6 — DEPTH, NOT FEATURE PILE
Глубина растёт через shape mastery, obstacle grammar, timing redraw и чтение rivals, а не через несвязанные мини-игры.

## 6. Core loop
`увидеть upcoming geometry → выбрать/нарисовать shape → physical locomotion → оценить результат → сравнить себя с rivals → redraw при необходимости → finish → reward/status → мгновенная причина нажать Next Race`.

## 7. Match loop
`lineup → 3s initial draw/countdown → 30–45s race → finish placement → 3–5s results/podium → one-tap rematch/requeue`.

## 8. Session loop
Целевая здоровая сессия не растягивает одну гонку. Она состоит из серии быстрых heats:
`join → first heat → rematch chain → 3–10+ races depending player intent → 1–2 ownership/status changes → видимая next goal → leave`.

Целевой session target: **~10–15 минут** серии коротких гонок без искусственного ожидания. Это стартовый tuning/measurement target; фактический baseline уточняется данными без изменения core loop.

## 9. Persist lines
### Collection
Cube bodies, ink/leg visuals, trails, finish FX, victory poses.

### Status
Wins, podiums, mastery/trophies, seasonal rank/badges, visible milestones.

### Access
Новые permanent course pools/themes/challenge sets, открываемые mastery, но без power advantage.

Persist не означает «навсегда быстрее».

## 10. Long-term path
`понял базовые shapes → научился быстро адаптироваться → освоил более сложные course grammar → собирает заметный visual identity → повышает visible status → участвует в rotations/tournaments → возвращается за новыми track/cosmetic combinations`.

## 11. Roblox-native differentiation
Мы не строим ценность на факте «рисование существует». Зафиксированная адаптация референсного core: **рисование становится live competitive decision**, а чужие решения видны и способны поменять собственный redraw.

Multiplayer является частью product lock. Тесты 2→8 игроков проверяют качество реализации — читаемость, latency, camera, pressure/comedy feedback и rematch flow. Плохой тест сначала требует исправить реализацию/подачу; изменение product identity допускается только отдельным Decision Log + scope change.

## 12. Revenue thesis
Игрок платит не за шанс победить, а за **самовыражение и статус в месте, где его постоянно видят другие**.

Монетизация строится после доказанной ценности:
`увидел чужой стиль / заработал первый свой cosmetic / понял, что presentation заметна → захотел сильнее выделяться → контекстный cosmetic offer → мгновенно equip → следующий lineup демонстрирует покупку`.

## 13. Scope lock — first real product slice
Первый настоящий vertical slice обязан **подтвердить соответствие реализации зафиксированному продукту**:
- draw→physical leg;
- distinct useful shapes;
- meaningful redraw;
- 8-player readable race;
- social comparison;
- fair finish authority;
- fast rematch;
- baseline Coins→cosmetic ownership loop;
- mobile performance.

## 14. Explicit non-goals
- racer-vs-racer physical collisions;
- combat/weapons;
- open-world exploration;
- public free-form art sharing;
- pets as power;
- rebirth/stat simulator;
- permanent speed/grip/torque upgrades;
- paid stronger physics;
- mandatory gacha;
- 20 visible racers in one heat;
- procedural generation before authored grammar works;
- battle pass before core/meta retention proves need;
- giant lobby that delays race entry.

## 15. Implementation blocker criteria
Следующий milestone запрещено начинать, пока текущая реализация показывает одно из следующего:
1. Shapes ощущаются почти одинаково — rework collider/physics/tuning/obstacle contrast.
2. Одна простая shape доминирует mixed obstacle track — rework TrackPiece grammar/parameter ranges.
3. Redraw воспринимается как busywork — rework obstacle cadence/input/feedback.
4. Rival visibility создаёт шум — rework camera/HUD/spacing/presentation.
5. Mobile physics/input не удерживают стабильный feel — rework performance/network/input implementation.

Эти пункты являются acceptance blockers, а не незакрытыми дизайнерскими вопросами. Design scope меняется только отдельным решением владельца продукта.

## 16. Decision hierarchy
1. `FEATURE_LIST.md` — scope.
2. Decision Log — последнее принятое решение.
3. Specialized spec — поведение.
4. `16_BALANCE_TUNING.md` — числа.
5. Код не имеет права молча менять product meaning.


## Implementation evidence rule v1.3.4
The product direction is locked, but implementation/player outcomes are not called pre-proven. `54` holds dated reference evidence; `55` defines empirical product gates; `56` purchase integrity; `57` objective performance release gates; `78` current documentation PASS.
