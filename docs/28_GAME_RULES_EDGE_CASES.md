# 28 — GAME RULES & EDGE CASES
Статус: **BEHAVIOR CONTRACT v1.3.4**. Этот файл закрывает спорные состояния игры. Числа не дублируются: конкретные значения живут в `16_BALANCE_TUNING.md`/runtime configs.

## 1. Базовое правило
Игрок управляет только рисунком движителя. Куб не получает ручной газ, прыжок или steering. Победа определяется сервером по валидному пересечению Finish после упорядоченных checkpoints.

## 2. До старта
- Новый/late-join игрок не вставляется в уже идущую гонку: ждёт следующего heat.
- В PREP разрешено рисовать; если валидной формы нет к GO, **никакая StarterShape не создаётся**: racer остаётся stationary и получает strong draw hint (`73/74`).
- Countdown никогда не ждёт конкретного игрока.

## 3. Рисование
- Один pointer gesture = один stroke.
- Пока новый stroke рисуется, старая нога продолжает работать.
- После release сервер валидирует и атомарно заменяет обе ноги одной ShapeSpec.
- Невалидный stroke не уничтожает старую форму; клиент получает причину отказа.
- Самопересечение разрешено, но физическая геометрия ограничивается budget и safety rules.
- DrawCanvas не является публичным art-board; stroke не сохраняется и не публикуется.

## 4. Физика
- Body, hitbox, масса, motor envelope и максимальный radius одинаковы для всех косметик.
- Leg ↔ Track collides. Leg ↔ Body, Leg ↔ Leg и Racer ↔ Racer физически не сталкиваются.
- Cosmetic meshes `CanCollide=false`, `Massless=true` и не меняют COM.
- Скрытый assist допускается только против полного stall; он не проходит препятствие вместо формы.

## 5. Падение / застревание
- Выход body center за canonical `KillPlaneY` from `74` или подтверждённый unrecoverable state → respawn на последний валидный checkpoint.
- Respawn не сбрасывает race elapsed time и даёт фиксированный penalty из config.
- Stuck hint появляется раньше auto-respawn; игроку сначала дают шанс redraw.
- Respawn никогда не переносит вперёд последнего подтверждённого checkpoint.

## 6. Финиш
- Первый серверный валидный Finish enter после всех checkpoints фиксирует finishOrder.
- После первого финишировавшего запускается `FinishGraceWindow=15s` starting default; hard timeout and exact deterministic DNF tie-break are `74`.
- Игрок, вышедший до финиша, получает Leave/DNF и не получает placement bonus.
- RewardService выдаёт награду через unique server `GrantId` и idempotent profile mutation (`31/44/74`); client-visible raceId не является единственным exactly-once ключом.

## 7. Ремач и late join
Exact semantics/timeouts are owned by `74`. Launch has **no auto-requeue setting**.
- `RACE AGAIN` visible immediately, disabled for 0.75s; click sets queue intent; server-ready begins only after Results minimum 3.5s.
- Игроки с confirmed requeue intent идут в next assembly; отсутствие клика не блокирует сервер.
- Newly arrived completed player receives one automatic initial next-heat queue intent; late join spectates current heat with `YOU'RE IN NEXT RACE`.
- Garage does not cancel queue; explicit `LEAVE QUEUE` does.

## 8. Косметика
- Equip разрешён только owned item.
- Смена косметики во время Racing откладывается до следующего heat.
- Вся cosmetic progression не меняет physics config.

## 9. Сеть и ошибки
- Клиент никогда не сообщает `IWon`, Coins, authoritative CFrame или purchase result.
- Потеря remote ответа на stroke не должна удалять старые ноги.
- При кратком network stall визуальный клиент может интерполировать, но server state остаётся истиной.
- **Initial profile load failure after bounded retries:** player may race only in `GuestSafe` mode per `31/41`; persistent rewards/equip/purchases are disabled and UI states that progress is temporarily unavailable.
- **Save failure after a safely loaded profile:** current heat may continue; profile remains dirty and retries/reconciles per `31`. UI never shows false `Saved`.
- Developer Product purchase recovery follows `56`; do not invent a separate “high priority save” path that can duplicate a grant.

## 10. Серверные shutdown/update
- Новые heats не стартуют после начала controlled shutdown.
- Идущий heat либо получает короткое завершение, либо закрывается без placement reward, если безопасно завершить нельзя.
- Dirty profiles сохраняются по shutdown path; не обещать игроку сохранение до подтверждённого write.

## 11. Запрещённые неоднозначности
Нельзя импровизировать: P2W physics, mid-race track differences, PvP collisions, client-authoritative reward/finish, сохранение свободных рисунков, mandatory long lobby, forced shop between races.
