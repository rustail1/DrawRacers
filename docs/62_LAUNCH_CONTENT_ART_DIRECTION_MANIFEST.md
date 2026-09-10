# 62 — LAUNCH CONTENT & ART DIRECTION MANIFEST
Статус: **FINAL LAUNCH CONTENT / VISUAL IDENTITY CONTRACT v1.3.4**.

This file closes the remaining art/content choices that an artist or implementer should not invent during production. `13_CONTENT_ART_AUDIO.md` owns broad content principles; `36` owns naming/import rules; `43` owns cosmetic fairness/equip; `61` owns prices/progression; `59` owns UI layout.

Camera/rider presentation amendment is approved by `DECISION_LOG_CAMERA_RIDER_PRESENTATION_2026-09-10.md`. It preserves the cube shell as the canonical racer body and adds a separate, nonphysical human rider presentation at E03; it does not authorize rider runtime during the current M0 gate.

## 1. Public identity
- **Primary public title:** `Draw Racers`.
- Internal project codename may remain `DrawRacers` in repository/package names.
- Launch one-line promise: **`Draw your wheels. Redraw. Overtake.`**
- Short description source copy: **`Draw a shape, turn it into real wheels, and race up to 8 players through obstacle courses. Redraw whenever the track changes and find a better shape before your rivals do.`**
- Primary icon text: **no text** unless discovery testing proves a title lockup improves PTR.
- IP release gate: `48` must pass. If `Draw Racers` cannot be legally/platform-cleared, use fallback candidates in this exact order without changing gameplay/visual design: `Doodle Racers` → `Shape Sprint Racers` → `Scribble Wheels`. If all three fail clearance, public release is BLOCKED for Product Owner naming Decision Log; implementers do not invent a fourth name.

## 2. Visual style sentence
**Bright toy-like obstacle racing with chunky readable geometry, hand-drawn energy in the wheel lines, and very low visual noise around collision surfaces.**

The visual identity is deliberately different from Draw Climber: no copied character proportions, UI layout, palette, obstacle arrangement, sound, logos, textures or extracted assets.

## 3. Canonical palette
All hex values are sRGB design references; implementation converts to Roblox Color3.

| Token | Hex | Use |
|---|---|---|
| SkyLight | `#DDF5FF` | Toy Workshop sky/background |
| SkyDeep | `#A8DBF2` | distant layer |
| TrackLight | `#F3F0E8` | primary collision floor |
| TrackEdge | `#394454` | collision silhouette/edge stripe |
| SurfaceDark | `#172033` | Neon Factory background / modal dark |
| SurfaceMid | `#26344B` | panels / dark track shell |
| LocalAccent | `#27C2FF` | local-player neutral accent / primary CTA |
| AccentWarm | `#FFB33C` | reward/highlight secondary |
| Success | `#42D77D` | success icon + text, never hue-only |
| Warning | `#FF9A3C` | warning icon + text |
| Error | `#FF4F6D` | reject/error icon + text |
| TextLight | `#FFFFFF` | text on dark |
| TextDark | `#172033` | text on light |

Rival accent assignment for presentation only, in order: `#FF5C7A`, `#8E7CFF`, `#4FD1A1`, `#FFC857`, `#F77EFF`, `#62B0FF`, `#FF8C42`, `#8FD14F`. Racer number/name remains visible so color is never the only identifier.

## 4. Materials and shape language
- Collision track Parts: `SmoothPlastic` or equivalent matte material; no reflective/translucent collision surface.
- Neon material is decor/edge/VFX only, never the entire collision face.
- Racer collision body remains invisible canonical 3×3×3; visual shell fits within the same envelope and may bevel corners visually by <=0.18 stud.
- Wheel/leg visible stroke is a rounded line/ribbon; physics collider remains hidden/simple segment chain.
- Obstacles use 0.15–0.30 stud visual bevel where practical, but collision remains primitive/readable.
- Decoration sits outside collision silhouette and has `CanCollide=false` unless explicitly part of TrackPiece.

## 5. Typography / icons
- UI primary family: **Gotham / platform equivalent sans**, bold for numbers/CTA, medium for body copy. If Roblox deprecates a specific enum, use the current platform-provided closest sans family without changing hierarchy/weights.
- No decorative script font in gameplay UI.
- Icon set style: filled geometric icons, 2 px equivalent outline where needed; single consistent set for Coin, lock, trophy/mastery, settings, body, ink, trail, finish.
- Icon source must be original/licensed for project; no traced competitor icons.

