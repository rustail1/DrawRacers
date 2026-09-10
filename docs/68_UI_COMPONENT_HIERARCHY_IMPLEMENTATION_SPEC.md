# 68 — UI COMPONENT HIERARCHY & IMPLEMENTATION SPEC
Статус: **EXACT UI INSTANCE/CONTROLLER CONTRACT v1.3.4 / R16.3B**.

Цель: `59` already fixes layout; this file fixes **ScreenGui/component names, controller ownership and state binding**, so UI programmer/Codex does not invent a second hierarchy.

Camera/rider input and presentation ownership amendment is approved by `DECISION_LOG_CAMERA_RIDER_PRESENTATION_2026-09-10.md`. It is sequence-gated to D09/E03 and does not change current M0 runtime ownership.

## 1. ScreenGui roots
All launch ScreenGui use `ResetOnSpawn=false`, SafeRoot container and controller-owned visibility.

```text
RaceHUD
  SafeRoot
    PlacementChip
    ProgressStrip
    SettingsButton
    CountdownLayer
    FinishLayer
    ConnectionBanner
DrawHUD
  SafeRoot
    DrawCanvas
      DrawInputRect
        StrokePreview
          AcceptedLayer
          LiveLayer
      AcceptedShapeThumbnail
      EmptyGhost
    ValidationToast
    DrawHint
ResultsHUD
  Dimmer
  SafeRoot
    ResultsPanel
      PlacementHeader
      PodiumViewport
      RewardRow
      OfferSlot
      NextGoalRow
      RaceAgainButton
      GarageButton
GarageHUD
  Dimmer
  SafeRoot
    TopBar
    CategoryRailOrTabs
    PreviewViewport
    ItemGrid
    DetailBar
StoreHUD
  Dimmer
  SafeRoot
    StorePanel
      HeroOffer
      SecondaryOffers
      CloseButton
SettingsHUD
  Dimmer
  SafeRoot
    SettingsPanel
      MusicRow
      SfxRow
      ReduceMotionRow
      RivalShapeDetailRow
      HighContrastRow
      LanguageRow
      CloseButton
```
Exact positions/sizes/copy = `59`. Palette/art tokens = `62`.

## 2. Controller ownership
- `InputController`: platform pointer normalization for DrawCanvas only; it does not become a general camera manager.
- `DrawingController`: DrawCanvas stroke state/preview/submit/result.
- `RaceCameraController`: beginning at D09, owns active-race camera target smoothing, look-ahead, bounded world free-look gesture state and automatic return; no gameplay authority/remotes.
- `RiderPresentationController`: beginning at E03, owns human mini-avatar rider visual binding/pose/normalization/cleanup only; no racer physics, camera targeting or cosmetic entitlement authority.
- `HUDController`: PlacementChip, ProgressStrip, CountdownLayer, FinishLayer, ConnectionBanner.
- `ResultsController`: ResultsHUD state + RequeueRequest.
- `GarageController`: category/select/preview/equip request.
- `StoreController`: offer cards + platform prompt request; never grants ownership.
- `SettingsController`: local/persistent presentation preferences through SettingsRequest.
- `AudioController`: semantic SFX/music from `47`.
- `FeedbackController`: haptic/VFX presentation routing; no gameplay authority.

No controller directly mutates Coins/ownership/finish. `RaceCameraController` and `RiderPresentationController` are target/future controllers until their ordered D09/E03 tasks become active; current M0 must not instantiate them early.

## 3. UI state model
Canonical local presentation states:
`LOADING | PREP | COUNTDOWN | RACING | FINISHING | RESULTS | GARAGE | STORE | SETTINGS | ROUTING | GUEST_SAFE | UPDATE`.
Only one modal family (`RESULTS/GARAGE/STORE/SETTINGS`) owns modal input at a time. Settings may overlay race non-destructively; DrawCanvas input pauses while Settings modal owns pointer focus.

## 4. DrawCanvas input rules
- **R16.3B:** DrawCanvas contains one **wide semantic DrawInputRect** with canonical semantic aspect `1.75:1`; its visible boundary and pointer-capture area are the same rectangle. Exact geometry and responsive sizes are owned by `59`.
- Isotropic normalization uses half the DrawInputRect pixel height as one semantic unit on both axes. Raw input limits are `X ±1.75`, `Y ±1.0`; the wide UI must never stretch physical X/Y geometry.
- only `DrawInputRect` captures drawing pointer;
- pointer-down inside starts one stroke;
- pointer exit does not terminate until pointer-up/cancel;
- second touch does not create second stroke; it is ignored for draw while primary stroke active;
- system gesture/cancel aborts local unfinished stroke, current accepted shape remains;
- no submit until pointer-up;
- sequence increments locally per submission;
- awaiting server result does not freeze racer/current old shape;
- accepted `StrokeResult.acceptedPoints` are first-point-anchored server authority; DrawingController may use the sequence-scoped submitted first point only as a presentation anchor so the accepted line remains where the player drew it;
- that presentation anchor is local-only and cannot alter ShapeSpec, collider geometry, motor physics or server authority;
- rejected result keeps previous accepted thumbnail.

Future D09 camera gesture ownership must preserve all rules above. In particular, camera code may observe world-space RMB/touch gestures but never changes `InputController`'s drawing-pointer semantics or steals an already-started DrawInputRect stroke.

