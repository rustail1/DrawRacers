# 60 — TRACKPIECE PARAMETER CATALOG & FIRST 20 TRACKS
Статус: **LAUNCH LEVEL CONTENT NUMERIC CONTRACT v1.3.4**.

Exact blockout→8-lane→theme→release production procedure is `67_LEVEL_BUILD_ASSEMBLY_RELEASE_PLAYBOOK.md`; exact Studio template structure is `65`.

This file owns the **starting dimensions/validated-authoring targets** for launch TrackPieces and the exact first 20 authored TrackDefinitions. Values are project starting hypotheses to be tuned through `55`/`16`, not facts copied from a reference. `04` owns design grammar; `30` owns serialized schemas; `42` owns physical authoring conventions.

## 1. Coordinate convention
- Travel axis: +X.
- Lane centerline: Z=0 before per-lane offset.
- Baseline floor top: Y=0.
- Racer body collider: 3×3×3 studs (`16`).
- `Length` includes safe entry/exit pads where listed.
- Static collision edges use simple Parts; decorative shells never change these dimensions.
- Parameter ranges are hard authoring bounds until a gate-backed Decision Log changes them.

## 2. Canonical 24 TrackPieces
| Id | Length | Default parameters | Allowed launch range | Primary read |
|---|---:|---|---|---|
| FlatShort | 18 | flat Y=0 | Length 14–22 | baseline speed |
| FlatLong | 36 | flat Y=0 | Length 30–44 | pure comparison |
| MicroBumps | 24 | bump H=.8, W=2.0, spacing=4.0, count=5 | H .5–1.1; spacing 3.5–4.5 | stability |
| RollingHills | 30 | hill H=1.5, half-length=5, count=3 | H 1.0–2.0; half-length 4–6 | rounded contact |
| SmallSteps | 28 | repeated block H=1.5, D=4.0, gap=1.0, count=5 | H 1.2–1.8; D 3.5–4.5; gap .8–1.2 | reach intro |
| TallSteps | 32 | repeated block H=2.5, D=4.5, gap=1.0, count=5 | H 2.2–2.8; D 4–5; gap .8–1.2 | hook/long |
| StairUp | 32 | riser H=1.7, tread=4.0, count=6 | H 1.4–1.9; tread 3.5–4.5 | repeated climb |
| StairDown | 28 | drop H=1.6, tread=4.0, count=5 | H 1.3–1.9 | post-climb stability |
| SingleWallLow | 20 | wall H=2.6, thickness=2.0, centered; approach/exit=9 | H 2.2–3.0 | first climb |
| SingleWallHigh | 24 | wall H=4.2, thickness=2.0, centered; approach/exit=11 | H 3.8–4.6 | hook mastery |
| GapSmall | 24 | gap=3.2 centered; approach/landing=10.4 | gap 2.8–3.6 | reach |
| GapMedium | 28 | gap=5.6 centered; approach/landing=11.2 | gap 5.0–6.2 | strong reach |
| BrokenPlatforms | 34 | platform=4.0, gap=3.5, platforms=5 | platform 3.5–4.5; gap 3.0–4.0; total must equal Length | repeated reach |
| LowTunnelWide | 28 | ceiling clearance=4.25, tunnel=16 | clearance 3.95–4.50; tunnel 14–18 | compact |
| LowTunnelSteps | 32 | clearance=4.45, internal steps H=.9 D=4 count=3 | clearance 4.2–4.7; H .7–1.1 | compact+climb |
| CeilingTeeth | 30 | base clearance=6.2, tooth low point=4.4, tooth width=2, count=5 | low point 4.1–4.7 | punish huge radius |
| VValley | 30 | depth=3.0, down/up slope length=10 | depth 2.6–3.5 | reach from depression |
| NarrowPit | 26 | pit width=5.0, depth=3.4, approach/exit=10.5 | width 4.5–5.6; depth 3.0–3.8 | long lever |
| AlternatingBlocks | 34 | block H=2.0, W=4.0, gap=3.0, count=5 | H 1.7–2.4; gap 2.6–3.4 | contact rhythm |
| RampUp | 28 | angle=18°, ramp run=18, approach/exit=5 | 14–22° | traction |
| RampDownIntoGap | 30 | angle=-18°, ramp run=14, gap=4.8, landing=10 | angle -14…-22°; gap 4.3–5.3 | transition+reach |
| MovingGate | 26 | gate period=3.0s, open window=1.35s, closed clearance=1.6, open clearance=7.0 | period 2.6–3.6; open 1.1–1.6 | timing |
| MovingPlatformGap | 34 | gap=8.0, platform W=5.0, travel=3.0, period=3.6s | gap 7–9; travel 2.5–3.5; period 3.2–4.2 | timing+reach |
| FinishSprint | 40 | flat Y=0; finish line at X=36 | Length 34–46 | final comparison |

