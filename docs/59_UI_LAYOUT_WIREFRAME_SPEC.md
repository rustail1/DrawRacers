# 59 — UI LAYOUT / WIREFRAME SPEC
Статус: **FINAL PRESENTATION LAYOUT CONTRACT v1.3.4**.

This file owns **where player-facing UI is placed and how large it is**. Exact ScreenGui child names/controller/focus binding are owned by `68_UI_COMPONENT_HIERARCHY_IMPLEMENTATION_SPEC.md`. `29_UI_SCREEN_FLOW_SPEC.md` owns screen behavior/state transitions; `37_LOCALIZATION_ACCESSIBILITY.md` owns accessibility/localization. Any implementation may change HOW the hierarchy is coded, but it must preserve the observable layout contract below unless a Product Owner Decision Log changes this file.

## 1. Reference canvas and responsive modes
- Launch orientation: **landscape only**.
- Reference artboard: **1920×1080, 16:9**.
- All layout values below are normalized viewport fractions inside a SafeRoot; do not hard-code 1920×1080 pixel coordinates.
- SafeRoot uses visible safe area after Roblox top/system insets. Additional inner margin: `2.5% viewport width` left/right and `2.0% viewport height` top/bottom, minimum 16 px.
- Minimum interactive target: **48×48 px** at 1080p equivalent; primary touch CTAs target 56–64 px equivalent.
- `TOUCH_LAYOUT`: last meaningful gameplay input is touch OR touch-only device. `DESKTOP_LAYOUT`: mouse/keyboard. Hybrid devices switch after the next non-drawing input family; an in-progress stroke never switches layout.
- Critical race information must remain visible from 16:9 through ~2.2:1 landscape aspect. Extra width expands world view first; HUD remains inside SafeRoot.

Notation: `A(x,y)` = AnchorPoint. `P(x,y)` = SafeRoot-relative position. `S(w,h)` = SafeRoot-relative size.

## 2. Z-order contract
| Layer | ZIndex band | Content |
|---|---:|---|
| World billboards | world | racer name/number markers only |
| HUD base | 10–19 | placement, progress, settings |
| Draw UI | 20–29 | DrawCanvas, stroke preview, validation |
| Race feedback | 30–39 | countdown, finish placement, banners |
| Modal screens | 50–69 | Results, Garage, Store, Settings |
| Purchase platform prompt | platform | Roblox-owned prompt |
| Critical error/update | 90–99 | blocking only when continuing safely is impossible |

No cosmetic/VFX element may render above DrawCanvas input feedback or modal purchase/status copy.

## 3. RACING — exact HUD composition
### Shared
| Element | Anchor | Desktop | Touch | Notes |
|---|---|---|---|---|
| PlacementChip | A(0,0) | P(.025,.025) S(.115,.070) | P(.025,.025) S(.145,.078) | Shows `3 / 8`; player number icon at left |
| ProgressStrip | A(.5,0) | P(.500,.030) S(.420,.040) | P(.500,.030) S(.390,.044) | Local marker + nearest two rivals + finish icon |
| SettingsButton | A(1,0) | P(.975,.025) S(.050,.070) | P(.975,.025) S(.065,.078) | gear icon; opens non-destructive settings |
| DrawCanvas | A(.5,1) | P(.500,.975) S(.460,.255) | P(.500,.975) S(.640,.285) | lower center; rounded panel, transparent enough to see world silhouette |
| ValidationToast | A(.5,1) | P(.500,.705) S(.320,.052) | P(.500,.675) S(.440,.058) | max 2.0 s; accepted/rejected only |
| DrawHint | A(.5,1) | P(.500,.705) S(.380,.060) | P(.500,.675) S(.500,.064) | FTUE/timed hint only; mutually exclusive with toast |
| ConnectionBanner | A(.5,0) | P(.500,.085) S(.420,.050) | same | non-blocking; never covers progress strip |

