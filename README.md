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
**B02 — DrawingController local stroke preview is implemented and awaiting Studio acceptance.**

Bootstrap A01–A04 and B01 are ACCEPTED. B03 stroke dedupe/clamp must not start until B02 passes one-continuous-preview, exact-hit-rect and cancel-preserves-accepted-shape acceptance.

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

## Accepted state
- A01: Git/Rojo baseline, build/serve and Studio sync round-trip accepted.
- A02: canonical minimal shared/server/client bootstrap accepted.
- A03: reproducible Studio M0 lane + debug spawn + representative anchors accepted.
- A04: DEV/STAGING/PROD deployment skeleton, no fake IDs, fail-closed validator and exact static Studio roots accepted.
- B01: mouse/touch pointer abstraction; semantic start/move/end/cancel stream and camera input ownership accepted.

## B02 local preview
`src/client/Controllers/DrawingController.lua` now owns the `DrawHUD/SafeRoot/DrawCanvas` hierarchy and binds B01 input only to the exact `DrawInputRect`.

During Play:
- drag inside DrawCanvas to see the cyan continuous local stroke;
- release to keep the completed local candidate and its thumbnail;
- begin another stroke, then force a cancel (for example focus loss) to verify the previous candidate is restored;
- this task is client-preview only: no RemoteEvent, server ShapeSpec, physical leg, or world geometry exists yet.

## Working loop
`ChatGPT/GitHub change -> git pull --ff-only -> Rojo -> Studio playtest -> PASS/FAIL -> next change`

Before pulling remote changes, run `git status` and do not overwrite uncommitted local work.