## 3. Exact collision construction recipes
All coordinates are **piece-local** before TrackService places the piece. `Start` is `(0,0,0)`. `End.X = Length`; `End.Y` follows the top-surface endpoint described below. Collision width is exactly `Z=-4..+4` (8 studs) unless a moving gameplay object explicitly spans that same width. Standard solid floor thickness is 2 studs, so a flat top at Y=0 uses a Part centered Y=-1. Decorative shells are non-collidable.

TrackPiece authoring may use `Part`/`WedgePart` or equivalent simple primitives, but the **top collision profile/intervals below are exact**. A different topology that merely looks similar is not accepted.

### FlatShort / FlatLong / FinishSprint
- One continuous floor over `X=0..Length`, top Y=0.
- `FinishSprint`: Finish trigger plane center X=`Length-4`, spans lane width and safe racer height; final checkpoint must already be satisfied before Finish can count.

### MicroBumps
- Continuous baseline floor X=0..24, top Y=0.
- Five triangular wedge bumps, each base width 2.0 and height H, centered at X=`4,8,12,16,20`.
- Each bump top profile: Y=0 at centerX−1 and centerX+1; Y=H at centerX.

### RollingHills
- Three contiguous symmetric triangular hills, each base length 10.
- Surface points: `(0,0)→(5,H)→(10,0)→(15,H)→(20,0)→(25,H)→(30,0)`.
- Use paired WedgeParts per hill; no hidden flat bridge across valleys.

### SmallSteps
- Continuous baseline floor top Y=0.
- Five raised rectangular blocks top Y=H, each depth D=4.0.
- Exact default intervals: `[2,6]`, `[7,11]`, `[12,16]`, `[17,21]`, `[22,26]`; gaps are 1.0; entry/exit 2.0.
- These are repeated discrete blocks, **not** an ascending staircase.

### TallSteps
- Continuous baseline floor top Y=0.
- Five raised blocks top Y=H, D=4.5, gap 1.0.
- First block starts X=2.75; subsequent starts add 5.5; final block ends X=29.25; entry/exit=2.75.
- Repeated discrete blocks, not ascending.

### StairUp
- Entry floor X=0..4 at Y=0.
- Six contiguous treads, D=4 each: X=4..8 top H; 8..12 top 2H; 12..16 top 3H; 16..20 top 4H; 20..24 top 5H; 24..28 top 6H.
- Exit X=28..32 top=6H. End.Y=`6H` (default 10.2).
- Vertical riser faces are collidable; no ramp substitution.

### StairDown
- Entry X=0..4 top Y=0.
- Five contiguous descending treads: X=4..8 top `-H`; 8..12 `-2H`; 12..16 `-3H`; 16..20 `-4H`; 20..24 `-5H`.
- Exit X=24..28 top `-5H`. End.Y=`-5H` (default -8.0).

### SingleWallLow / SingleWallHigh
- Continuous baseline floor X=0..Length top0.
- One solid wall, thickness X=2.0, lane width8, bottom Y=0, top Y=H, centered at `X=Length/2`.
- Low default interval X=9..11; High X=11..13.

### GapSmall / GapMedium
- No collision inside the centered gap.
- Approach/landing length each = `(Length-gap)/2`.
- Default GapSmall: floor X=0..10.4 and 13.6..24.
- Default GapMedium: floor X=0..11.2 and 16.8..28.
- Both floor tops Y=0; there is no hidden floor/catch rail in the gap.

### BrokenPlatforms
- Five flat platforms at top Y=0, each default width4.0 separated by four gaps3.5; total exactly `5×4 + 4×3.5 = 34`.
- Intervals: `[0,4]`, `[7.5,11.5]`, `[15,19]`, `[22.5,26.5]`, `[30,34]`.
- No hidden baseline floor between platforms.

### LowTunnelWide
- Continuous floor X=0..28 top0.
- Ceiling collision covers X=6..22; ceiling bottom Y=`clearance`, thickness2, width8.
- Entry/exit open zones each6.

### LowTunnelSteps
- Continuous floor X=0..32 top0.
- Ceiling collision X=6..26, bottom Y=`clearance`, thickness2.
- Three raised internal blocks top Y=H, D=4 at intervals `[8,12]`, `[14,18]`, `[20,24]`.
- Resulting local clearance over blocks = `clearance-H`; validator checks body fit.

### CeilingTeeth
- Continuous floor X=0..30 top0.
- Overhead base roof X=4..26 with bottom Y=`baseClearance=6.2`, thickness2.
- Five downward rectangular teeth width2, centered X=`7,11,15,19,23`; each tooth extends from roof bottom to `toothLowPoint` (default4.4).
- No tooth is decorative; all are gameplay collision.