### DrawCanvas internal layout
- Inner drawing rect: 92% width × 82% height centered; remaining area is border/status only.
- Stroke visual thickness: 6 px equivalent desktop, 8 px touch; physics thickness is unrelated.
- Empty-state ghost icon centered at 18% opacity until first pointer-down; disappears permanently for that heat after first stroke.
- Pivot marker: non-interactive 8 px equivalent dot at exact DrawInputRect center `(0,0)`, 25% opacity; semantic mapping owner is `73`.
- No Apply / Confirm / Delete button.
- Input rect exactly matches visible drawing rect; no invisible oversized hit area.
- Current accepted-shape thumbnail: top-right of canvas, 14% canvas width, square; informational only, no click.
- Local preview color uses equipped Ink; invalid preview adds dashed outline, not color-only failure.

### World billboards
- Each visible human racer has a compact marker above body: `#N` + truncated display name (max 12 glyphs), no chat/status text. Bots use exact label `BOT #N` and never imitate a human name/avatar.
- Local racer marker hidden unless needed for accessibility/high-overlap mode.
- Opponents farther than camera readable range are represented only in ProgressStrip.

## 4. PREP / COUNTDOWN
- DrawCanvas already visible in final Racing position.
- `PREP`: center-top prompt `DRAW YOUR WHEELS` at A(.5,0), P(.5,.16), S(.42,.08).
- Countdown `3 / 2 / 1 / GO!`: A(.5,.5), P(.5,.42), S(.22,.18); Reduce Motion uses opacity/scale <=1.05, no screen shake.
- PlacementChip is visible but displays `– / 8` until race starts.

## 5. FINISHING
- DrawCanvas fades to 35% opacity and stops accepting input immediately after authoritative finish.
- Placement burst: A(.5,.5), P(.5,.40), S(.38,.18), text `1ST!` / `2ND!` etc.
- Reward teaser below: P(.5,.54), S(.34,.06). Before server grant commit show `CALCULATING REWARDS…`; after commit show only canonical committed delta such as `+120 COINS`. GuestSafe shows `PROGRESS UNAVAILABLE`, never a fake reward.
- Duration and reward timing semantics use `74`; Results follows automatically.

## 6. RESULTS — exact layout
Modal panel: A(.5,.5), P(.5,.5), S(.72,.78) desktop; S(.86,.84) touch.

Inside panel, normalized to panel:
- Header/placement: A(.5,0), P(.5,.055), S(.50,.12).
- Top-3 podium presentation: P(.5,.24), S(.78,.28).
- Reward row: P(.5,.52), S(.72,.10): Coins delta, Mastery delta, unlock/status delta.
- Next-goal row: P(.5,.64), S(.72,.08), one concrete target only.
- `RACE AGAIN`: A(.5,1), P(.5,.945), S(.48,.13) desktop; S(.58,.14) touch. Visible immediately; disabled first 0.75s; click sets queue intent; label becomes `QUEUED`; actual server-ready after 3.5s Results minimum per `74`.
- `GARAGE`: A(0,1), P(.045,.945), S(.20,.11) desktop; S(.23,.12) touch.
- Settings icon remains top-right outside modal.
- No Shop CTA competes with `RACE AGAIN`. Context paid offer may appear only as one compact card between reward and next-goal rows after eligibility in `45` is true; it must not move the primary CTA.

Exact English copy:
- primary: `RACE AGAIN`
- secondary: `GARAGE`
- reward label: `RACE REWARDS`
- next goal label: `NEXT GOAL`
- DNF header: `FINISH NEXT TIME` (not punitive)

## 7. SPECTATING / LATE JOIN — exact HUD
- Hide DrawCanvas, DrawHint, ValidationToast and local PlacementChip.
- Keep spectator ProgressStrip at the normal top-center position, showing current leader + nearest race markers.
- Banner: A(.5,0), P(.5,.095), S(.42,.055), exact copy `YOU'RE IN NEXT RACE` when initial queue intent is active; otherwise `SPECTATING`.
- Small secondary `GARAGE` CTA may appear bottom-left outside modal only if profile safely loaded; opening Garage does not cancel queue.
- Spectator camera policy is `74`; no manual next/previous target buttons at launch.

