# 20 — HOW TO DEVELOP THE GAME

Статус: **IMPLEMENTATION PLAYBOOK v1.3.4**  
Назначение: пошагово объяснить, **как именно разрабатывать Draw Racers**, чтобы дизайн, код, Roblox Studio и AI не расходились.

Этот файл отвечает не на вопрос «что за игра?» — это делает GDD. Он отвечает на вопрос **«каким процессом довести игру от пустого проекта до релиза?»**.

---

## 1. Основной принцип разработки

Процесс из курса фиксируется как обязательный:

`Feature List → WHY/Scope Gate → специализированный spec → technical reconnaissance → минимальный end-to-end шаг → Studio test → edge/regression → human acceptance → Decision Log/SESSION → следующий шаг`.

Нельзя отдавать AI задачу уровня «сделай мультиплеер», «сделай физику ног», «сделай магазин». Одна задача должна давать **одно отдельно наблюдаемое поведение**.

Человек владеет **WHAT и WHY**. AI/Codex предлагает и реализует **HOW**, но только после изучения существующего проекта.

---

## 2. Источники истины

Перед любой задачей определить, где живёт факт.

| Вопрос | Source of truth |
|---|---|
| Что входит в scope? | `FEATURE_LIST.md` |
| Что за продукт и почему? | `00_PROJECT_BIBLE.md`, `01_PRODUCT_IDEA_MARKET.md`, `02_FULL_GDD.md` |
| Как должна вести себя конкретная система? | профильный spec `03–10` |
| Техническая архитектура | `11_TECH_DESIGN_ROBLOX.md`, `21_SYSTEM_CLASS_ARCHITECTURE.md` |
| Числа/тюнинг | global physics/race/camera `16`; UI geometry `59`; level geometry/tracks `60`; economy/progression/prices `61`; performance `57` |
| Почему принято решение | `DECISION_LOG_TEMPLATE.md` → конкретный Decision Log |
| Что уже реализовано | `SESSION.md` |
| Порядок разработки | `12_FEATURE_PLAN_ROADMAP.md`, `18_TRELLO_BACKLOG.md`, `25_IMPLEMENTATION_SEQUENCE.md` |
| Remote/data contracts | `22_NETWORK_DATA_CONTRACTS.md` |
| Как тестировать | `24_TESTING_QA_MATRIX.md`, empirical gates `55`, release matrix `57`, UI screenshots `59` |
| Launch art/content/public identity | `62_LAUNCH_CONTENT_ART_DIRECTION_MANIFEST.md` |
| Current final documentation audit | `78_FINAL_EXECUTION_CONSISTENCY_AUDIT_v1.3.4.md` |

**Не копировать один и тот же факт в несколько документов.** Если нужен контекст — ставить ссылку на source of truth. `_HISTORY/` не загружается в обычный AI-контекст и не является источником истины.

---

## 3. Инструментальная связка

Рекомендуемый рабочий контур:

`Git + VS Code + Rojo + Codex/Claude + Roblox Studio`.

Roblox Studio остаётся местом, где принимается игровой результат руками и глазами. AI может проверять код, типы, вычисления, инварианты и автоматические тесты, но **feel физики, камера, читаемость, touch UX и соревновательная честность принимаются человеком в Play Mode**.

Если используется Studio MCP, он дополняет, но не заменяет этот процесс.

---

## 4. Как начинать новый milestone

Перед началом milestone:

1. Открыть `FEATURE_LIST.md`.
2. Проверить, что milestone ещё актуален и предыдущий gate принят.
3. Прочитать только профильные specs.
4. Создать/обновить Decision Log, если появляется новое продуктовое решение.
5. Провести техническую разведку текущего Roblox-проекта.
6. Составить **минимальную вертикальную цепочку**, которая доказывает вопрос milestone.
7. Не тянуть будущие сервисы «про запас».

### Gate rule
Если milestone не доказал свой главный вопрос — следующий milestone **не начинается автоматически**.

---

## 5. Technical reconnaissance — обязательный первый шаг каждой крупной фичи

Первый промпт Codex по новой системе:

> Ничего пока не меняй. Прочитай FEATURE_LIST, профильный spec, SESSION и Decision Log. Изучи DataModel и код. Найди существующие модули, runtime state, remotes, configs, UI, тестовые инструменты и точки интеграции. Покажи минимальный путь через существующую архитектуру. Не создавай параллельные Manager/Service, если можно расширить существующее.

