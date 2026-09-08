# 29 — UI / SCREEN FLOW SPEC
Статус: **PRESENTATION BEHAVIOR CONTRACT v1.3.4**. UI mobile-first, landscape. Source UI language: English; localization — `37_LOCALIZATION_ACCESSIBILITY.md`; **exact anchors/sizes/hierarchy/copy/wireframes — `59_UI_LAYOUT_WIREFRAME_SPEC.md`**.

## 1. Экранные состояния
`BOOT → LOADING → FTUE/RACE_QUEUE/SPECTATING → PREP → COUNTDOWN → RACING → FINISHING → RESULTS → (REQUEUE | GARAGE)`. Exact queue/requeue timing is `74`.

## 2. Race HUD
Всегда во время Racing:
- placement `3/8`;
- компактный progress strip;
- DrawCanvas в нижней части;
- локальный feedback stroke validation;
- минимальный rival identification.
Не показывать shop/dailies/popups поверх active race.

## 3. DrawCanvas
- touch/mouse capture только внутри canvas;
- live preview локальный, без round-trip;
- release = submit;
- accepted = короткий visual snap/ink pulse;
- rejected = старая форма остаётся + короткая причина (`Too small`, `Try one line`).
- Canvas не требует Apply/Confirm/Delete.

## 4. Results
Показывает: placement, **committed** earned Coins/status delta, top 3 presentation, `RACE AGAIN` primary CTA, `GARAGE` secondary. Launch has no auto-requeue preference: after a played public heat, only explicit `RACE AGAIN` queues another heat. CTA guard/minimum Results timing follows `74`.

## 5. Garage
Вкладки: Body / Ink / Trail / Finish FX. Для каждого item: preview, owned/price state, equip. Locked item показывает понятный источник, а не неизвестный замок.

## 6. Store
Не является обязательным маршрутом. Context offer открывается из конкретного момента/preview. Платёжные CTA визуально отличимы от soft-currency.

## 7. Settings
Music, SFX, Reduce Motion, Hide/Reduce Rival Custom Shapes, language link/system, performance preset only if реально нужен.

## 8. Input priority
Touch/Mouse drawing > UI navigation. Стартовый релиз: touch + mouse/keyboard platform navigation. Console/gamepad drawing = LATER, не launch scope.

## 9. Safe states
- disconnect: non-blocking banner, gameplay recovery;
- profile load unavailable / GuestSafe: non-blocking `Progress temporarily unavailable` state; hide/disable paid offers and persistent reward/equip actions;
- save delayed: do not show false `Saved`; keep retry/reconcile status non-blocking;
- purchase pending: block duplicate buy button только для данного SKU;
- server update: понятное сообщение после heat.

## 10. Spectating / late join
Exact behavior is `74`: DrawCanvas/PlacementChip hidden; spectator ProgressStrip + `YOU'RE IN NEXT RACE` when initial queue active; camera follows stable leader automatically; no manual target cycling at launch.

## 11. Acceptance
На телефоне игрок должен без чтения длинного текста понять: где он, куда едет, где рисовать, кто впереди, как начать следующую гонку.


## 12. Layout ownership
This file owns WHAT appears and WHEN. `59` owns WHERE/HOW LARGE. If implementation visually deviates from `59` without a Decision Log, the UI is not accepted even if behavior works.