## 8. GARAGE — exact layout
Full-screen modal over garage preview scene.
- Top bar: A(.5,0), P(.5,.02), S(.95,.08): title `GARAGE`, Coins at right, Close at far right.
- Category rail: A(0,0), P(.025,.13), S(.18,.72) desktop; touch uses horizontal tabs P(.5,.12), S(.90,.075).
- Categories in fixed order: `BODY`, `INK`, `TRAIL`, `FINISH FX`.
- Preview viewport: desktop P(.43,.49), S(.42,.66); touch P(.34,.50), S(.54,.62).
- Item grid: desktop P(.79,.49), S(.34,.66); touch P(.77,.50), S(.40,.62).
- Detail/CTA bar: bottom P(.5,.92), S(.92,.11). States: `EQUIP`, `EQUIPPED`, `{PRICE} COINS`, `UNLOCK: {SOURCE}`, `OWNED`.
- Selecting locked/pass item previews it before purchase. Preview never grants race equip until server-confirmed ownership.
- Close returns to Results/requeue context without cancelling an already queued next heat unless user explicitly chooses `LEAVE QUEUE`.

## 9. STORE / contextual offer
No mandatory standalone shop in FTUE. When opened:
- modal S(.66,.70) desktop; S(.86,.78) touch;
- one hero offer + at most two secondary cards;
- Robux CTA always includes Robux icon + numeric platform price returned by current platform API; never hard-code stale display price into art;
- soft-currency CTA uses Coin icon and cannot share the same button styling as Robux purchase.
- close button top-right, 48px min target.
- paid-offer eligibility and products are owned by `45/61/62`; purchase grant by `56`.

## 10. SETTINGS
Panel S(.48,.64) desktop; S(.76,.72) touch.
Fixed order:
1. Music toggle
2. SFX toggle
3. Reduce Motion toggle
4. Rival Shape Detail: `FULL / REDUCED / HIDDEN`
5. High Contrast Progress Markers toggle
6. Language/system localization entry
7. `RETURN TO RACE` / `CLOSE`

No destructive account/data action in launch Settings.

## 11. LOADING / GuestSafe / update states
### Loading / place transition
- center logo/title at P(.5,.38) S(.50,.14)
- progress text P(.5,.55) S(.42,.06), no fake percentage unless actual measurable progress exists.
- cross-place route copy: `CONNECTING TO RACES…`; retry button on a surfaced routing failure: `TRY AGAIN`.

### GuestSafe
Non-blocking persistent banner below top HUD: `PROGRESS TEMPORARILY UNAVAILABLE`.
Garage is browse-only; `EQUIP`, Coin spend and Robux offer buttons disabled with tooltip `TRY AGAIN WHEN PROGRESS IS AVAILABLE`.

### Server update
After heat/results: modal `SERVER UPDATE` / `REJOIN` primary. Never interrupt an active stroke or race unless platform disconnect forces it.

## 12. FTUE choreography / copy ownership
0–20 s: `DRAW YOUR WHEELS` above canvas.
First valid movement: no text; use apply pulse + motion.
First geometry mismatch timed hint after stuck threshold: `DRAW A DIFFERENT SHAPE`.
Low-clearance example hint only after failed attempt: `TRY SMALLER`.
Reach example hint only after failed attempt: `TRY LONGER`.
First finish Results adds `YOU CAN REDRAW ANY TIME` only if player completed with zero redraws; otherwise omit.

All copy uses localization keys; these English strings are canonical launch source copy.

## 13. UI visual tokens
- Corner radius: 14 px small chips/buttons, 22 px modal/cards equivalent.
- Border: 2 px equivalent high-contrast outline for interactive components.
- Primary CTA: filled accent; secondary CTA: neutral surface; destructive style unused at launch.
- Body text min 18 px equivalent desktop, 20 px touch; HUD numerals 24–34 px; countdown 72–110 px.
- Use icons + text for Coins, placement, lock and warnings. Never encode required meaning by hue alone.

Exact palette/font assets are owned by `62_LAUNCH_CONTENT_ART_DIRECTION_MANIFEST.md`.

## 14. Acceptance / screenshot matrix
UI is accepted only when screenshots/video pass all of:
1. 1920×1080 desktop.
2. 1366×768 desktop.
3. 2532×1170 touch landscape/notch-safe.
4. 2400×1080 wide touch landscape.
5. low-end target from `57`.

For each: no overlap, no clipped text in English, DrawCanvas never covers the next meaningful obstacle read, primary CTA is visible without scrolling, and safe-area/system bars do not occlude input.