## 6. Launch world themes
### THEME 01 — `TOY_WORKSHOP`
Used by T01–T10.
- bright sky/light background;
- cream/light-gray collision surfaces + charcoal edge strip;
- background props: oversized pencils, rulers, toy blocks, pegboard silhouettes, paper scraps;
- decor depth layers: far wall / mid props / track; no moving decor near wheel contact;
- start gate: chunky blue arch with white `DRAW!` light panel;
- finish gate: warm accent arch + checker strip.

### THEME 02 — `NEON_FACTORY`
Used by T11–T20.
- dark navy background and dark non-collision structures;
- collision surfaces remain light enough for silhouette readability;
- cyan/magenta/yellow decor strips, but TrackEdge stays consistent;
- background props: conveyor frames, pipes, sign panels, inactive robot arms;
- moving obstacle mechanics are gameplay pieces, not decorative fake hazards.

Theme changes **presentation only**. No friction, gravity, collision, visibility advantage or different geometry is attached to theme identity.

## 7. Launch racer shell
Canonical visual body:
- cube shell aligned to body collider;
- front face has two simple eye shapes + small mouth/sticker area;
- no limbs/character rig;
- local/rival shells never exceed canonical 3×3×3 fairness envelope;
- player display-number badge appears above body via billboard, not painted permanently on shell.

The `no limbs/character rig` rule applies to the **cube shell itself**. Beginning at E03, human racers may additionally render one separate `RiderPresentation` mini-avatar above the cube. The rider is not part of the shell, collider or locomotion assembly.

### Human rider presentation — E03
- Visual direction: compact jockey/frog-rider/rodeo silhouette seated on the cube, with knees/legs visually to the sides, torso slightly forward and arms directed forward/toward the cube.
- The first production version does not require bob/lean animation; that is later presentation polish.
- Use a standardized/normalized avatar presentation rather than allowing arbitrary Roblox body scale to set race silhouette size.
- Starting normalized target scale equivalent = **0.65**. Human Studio comparison sweep = **0.55 / 0.65 / 0.75**.
- A hard visual readability envelope/fallback is mandatory. Oversized bundles, layered clothing or accessories may be simplified/omitted/scaled by a deterministic presentation rule rather than expanding racer gameplay geometry or dominating the race view.
- Rider presentation is nonphysical and never changes BodyCollider/leg dimensions, mass, material, collision, motor, lane behavior, checkpoint/finish authority or camera target authority.
- Rider identity is tied to the human player through the server-authored presentation mapping from `65` and rendered by `RiderPresentationController` from `21`.
- Bots do not imitate human avatar appearance. Bot presentation remains clearly labeled `BOT #N`.
- At 2 and 8 racers, the cube, drawn leg silhouette and upcoming obstacle must remain more readable than rider accessory detail.

The canonical `3×3×3` fairness envelope still owns physical BodyCollider/body-shell dimensions. The separate rider may extend visually above the shell only inside the bounded nonphysical readability envelope approved at E03; it never changes competitive geometry.

## 8. Exact launch cosmetic catalog — 20 produced cosmetics + 1 null trail state
All IDs below are canonical and must exist before public launch. All preserve `PhysicsProfile="STANDARD"`.

### Body — 6
1. `Body_Default_01` — white/blue clean cube — Common — default.
2. `Body_Stripes_01` — diagonal warm stripes — Common — Coins.
3. `Body_Checker_01` — black/cream racing checks — Rare — Coins.
4. `Body_StickerBomb_01` — original doodle sticker collage — Rare — Starter Pass.
5. `Body_NeonGrid_01` — dark shell with cyan/magenta grid — Epic — Neon Pass.
6. `Body_CrownPlate_01` — gold trim/crown emblem printed within shell — Legendary — Premium Pass.

### Ink — 5
7. `Ink_Graphite_01` — dark graphite rounded stroke — Common — default.
8. `Ink_Sky_01` — bright sky blue — Common — FTUE completion reward.
9. `Ink_Coral_01` — coral-red stroke — Common — Coins.
10. `Ink_Lime_01` — lime stroke with subtle glow edge — Rare — Starter Pass.
11. `Ink_Spectrum_01` — moving rainbow gradient visual only — Epic — Neon Pass.