Результат разведки должен содержать:
- какие файлы/instances относятся к задаче;
- кто уже владеет нужным состоянием;
- что можно переиспользовать;
- какие зависимости затрагиваются;
- минимальный change-set;
- риски/regression surface;
- как проверить результат в Studio.

Только после этого разрешается реализация.

---

## 6. Как резать задачи

### Плохо
`Сделать физические ноги`.

### Хорошо
1. `DrawCanvas отдаёт нормализованный stroke.`
2. `StrokeMath удаляет дубликаты и упрощает точки.`
3. `LegAssembly строит одну welded physical shape.`
4. `Один HingeConstraint вращает одну leg assembly.`
5. `Две ноги двигают Body по FlatTest.`
6. `Invalid redraw не уничтожает старые ноги.`

Каждый пункт можно отдельно увидеть, сломать и принять.

---

## 7. Правило минимального изменения

Каждый implementation turn:

1. **Expected result** — что игрок/тестер увидит.
2. **Minimal change** — минимальный набор кода/instances.
3. **Run** — Play Mode / Start Server.
4. **Check** — acceptance + edge case.
5. **Regression** — если затронут shared system.
6. **Accept/Reject**.
7. Только после принятия — следующий шаг.

Нельзя одновременно переписывать input, физику, camera и race state, если задача проверяет только redraw.

---

## 8. Human acceptance

AI не имеет права сам объявлять feature готовой по чистой Console.

Для каждой feature есть три слоя:

### Automated
- type/static checks;
- pure module tests;
- invariant tests;
- malformed payload tests;
- repeatable calculations.

### Studio technical
- Client/Server separation;
- multi-client test;
- no errors;
- state transitions;
- save/rejoin;
- remote validation.

### Human feel
- удобно ли рисовать;
- понятно ли shape→movement;
- приятно ли redraw;
- читается ли obstacle;
- не укачивает ли camera;
- кажется ли race честной;
- смешно/интересно ли смотреть на соперника.

Human feel не заменяется автоматизацией.

---

## 9. Когда создавать новый Service/Class

Новый сервис допустим только если:
1. есть отдельная ответственность;
2. у него есть собственное состояние/жизненный цикл или единый платформенный gateway;
3. существующий модуль не является естественным владельцем;
4. можно назвать публичный API без слов `DoEverything`;
5. нет циклической зависимости.

Запрещено создавать:
- `NewRaceManager` рядом с `RaceService`;
- `GameManager` как глобальный контейнер всего;
- отдельный controller на каждую кнопку;
- класс только ради одного stateless helper;
- сервис «на будущее» без активной feature.

Точные владельцы систем зафиксированы в `21_SYSTEM_CLASS_ARCHITECTURE.md`.

---

## 10. Dependency rule

Зависимости направлены сверху вниз:

`Bootstrap → Services → Runtime Objects → Pure Shared Modules`.

Client:

`ClientBootstrap → Controllers → Shared Pure Modules`.

Runtime object не должен сам искать глобальный service через случайные `game:GetService()`/`require()` зависимости, кроме Roblox engine services, если это оправдано. Предпочтительно передавать проектные зависимости через constructor/init.

**Circular requires запрещены.**

---

## 11. Server/client rule

Для competitive state:
- клиент сообщает **намерение/input**;
- сервер валидирует;
- сервер меняет authoritative state;
- клиенты визуализируют replicated result.

Клиент не сообщает:
- `IWon`;
- награду;
- authoritative finish time;
- произвольный racer CFrame;
- цену предмета;
- что item уже куплен.

Подробнее: `22_NETWORK_DATA_CONTRACTS.md`.

---

## 12. Physics rule

До M0.5 весь фокус — на физической реализации и acceptance core.

Не добавлять:
- economy;
- skins;
- 8-player service;
- season;
- procedural generator;
- social extras.

До acceptance нельзя считать слой готовым, пока:
1. shape не меняет движение достаточно читаемо;
2. несколько shapes не показывают предусмотренные trade-offs;
3. redraw не проходит UX/feedback acceptance;
4. mixed track не создаёт предусмотренную адаптацию;
5. universal-shape dominance не устранена физикой/level grammar.

Это критерии качества реализации locked design, а не открытые продуктовые вопросы.

---

## 13. Milestone development path

### M0 Physics Lab
Цель: реализовать и принять `draw → physical locomotion`.

Работаем только локально/серверно настолько, насколько нужно для правильной будущей архитектуры. Итог: один racer, одна lane, пять препятствий, redraw.

