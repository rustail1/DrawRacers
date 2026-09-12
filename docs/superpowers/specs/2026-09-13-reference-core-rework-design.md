# Draw Racers Reference Core Rework Design

**Status:** APPROVED FOR AUTOPILOT IMPLEMENTATION

**Baseline at approval:** `591bdf7f65bcb5fa050b3cfe612a895700fb5be3`

## Goal

Bring the current Draw Racers core closer to the proven Draw Climber interaction feel without copying art/assets: draw a shape, see the same canonical shape become the two rotating legs, redraw while moving, and preserve motion continuity.

## Global constraints

- Repository: `rustail1/DrawRacers`, branch `main` only. No branches or PRs.
- Work in small RCP stages with fresh-main checks, targeted tests, scoped diffs, Rojo build and CI.
- Ordinary Studio development remains `G0`; do not restore long automatic evidence suites.
- HUMAN visual/physics/feel gates may be marked `HUMAN_PENDING` during unattended work, but never fabricated as PASS.
- Do not change race rules, economy, progression, level generator, obstacle dimensions, player data, network protocol, anti-stall or motor tuning unless a concrete failure proves it necessary.

## Target architecture

### RCP-01 Stable axle
`AxleRoot` + `HingeConstraint`/motor become long-lived racer state. Redraw keeps the same axle, current rotation angle and motor ownership; only left/right geometry changes.

### RCP-02 Larger/thicker legs
Target physical reach is approximately 2x current (`LegCanvasHalfSpan` about 6.30 and `MaxLegExtentFromHub` about 9.0 if the current values are still 3.15/4.5). Split gameplay collider thickness from presentation thickness. Initial physical-thickness hypothesis: 0.60-0.65; visual thickness: 0.85-0.95. Final values require Studio tuning.

### RCP-03 Canonical draw -> leg parity + larger canvas
Create a pure deterministic shared shape builder used by both client preview and server validation. Pipeline: clamp -> dedupe -> RDP simplify -> resample -> anchor first point -> geometry mapping -> segment plan. The server remains authoritative by recomputing from raw input. Main gameplay canvas uses fixed isotropic mapping and no per-shape auto-fit. Canvas grows to roughly 2x area, not 2x each axis; initial height hypotheses are desktop 0.39-0.40 and touch 0.47-0.48 while preserving 1.75:1 aspect. Canvas centerline must equal physical leg centerline within floating-point epsilon.

### RCP-04 Rapid hub-to-tip reshape
One visible leg pair only. Accepted new geometry reshapes on the stable axle from hub to tip by arc length, typically 0.08-0.12s and no more than about 0.15s initially. Partial segments grow from `a` toward `b`, never symmetrically about midpoint. Growing physical geometry becomes collidable progressively so long legs can contact the ground and naturally lift the cube. No body teleport, anchoring or second old/new pair. Add temporary support only if Studio evidence proves it necessary.

### RCP-05 Camera feel
Keep current side framing, look-ahead, dead zones and 360-degree RMB yaw. Filter high-frequency BodyCollider motion more strongly, especially vertical micro-jitter, while still following real jumps/falls and large elevation changes.

### RCP-06 Rider pose
Presentation-only rider sits clearly astride the cube: pelvis on top, torso slightly forward, knees bent on both sides, readable riding/jockey/cowboy pose. Rider remains non-colliding, massless and physics-neutral. Preserve safe visual accessories where possible.

### RCP-07 Cosmetic foundation
Independent `LegSkinId`, `CubeSkinId`, `RiderSkinId` presentation categories. Cosmetics may change mesh/material/color/texture/visual width/accessories/effects but never collider path, physical thickness, mass, friction, motor, max reach, speed or BodyCollider.

## Autonomous-run policy

During the user's unattended 12-hour window, complete stages sequentially using automated evidence. When a stage needs a human feel/visual gate, record `HUMAN_PENDING` and continue only with later work that is technically independent and does not rely on pretending that gate passed. After planned stages are implemented, spend remaining runs on static/runtime-contract audits, CI failures, regression analysis and fixes for proven defects. Never invent Roblox Studio observations.