### Trail — 5 runtime entries (4 produced + 1 null state)
12. `Trail_None` — no trail — default.
13. `Trail_SpeedLines_01` — sparse white speed dashes — Common — Coins.
14. `Trail_Dots_01` — fading dot chain — Rare — Coins.
15. `Trail_Pixel_01` — sparse square pixels — Epic — Neon Pass.
16. `Trail_Stars_01` — sparse small star particles — Legendary — Premium Pass.

### Finish FX — 5
17. `Finish_Pop_01` — small radial paper-pop — Common — default.
18. `Finish_Confetti_01` — short confetti burst — Rare — Coins.
19. `Finish_Spark_01` — three warm spark arcs — Rare — Starter Pass.
20. `Finish_NeonBurst_01` — cyan/magenta ring burst — Epic — Neon Pass.
21. `Finish_CrownBurst_01` — gold crown glyph + rays — Legendary — Premium Pass.

**Catalog count note:** `Trail_None` is a null/default equip state rather than a produced cosmetic asset. Produced launch cosmetic assets = **20** (6 bodies + 5 inks + 4 non-null trails + 5 finish FX). Runtime catalog contains **21 entries** including `Trail_None`.

The Roblox avatar rider is identity presentation, not a new Draw Racers paid cosmetic category in this launch catalog. `CosmeticService` still owns Body/Ink/Trail/Finish FX ownership and equip.

## 9. Paid bundle presentation
- Starter bundle theme: `DOODLE STARTER` — StickerBomb + Lime Ink + Spark Finish.
- Neon bundle theme: `NEON RUSH` — NeonGrid + Spectrum Ink + Pixel Trail + Neon Burst.
- Premium bundle theme: `CROWN FINISH` — CrownPlate + Stars Trail + Crown Burst.
- Exact price hypotheses: `61`.
- Bundle cards use in-game preview renders, never illustrated power claims.

## 10. Launch scene/assets checklist
Required produced assets before public launch:
- 2 theme environment kits;
- 24 TrackPiece visual shells/decoration sets compatible with `60` collision blockouts;
- start gate + finish gate for both themes;
- 20 produced cosmetic assets + `Trail_None` null state;
- garage preview pedestal/scene;
- podium 1/2/3 scene;
- Coin, Mastery/Trophy, Settings, Lock, Body, Ink, Trail, FinishFX icons;
- title/logo wordmark `Draw Racers`;
- 3 discovery thumbnail compositions and 3 short-video capture templates;
- UI panel/button/nine-slice assets matching `59` tokens;
- VFX: shape apply, finish pop, confetti, spark, neon burst, crown burst;
- audio categories from `47`.

Rider implementation is generated from the player's normalized avatar presentation and deterministic pose/envelope contract; it does not add a new paid launch asset count. Any helper pose/rig assets introduced by implementation still follow `36/69/70` provenance rules.

## 11. Discovery creative freeze
### Thumbnail A — `HOOK OVER STEPS`
- foreground local cube on left-middle;
- oversized hook-like drawn leg clearly contacting tall steps;
- one rival with round wheel stuck/behind;
- finish direction readable to right;
- no UI except optional small 1/8-style placement chip if captured from game.

### Thumbnail B — `TINY WHEEL TUNNEL`
- giant rival wheel blocked by low tunnel;
- local compact shape passing underneath;
- strong silhouette contrast; no explanatory paragraph.

### Thumbnail C — `8 WEIRD RACERS`
- diagonal race pack of 8 cubes, each with visibly different legal leg shapes;
- one readable obstacle ahead;
- avoid visual pile-up by staggered progress positions.

Creative hypothesis testing/acceptance remains `38/55 G6`; these are the exact first three production assets, not guaranteed winners.

## 12. Camera/art readability constraints
- No theme prop may cover the upcoming obstacle silhouette in the camera framing from `16`.
- Active-race particle lifetime <=1.0 s for normal contact/shape feedback; finish FX may run <=1.5 s after local finish.
- Trails are capped to a visually sparse footprint and can be reduced/hidden by accessibility setting.
- No full-screen flash brighter than 20% opacity overlay; Reduce Motion removes nonessential scale/zoom/shake.
- Rider silhouettes/accessories are subject to the same race-readability priority: they may not cover the local/rival leg silhouette or make the next obstacle unreadable in the canonical camera framing.

## 13. Ownership and approval
Artist may choose implementation details such as mesh topology, texture packing and UV layout. Artist may **not** independently change palette role, shell size, catalog identity, theme identity, obstacle readability, UI hierarchy, rider readability envelope, or add gameplay collision. Any such change requires the relevant owner doc/Decision Log.