### VValley
- Entry floor X=0..5 top0.
- Downward planar wedge top from `(5,0)` to `(15,-depth)`.
- Upward planar wedge top from `(15,-depth)` to `(25,0)`.
- Exit floor X=25..30 top0. End.Y=0.

### NarrowPit
- Approach floor X=0..10.5 top0.
- Pit bottom floor X=10.5..15.5 top Y=`-depth`.
- Landing floor X=15.5..26 top0.
- Vertical side walls at X=10.5 and15.5 connect top0 to pit bottom; no hidden slope.

### AlternatingBlocks
- Continuous baseline floor X=0..34 top0.
- Five raised blocks H, W=4 separated by 3-unit baseline gaps.
- Exact intervals: `[1,5]`, `[8,12]`, `[15,19]`, `[22,26]`, `[29,33]`; entry/exit1.

### RampUp
- Entry floor X=0..5 top0.
- One planar ramp run18 from `(5,0)` to `(23, rise)` where `rise=tan(angle)*18`.
- Exit floor X=23..28 at top Y=`rise`; End.Y=`rise`.

### RampDownIntoGap
- Entry flat X=0..1.2 at top0.
- Down ramp run14 from `(1.2,0)` to `(15.2, drop)` where `drop=tan(angle)*14` and angle is negative.
- Empty gap X=15.2..20.0, no hidden collision.
- Landing floor X=20..30 top Y=`drop`; End.Y=`drop`.

### MovingGate
- Continuous floor X=0..26 top0.
- Gate is one gameplay collision panel centered X=13, thickness X=1.5, width Z=8, vertical height6.0.
- `clearance` means gate **bottom** Y above floor. Closed bottom=1.6; open bottom=7.0.
- Default 3.0s cycle at heat phase0: 0.00–0.30 move closed→open using smoothstep; 0.30–1.65 hold open (1.35s); 1.65–1.95 move open→closed; 1.95–3.00 hold closed. Repeat.
- All lanes use identical authoritative phase starting at GO; no per-player phase.

### MovingPlatformGap
- Approach floor X=0..13 top0; empty gap X=13..21; landing floor X=21..34 top0.
- One moving platform width X=5, Z=8, thickness1, centered X=17.
- Platform top Y follows `-0.5 + 1.5*sin(2π*t/period)` studs: min -2.0, max +1.0, period3.6s default.
- Phase t=0 at authoritative GO and is identical on all lanes.
- No hidden floor under the gap.

## 4. Safety geometry defaults
- Track floor width per lane: 8 studs; invisible side catch rails are forbidden in normal race unless explicitly tagged as recovery-only.
- Decorative geometry begins >=1.5 studs outside dynamic-leg collision envelope or has `CanCollide=false`.
- Recovery pad after difficult piece: 8–12 studs flat; default 10.
- Checkpoint is placed after the recovery pad for hard climb/gap pieces, not inside the obstacle.
- Spawn/respawn body center: Y=3.0 above local floor, forward tangent aligned +X, zero roll/pitch.
- Moving obstacle state/phase is resolved once per heat and mirrored identically across all lanes.

## 5. Exact first 20 TrackDefinitions
IDs below are canonical content IDs. Unless noted, `ExpectedRedraws` is inclusive and theme is `TOY_WORKSHOP` for T01–T10 and `NEON_FACTORY` for T11–T20.

### T01_FIRST_ROLL — TRAINING/REFERENCE
`FlatShort(18) → FlatLong(30) → FinishSprint(34)`
- Difficulty 0; ExpectedRedraws 0–1; expected human time 18–28s.
- Purpose: first draw → movement → finish.

### T02_STABLE_BUMPS — TRAINING/REFERENCE
`FlatShort → MicroBumps(H=.8) → FlatLong(30) → FinishSprint(34)`
- Difficulty 0; redraw 0–1; 20–30s.

### T03_REACH_STEPS — TRAINING/REFERENCE
`FlatShort → SmallSteps(H=1.5) → FlatShort → FinishSprint(34)`
- Difficulty 1; redraw 1–2; 22–32s.

### T04_FIRST_WALL — TRAINING/REFERENCE
`FlatShort → SingleWallLow(H=2.6) → FlatLong(26) → FinishSprint(34)`
- Difficulty 1; redraw 1–2; 22–34s.

### T05_GO_SMALL — TRAINING/REFERENCE
`FlatShort → LowTunnelWide(clearance=4.25) → FlatLong(26) → FinishSprint(34)`
- Difficulty 1; redraw 1–2; 22–34s.

### T06_STEPS_TO_SPEED
`FlatShort → SmallSteps(H=1.5) → FlatLong(32) → FinishSprint`
- Difficulty 1; redraw 1–3; 28–38s.

### T07_BIG_TO_SMALL
`FlatShort → SmallSteps(H=1.6) → LowTunnelWide(clearance=4.2) → FlatShort → FinishSprint(34)`
- Difficulty 2; redraw 2–3; 30–42s.

