# Draw Racers

Roblox production repository for **Draw Racers**.

## Source of truth
The current production specification is in `docs/` (v1.3.4 ZERO-QUESTION PRODUCTION HANDOFF). Do not mix older history packages into this repository.

Before any implementation task, read:
1. `docs/AGENTS.md`
2. `docs/FEATURE_LIST.md`
3. `docs/SESSION.md`
4. `docs/26_HANDOFF_MAP.md`
5. the exact task row in `docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`
6. only the owner specs named by that row

## Current implementation item
**B06 — RacerTemplate + RacerRuntime is implemented and awaiting Studio acceptance.**

B03–B05 StrokeMath code/specs remain wired as regression checks in every Studio Play. B06 introduces only the minimal physical racer foundation required by `16/21/65`; it does not pull leg collider construction, hinges, motors or locomotion forward from B07/B08.

## Toolchain
Rokit manages the project Rojo version. The repository currently pins Rojo in `rokit.toml`.

From the repository root:

```powershell
rokit install
rojo --version
rojo build -o DrawRacersDev.rbxlx
rojo serve
python verify.py
```

`verify.py` runs the current simple Python contract tests without requiring pytest. If pytest is installed, `python -m pytest -q` remains valid too.

Then connect the Rojo plugin in Roblox Studio to the localhost server shown by `rojo serve`.

## Accepted bootstrap/input state
- A01: Git/Rojo baseline, build/serve and Studio sync round-trip accepted.
- A02: canonical minimal shared/server/client bootstrap accepted.
- A03: reproducible Studio M0 lane + debug spawn + representative anchors accepted.
- A04: DEV/STAGING/PROD deployment skeleton, no fake IDs, fail-closed validator and exact static Studio roots accepted.
- B01: mouse/touch pointer abstraction; semantic start/move/end/cancel stream and camera input ownership accepted.
- B02: local DrawCanvas continuous preview/candidate/thumbnail stage accepted by Product Owner progression.

## B03–B05 StrokeMath regression layer
Current shared processing owns normalized clamp/dedupe, DrawInputRect-centered normalization, RDP simplification, open-polyline arc-length resampling and length measurement. Studio specs cover malformed/non-finite input, duplicate-heavy strokes, tiny strokes, self-cross, max raw points and canonical preset shapes.

Expected Studio lines:
- `[DrawRacers][B03] StrokeMath tests PASS`
- `[DrawRacers][B04] StrokeMath simplify/resample/normalize tests PASS`
- `[DrawRacers][B05] canonical/tiny/duplicate/self-cross/max-point/malformed StrokeMath matrix PASS`

## B06 racer foundation
`src/server/Runtime/RacerRuntime.lua` creates/owns the canonical `ServerStorage/RacerTemplates/RacerTemplate` and clones runtime racers under `Workspace.Runtime.Racers`.

B06 locks:
- `BodyCollider` = exact `3x3x3`, invisible physical body, no Humanoid;
- hubs at `(0,-0.75,-1.62)` and `(0,-0.75,+1.62)` relative to body;
- `MotorAttachment` placeholders only; no hinge/motor yet;
- canonical runtime attributes `RaceId/SlotIndex/LaneIndex/IsBot/ShapeVersion/TrackId/Finished`;
- runtime `Legs`, `Presentation` and Studio `Debug` roots;
- clean `Destroy()` removes the spawned racer model.

Studio acceptance is owned by `B06RacerRuntimeSpec` and should print:
- `[DrawRacers][B06] RacerTemplate/RacerRuntime tests PASS`

## Working loop
`ChatGPT/GitHub change -> git pull --ff-only -> Rojo -> Studio playtest -> PASS/FAIL -> next change`

Before pulling remote changes, run `git status` and do not overwrite uncommitted local work.
