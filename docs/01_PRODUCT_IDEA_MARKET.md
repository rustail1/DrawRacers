# 01 — PRODUCT IDEA, MARKET & REFERENCE BASIS — v1.3.4

## 1. What we are actually selling to attention
Не «игра про кубы» и не «Draw Climber clone».

**Thumbnail-level promise:** странные нарисованные колёса/ноги реально двигают кубы, а несколько игроков одновременно пытаются пройти одну и ту же безумную трассу.

## 2. Target audience decision
Основная: 9–13. Поведенческие design consequences:
- immediate visible result;
- short explainable action;
- peer comparison in-world;
- mobile-first touch;
- visual self-expression;
- short rounds with repeatability.

## 3. Demand / reference evidence snapshot (2026-09-02)
The reproducible evidence table with date, visits, CCU/rating, supported claim, unsupported claim and source is `54_MARKET_EVIDENCE_SNAPSHOT.md`.
Найденные Roblox-сигналы показывают сильный исторический спрос на **drawing as functional input + physics/obby result**. При этом несколько заметных drawing/obby products имеют огромные visits, но слабый текущий хвост/рейтинг; это означает, что hook может привлекать, но сам по себе не гарантирует долгую ценность.

### What this supports
- drawing input понятен рынку;
- physics/obstacle consequence способен привлекать большую аудиторию;
- формат может работать на small multiplayer servers.

### What the references do NOT guarantee
Референсы и рыночные сигналы достаточны, чтобы **зафиксировать продуктовый дизайн и начать полную разработку**, но они не могут гарантировать метрики конкретной реализации или коммерческий хит. Поэтому следующие пункты не являются вопросами «что делать» — это измеряемые outcomes уже выбранного дизайна:
- retention/rematch целевой 8-player версии;
- насколько часто игрок реально читает чужую shape;
- сила cosmetics/status как monetization/persist value;
- PTR конкретных title/icon/thumbnail;
- latency/FPS конкретной Roblox-реализации на target mobile.

## 4. Product differentiation decision
Существующие drawing-physics experiences часто упакованы как stage obby/vehicle progression. Зафиксированная продуктовая дифференциация:

> **короткая live гонка, где чужой рисунок виден, создаёт pressure/comedy и может заставить тебя изменить собственное решение прямо сейчас.**

Это решение не заявляется как доказанный источник будущего retention само по себе. Оно фиксирует, **как именно** мы адаптируем знакомый drawing→physics core под Roblox multiplayer; эффективность исполнения измеряется после реализации.

## 5. Why Roblox
### 1 player
Physics puzzle/time trial. Можно понять механику, но social spectacle отсутствует.

### 2 players
Появляются relative position, pressure, copying/counter-learning. Этот режим используется как дешёвый integration/UX stage до масштабирования той же системы на 5–8 игроков.

### 5–8 players
Появляются одновременно несколько решений, лидеры/отстающие, фейлы, overtakes, podium/status. Это целевой продуктовый масштаб.

### 20 players
Одна race-camera становится нечитаемой. Решение: несколько heats/queue/lobby, но **8 racers max per heat**.

## 6. Core verbs
1. Читать трассу.
2. Рисовать.
3. Наблюдать физический результат.
4. Сравнивать себя с rivals.
5. Перерисовывать.
6. Финишировать.
7. Рематчить.
8. Превращать награду в collection/status и снова идти в race.

## 7. First five minutes
1. Spawn сразу в controlled first heat.
2. First stroke двигает cube.
3. Первый obstacle показывает, что shape matters.
4. Redraw даёт заметное улучшение/обгон.
5. Finish → первая награда → быстрый cosmetic equip/goal → Next Race.

После пяти минут желание продолжить должно исходить из: «ещё одна трасса / хочу победить / хочу попробовать другую shape / хочу показать новый look», а не из обещания далёкой меты.

## 8. Implementation outcomes to verify, not design questions
1. **Physical shape feel** — разные shapes действительно ощущаются и полезны по-разному.
2. **Adaptation** — mixed tracks естественно вызывают 2–4 meaningful redraw.
3. **Social multiplier** — visible rivals делают гонку интереснее, а не шумнее.
4. **Mobile/network viability** — feel сохраняется на target devices.
5. **Repeatability** — игрок хочет сразу следующую гонку.
6. **Expression economy** — visible cosmetics/status создают достаточно желания без P2W.
7. **Marketability** — icon/thumbnail способны мгновенно объяснить drawing race.

## 9. Dependency-safe build path
Не строить верхние слои раньше зависимостей.
`Physics Lab → mixed track → 2 real players → 8-player slice → meta → monetization`.

Каждый gate — **acceptance gate реализации**: если результат плохой, исправляется текущий слой до DoD. Это не приглашение заново придумывать игру. Scope меняется только через явный Decision Log.
