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
**B04 — StrokeMath Simplify/Resample/Normalize is implemented and awaiting combined local acceptance with B03.**

Bootstrap A01–A04 and B01–B02 are ACCEPTED. B03/B04 now have behavior specs in Studio; B05 must not start until both local specs and repository contract checks are green.

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
- B02: local DrawCanvas continuous preview/candidate/thumbnail stage accepted by Product Owner progression.

## B03/B04 stroke processing
Current shared files:
- `src/shared/Types/StrokeTypes.lua`
- `src/shared/Config/PhysicsConfig.lua`
- `src/shared/Math/StrokeMath.lua`
- `src/server/Tests/B03StrokeMathSpec.lua`
- `src/server/Tests/B04StrokeMathSpec.lua`

B03 starts from the exact `16` defaults used by its layer: raw sample min movement `0.010`, raw cap `96`, minimum raw points `3`, dedupe distance `0.012`, normalized bounds `[-1,1]`.

B04 adds the next exact defaults: RDP epsilon `0.022`, resample target `12`, max cleaned points `15`, minimum cleaned polyline length `0.18`.

`StrokeMath` remains pure/deterministic. It now supports DrawInputRect-centered normalization (`center=(0,0)`, screen right `+X`, screen up `+Y`), RDP simplification, open-polyline arc-length resampling, and length measurement. It does not recenter or resize shapes by their own bounds.

In Studio, `Bootstrap.server.lua` runs both specs and should print:
- `[DrawRacers][B03] StrokeMath tests PASS`
- `[DrawRacers][B04] StrokeMath simplify/resample/normalize tests PASS`

## Working loop
`ChatGPT/GitHub change -> git pull --ff-only -> Rojo -> Studio playtest -> PASS/FAIL -> next change`

Before pulling remote changes, run `git status` and do not overwrite uncommitted local work.