### T08_SPEED_TO_REACH
`FlatLong(30) → GapSmall(gap=3.3) → FlatShort → FinishSprint`
- Difficulty 2; redraw 1–3; 28–40s.

### T09_REACH_TO_SPEED
`FlatShort → GapMedium(gap=5.4) → FlatLong(34) → FinishSprint`
- Difficulty 2; redraw 1–3; 30–42s.

### T10_HOOK_TO_COMPACT
`FlatShort → SingleWallLow(H=2.8) → FlatShort → LowTunnelWide(clearance=4.15) → FinishSprint(34)`
- Difficulty 2; redraw 2–4; 32–44s.

### T11_HILLS_AND_STEPS
`RollingHills(H=1.5) → FlatShort → SmallSteps(H=1.6) → FlatShort → FinishSprint(34)`
- Difficulty 2; redraw 2–4; 32–44s.

### T12_VALLEY_SPRINT
`FlatShort → VValley(depth=3.0) → FlatLong(32) → FinishSprint`
- Difficulty 2; redraw 1–3; 30–42s.

### T13_STEPS_AND_GAP
`SmallSteps(H=1.5) → FlatShort → GapMedium(gap=5.5) → FlatShort → FinishSprint(34)`
- Difficulty 3; redraw 2–4; 32–45s.

### T14_TUNNEL_STEPS
`FlatShort → LowTunnelSteps(clearance=4.45,H=.9) → FlatShort → SingleWallLow(H=2.6) → FinishSprint(34)`
- Difficulty 3; redraw 2–4; 32–45s.

### T15_RHYTHM_BLOCKS
`FlatShort → AlternatingBlocks(H=2.0,gap=3.0) → FlatLong(28) → FinishSprint(34)`
- Difficulty 3; redraw 2–4; 30–44s.

### T16_TALL_TO_LOW
`FlatShort → TallSteps(H=2.4) → FlatShort → LowTunnelWide(clearance=4.1) → FinishSprint(34)`
- Difficulty 3; redraw 2–4; 34–45s.

### T17_RAMP_GAP
`FlatShort → RampUp(angle=18) → FlatShort → GapMedium(gap=5.6) → FinishSprint(34)`
- Difficulty 3; redraw 2–4; 32–45s.

### T18_GATE_TIMING
`FlatLong(28) → MovingGate(period=3.0,open=1.35) → FlatShort → SmallSteps(H=1.5) → FinishSprint(34)`
- Difficulty 3; redraw 1–3; 32–45s.

### T19_MOVING_REACH
`FlatShort → GapSmall(gap=3.2) → FlatShort → MovingPlatformGap(gap=8.0,period=3.6) → FinishSprint(34)`
- Difficulty 4; redraw 2–4; 34–46s; hard timeout still owned by `16`.

### T20_MIXED_MASTERY
`RollingHills(H=1.5) → SingleWallHigh(H=4.1) → FlatShort → LowTunnelWide(clearance=4.1) → RampDownIntoGap(gap=4.8) → FinishSprint(36)`
- Difficulty 4; redraw 3–5; expected 36–48s during first tuning sweep; target tune back toward standard 30–45s if completion quality allows.

## 6. Launch track pools
- `TRAINING_REFERENCE_POOL`: T01–T05. DEV/STAGING/practice/reference only; not the mandatory first public-player sequence.
- `FTUE_MAIN`: **T06_STEPS_TO_SPEED only**. Every safely-loaded new player runs this controlled first heat until first authoritative finish.
- `PUBLIC_EARLY`: T06–T10; exact weights are `61` (T06=0.50, T07–T10=1.00).
- `PUBLIC_STANDARD`: T06–T16; exact weights `61`.
- `PUBLIC_ADVANCED`: T11–T20; exact weights `61`.
- `ALL_PUBLIC_DEBUG`: T06–T20, DEV/STAGING only unless Product Owner enables for testing.

Mastery/access selection rules and unlock thresholds are owned by `61_LAUNCH_ECONOMY_PROGRESSION_TABLE.md`.

## 7. Validator acceptance
A TrackPiece/TrackDefinition cannot ship if:
- default or min/max variant intersects impossible body envelope;
- a required jump/climb is impossible for at least 4 of 5 canonical legal shape suites after physics tuning;
- one canonical universal shape wins all meaningful sections without redraw in G1 adaptation tests;
- recovery/respawn location overlaps moving collision;
- any lane differs from the resolved shared snapshot;
- mobile device matrix in `57` fails with 8 racers on the heaviest track.

## 8. Tuning ownership
Changing a number inside the hard allowed range is level tuning and is logged. Changing the primary read/tag, obstacle topology, number of control verbs, or allowing a new physics advantage is a WHAT/WHY change and requires Decision Log + owner-doc update.