### M0.5 Adaptation Acceptance
Цель: реализовать/принять level grammar, создающую предусмотренный выбор формы.

### M1 2-Player Rival Slice
Цель: реализовать/принять locked rival layer: visibility, authority, race pressure/presentation и rematch.

Здесь впервые обязательны:
- server authority decision;
- remotes;
- race state;
- checkpoint/finish validation;
- две lanes;
- multi-client tests.

### M2 8-Player Vertical Slice
Цель: реализовать и принять целевой Roblox-format по 8-player DoD/QA.

Здесь появляются:
- 8 racers;
- FTUE;
- results/requeue;
- save;
- basic economy;
- cosmetics;
- analytics;
- performance gate.

### M3 Alpha
Цель: реализовать и принять repeated-session + persist/status loop.

### M4 Monetization/Soft Launch
Только после полностью работающего бесплатного value loop и принятого M3; monetization не используется для маскировки дефектов core/session.

### M5 Live Product
После production-ready M4 и подключённой аналитики; реальные данные управляют tuning/LiveOps, а не автоматически переписывают product lock.

---

## 14. Что обновлять после каждой принятой задачи

Обязательно:
- `SESSION.md` — текущее состояние;
- status feature в `FEATURE_LIST.md`;
- Decision Log — только если изменено продуктово/архитектурно значимое решение;
- тесты — если появилась новая invariant;
- профильный spec — только если решение дизайна реально изменилось.

Не писать историю сессий внутрь GDD.

---

## 15. Completion report AI

После задачи AI обязан сообщить:
1. какие файлы изменены;
2. какое поведение теперь существует;
3. какие тесты запускались;
4. что не протестировано;
5. edge cases;
6. regression risks;
7. отклонения от spec;
8. что в реализации выглядит хрупко;
9. следующий **самый маленький** шаг.

---

## 16. Как менять дизайн во время разработки

Если Play Mode показывает, что spec плох:

`наблюдение → сформулировать проблему → Decision Log → изменить source of truth → только потом менять код`.

Не разрешается «тихо подправить код, потому что так лучше» и оставить документы старыми.

Для чистого tuning без изменения смысла feature достаточно записи в tuning log/SESSION; для изменения поведения/контракта нужен Decision Log.

---

## 17. Definition of Done разработки

Игра не считается готовой потому, что «все карточки закрыты».

Релизный кандидат должен одновременно пройти:
- product DoD `15_DEFINITION_OF_DONE.md` + empirical gates `55`;
- technical/security/data tests `24_TESTING_QA_MATRIX.md`;
- target-device performance against `57_RELEASE_PERFORMANCE_DEVICE_MATRIX.md`;
- multi-client race regression;
- FTUE analytics instrumentation;
- save/purchase idempotency including `56` if Developer Products are enabled;
- manual playtest core feel.

---

## 18. Что неизбежно остаётся тюнингом, а не вопросом документации

Даже с полным пакетом нельзя заранее математически закрыть:
- финальный motor torque/acceleration;
- friction/material tuning;
- exact camera offset/FOV;
- best collider segment density;
- stabilizer strength;
- exact obstacle dimensions;
- final reward values/prices;
- **measured performance result** on real/equivalent devices (the PASS/FAIL threshold itself is already fixed in `57`).

Для каждого из этих пунктов у нас есть **стартовое значение/диапазон + тест + критерий**, поэтому это не открытый дизайн-вопрос, а экспериментальная настройка.


Launch place topology/routing owner: `23_PROJECT_SETUP_TOOLCHAIN.md` + `41_MATCHMAKING_SERVER_LIFECYCLE.md`; config contract `30`; do not invent a third lobby/matchmaking place.


## v1.3.4 zero-question execution additions
- Exact external Roblox provisioning/release outcomes: `64`.
- Exact Studio Instance/property/collision contract: `65`.
- Every implementation task output/acceptance: `66`.
- Exact level production workflow: `67`.
- Exact UI component hierarchy/controller bindings: `68`.
- Exact content production workflow: `69`.
- Deployment/asset IDs single owner: `70`.
- Coin catalog purchase + Pass entitlement transaction contract: `71`.
- Exact DrawCanvas→pivot→collider mapping and shape lifetime: `73`.
- Exact heat/timeout/DNF/requeue/spectator lifecycle: `74`.
- Exact Bot Fill difficulty/preset/decision policy: `75`.
- Concrete Day 0–30 LiveOps buffer: `76`.
- Final zero-question audit: `78`.