## 5. Data binding
UI receives immutable/view-model values from controllers; Roblox Instances are not the source of authoritative business state.
Examples:
- placement comes from RaceEvent/progress replication;
- Coins displayed from ProfileEvent/canonical profile snapshot;
- ownership/equip result only after CosmeticResult/ProfileEvent;
- platform prompt success alone is not entitlement proof; server-confirmed state drives owned badge.

`OwnerUserId` on a human racer is a server-authored presentation lookup key from `65`, not business authority. `RiderPresentationController` may use it to bind a player appearance to the corresponding visible racer but cannot infer ownership/reward/equip state from it.

## 6. Buttons exact behavior
`RACE AGAIN`: exact guard/readiness semantics are `74`: visible immediately, disabled 0.75s, one request sets queue intent, duplicate clicks ignored, server-ready after Results minimum 3.5s.
`GARAGE`: opens Garage; does not silently cancel queue; queued state exposes explicit `LEAVE QUEUE` before roster lock.
`EQUIP`: sends CosmeticRequest; pending visual state; rollback on reject.
Coin purchase button: server validates current price/ownership and applies persistent mutation.
Robux CTA: requests canonical offer; platform prompt handled by Store/Monetization path.
Settings: immediate local preview, server persistence where key is persistent.

## 7. Responsive implementation
Use scale/constraints/anchor logic from `59`; do not build separate handcrafted mobile UI tree. Touch/Desktop switch changes layout tokens on same semantic components. In-progress stroke never reparents/reflows until stroke ends.

## 8. Localization
All visible source strings use localization keys. Dynamic text uses formatted key + numeric parameter, not concatenated English where translation order matters. Truncation policy: display name max 12 glyphs; system copy wraps according to `59`; CTA cannot truncate in supported launch English/reference expansion test.

## 9. Focus/input priority
Priority:
`platform purchase prompt > critical update/error > modal > settings overlay > DrawCanvas > world camera gestures`.
During drawing, camera does not consume the same pointer. Keyboard/mouse camera controls that do not conflict may remain according to RaceCameraController.

D09 exact free-look ownership:
- desktop LMB belongs to drawing/UI interaction and is never a camera toggle;
- desktop free-look starts only while RMB is held in allowed world space; RMB release ends free-look and begins automatic return to canonical side framing;
- no second RMB/LMB click is required for return;
- a touch beginning in `DrawInputRect` remains drawing-owned through end/cancel even after pointer exit;
- a touch beginning on active UI remains UI-owned through end/cancel;
- a touch can become a camera gesture only when it begins in world space outside DrawCanvas and active UI;
- gesture ownership does not switch mid-touch;
- modal/settings focus always suppresses world-camera gesture start.

Exact camera limits/damping/return values live in `16`; this file owns only focus/controller binding semantics.

## 10. Accessibility bindings
- Reduce Motion disables nonessential scale/shake and FeedbackController motion/haptic extras as `37/47`;
- deliberate gameplay camera shake obeys Reduce Motion; ordinary racer physics is not an implicit source of camera shake;
- Rival Shape Detail controls rival visual complexity only, not physics;
- High Contrast adds icon/outline marker, never changes competitive geometry;
- all errors have icon + text, not color alone.

## 11. Spectator presentation
When `74` marks local player spectating: DrawingController disabled/hidden, HUDController uses spectator ProgressStrip/banner view-model, RaceCameraController follows stable leader per `74`, and ResultsController/queue view-model preserves initial next-heat intent. No launch manual camera target cycling.

Active-race free-look never changes the underlying Local Racer target. Spectator target ownership remains separate and entirely governed by `74`.

## 12. Rider presentation binding — E03
`RiderPresentationController` is introduced only at E03 after production camera exists.
- It creates at most one normalized human rider visual for one visible human racer mapping.
- It consumes server-authored presentation identity (`OwnerUserId`) plus player appearance; it does not create/modify authoritative racer state.
- It applies the deterministic pose/visual envelope from `62` and nonphysical instance rules from `65`.
- It does not target bots with human avatar presentation.
- It does not own Body/Ink/Trail/FinishFX entitlement or equip; that remains `CosmeticService`/profile authority.
- It cleans up rider visuals/connections when the racer or player presentation leaves scope.
- It does not become the target input for `RaceCameraController`; camera follows racer position, not rider head/accessories.

## 13. Reward presentation safety
FINISHING/RESULTS numeric reward UI binds only to committed race-grant/profile delta. Before commit display `CALCULATING REWARDS…`; GuestSafe uses `PROGRESS UNAVAILABLE`. Placement may display immediately because finish authority is separate from persistence.

## 14. Screenshot automation contract
Create a DEV screenshot harness that can force each UI state with deterministic mock view-model values. Required captures are `59` matrix plus: PREP, RACING accepted/rejected, FINISHING 1st/8th, RESULTS win/DNF/unlock/eligible offer, GARAGE owned/locked/pass, STORE, SETTINGS, GuestSafe, routing failure, server update.

E03 readability capture also includes local + rival rider presentation with 2 racers and the full 8-racer case, using at least one oversized-appearance fallback case. These captures remain presentation evidence and do not replace the device/performance matrix in `57`.

## 15. Acceptance
PASS when hierarchy names exist exactly, controller ownership matches above, no duplicated modal/hud implementation exists, all 59 screenshot layouts pass, touch drawing does not leak into UI/camera, and no client UI path can authoritatively award reward/equip/purchase.

For D09/E03, PASS additionally requires: camera gestures never steal DrawCanvas input; RMB release reliably returns to canonical framing; active-race camera remains Local-Racer-owned; rider presentation stays nonphysical and within the accepted 2/8-player readability envelope.
