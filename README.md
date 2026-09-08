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

## Current bootstrap work
**A04 — deployment/config skeleton is implemented and awaiting local acceptance.**

A01 and A02 are ACCEPTED. A03 local/human acceptance evidence must still be recorded before bootstrap is considered fully closed. Do not start B01 gameplay until both A03 and A04 are accepted.

## Toolchain
Rokit manages the project Rojo version. The repository currently pins Rojo in `rokit.toml`.

From the repository root:

```powershell
rokit install
rojo --version
rojo build -o DrawRacersDev.rbxlx
rojo serve
python -m pytest -q
```

Then connect the Rojo plugin in Roblox Studio to the localhost server shown by `rojo serve`.

## A04 deployment skeleton
Source files:
- `config/deploy/dev.env.lua`
- `config/deploy/staging.env.lua`
- `config/deploy/prod.env.lua`
- `config/deploy/validate.lua`
- `assets/asset_registry.lua`

No Roblox Universe/Place/Pass/Product/Asset ID is guessed. Unprovisioned IDs remain `nil`; the deployment validator rejects unresolved required IDs when resolution is required.

A04 also declares the static Studio roots required by the `65` contract: `ReplicatedStorage/Remotes`, `ReplicatedStorage/Assets`, `ServerStorage/RacerTemplates`, `ServerStorage/TrackPieces`, launch HUD roots, and `Workspace/Runtime/{Tracks,Racers,RacePresentation}`. Filesystem roots `Shared/Math`, `Shared/Net`, `Server/Services`, `Server/Runtime`, `Server/Tests`, and `Client/Controllers` exist without future implementation files.

## Working loop
`ChatGPT/GitHub change -> git pull --ff-only -> Rojo -> Studio playtest -> PASS/FAIL -> next change`

Before pulling remote changes, run `git status` and do not overwrite uncommitted local work.
