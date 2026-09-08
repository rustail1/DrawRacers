# 64 — PLATFORM PROVISIONING & RELEASE CONFIGURATION
Статус: **ZERO-QUESTION PLATFORM CONTRACT v1.3.4**.

Цель: убрать вопросы вида «что именно создать в Roblox/Creator Hub, где хранить IDs, какой place стартовый, что включать перед STAGING/PROD и что блокирует публикацию». Точные названия пунктов интерфейса Roblox могут меняться; контракт фиксирует **результат настройки**, а не устаревающий путь кликов.

## 1. Environment topology
Используются три отдельные experience/universe среды:

| Environment | Назначение | Public access | Real monetization | Real player data |
|---|---|---|---|---|
| DEV | локальная/интеграционная разработка | no | disabled | isolated DEV namespace |
| STAGING | published QA, teleport, DataStore, analytics, purchase flow tests | private/unlisted | test-only / disabled unless explicit QA | isolated STAGING namespace |
| PROD | публичная игра | public only after release gate | enabled per `61/70` | production namespace |

Нельзя направлять DEV/STAGING в PROD DataStore namespace.

## 2. Places per experience
Каждая среда содержит ровно два игровых place:
1. `EntryFTUEPlace` — **start place**.
2. `RacePlace` — public continuous-heats place.

Контракт маршрутизации = `23/41`. Никакой третий gameplay place на launch не создаётся без Decision Log.

## 3. Ownership
- Experience, places, Passes, Developer Products, uploaded game assets и discovery creatives принадлежат одному production owner/group.
- Нельзя завязывать PROD на временный личный asset другого человека.
- Creator/group ownership и deploy-account permissions фиксируются в `70_ENVIRONMENT_ASSET_ID_REGISTRY_CONTRACT.md`.

## 4. Required experience settings outcomes
Перед STAGING acceptance и затем PROD release должны быть подтверждены:
- start place = `EntryFTUEPlace`;
- `EntryFTUEPlace` и `RacePlace` published в одной версии schema contract;
- mobile + desktop разрешены; launch orientation landscape согласно `59`;
- Voice/Chat не являются gameplay dependency; отсутствие чата не ломает core;
- third-party teleports/HTTP внешние зависимости не требуются для core;
- DataStore/API access настроены только там, где нужны опубликованные тесты;
- experience maturity/compliance answers соответствуют реальному контенту;
- public drawing sharing отсутствует, safety contract = `39`;
- permissions позволяют release operator публиковать оба place и обновлять SKU/assets;
- shutdown/rejoin behavior = `35`.

## 5. Server authority / physics setting
Конкурентная физика использует current supported Roblox server-authority mode согласно `27` и реализации `11`. Конкретное текущее platform property проверяется перед включением STAGING. Если Roblox переименовал/заменил API, меняется adapter/HOW, но контракт остаётся: client sends intent, server owns competitive physical truth/finish/reward.

## 6. Monetization provisioning
Создать exact launch SKUs из `61`:
- Pass `STARTER_STYLE_PASS_A` — target 59 Robux;
- Pass `NEON_STYLE_PASS_A` — target 149 Robux;
- Pass `PREMIUM_PRESENTATION_PASS_A` — target 299 Robux;
- Developer Product `COINS_450_DP` — target 49 Robux, launch disabled;
- Developer Product `COINS_1100_DP` — target 99 Robux, launch disabled;
- Developer Product `COINS_2500_DP` — target 199 Robux, launch disabled.

Platform IDs are deployment outputs, not design guesses. They are inserted only through registry `70`, never hard-coded in gameplay modules. Runtime display price comes from platform data; art never contains a stale Robux number.


## 7. Analytics provisioning
Before G3/G6/soft launch:
- published STAGING emits required events from `46`;
- environment field/version lets analysis exclude DEV/STAGING;
- FTUE funnel, race finish/requeue, cosmetic engagement and offer funnel are visible;
- bots excluded from human KPI per `40/46`;
- event volume does not exceed current platform constraints; if platform limits change, consolidate fields/events without changing product questions in `10`.

## 8. Localization provisioning
Launch source language = English canonical copy from `59/62`.
Required before PROD:
- all player-facing strings are keys, not embedded literals except dev/debug;
- source English published;
- pseudo/localization expansion screenshot pass from `37/59`;
- unsupported translation never blocks core input.

Additional languages may launch later; absence of a translation is not permission to alter layout hierarchy.

## 9. Discovery assets provisioning
Required initial package from `62`:
- icon/logo;
- Thumbnail A/B/C;
- short-video capture templates;
- title + description;
- no copied competitor expression.

Only one creative variable is intentionally changed per discovery experiment where practical. PTR winner is empirical (`38/55 G6`).

## 10. Content maturity / safety / policy preflight
Before public switch:
- content maturity questionnaire reviewed against actual gameplay;
- drawing moderation/safety behavior `39` present;
- purchase products and random-item policy reviewed; launch contains no paid random mechanic;
- no misleading limited timer/fake discount;
- display names/bot labels cannot impersonate paid or official status;
- report/safety platform behavior is not obstructed by custom UI.

## 11. Publishing order
STAGING:
`publish EntryFTUEPlace → publish RacePlace → set registry → routing smoke → DataStore lease/handoff → analytics smoke → 8-player/bot soak → UI/device matrix → purchase sandbox/test path`.

PROD:
`backup known-good pair → publish schema-compatible EntryFTUEPlace + RacePlace → verify registry/SKUs → private smoke` → enable public access/discovery only after **`35` + `57` + `78` PASS**.

## 12. Platform-change rule
If Creator Hub/Roblox changes a menu/API/property:
1. do not invent a new product rule;
2. verify current official platform behavior;
3. adapt HOW in `27/64/70`;
4. rerun affected staging tests;
5. update Decision Log only if observable player contract must change.

## Acceptance
Platform provisioning is PASS only when every environment row in `70` has resolved required IDs, two-place routing works in STAGING, all launch Pass IDs resolve, disabled Developer Products cannot be prompted, analytics identifies environment correctly, and PROD remains non-public until `78` passes.
