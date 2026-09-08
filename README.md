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

## Current task
**A01 — Git repo + Rojo baseline.**

A02 or gameplay work must not start until A01 passes local Rojo build/serve and Roblox Studio sync round-trip.

## Toolchain
Rokit manages the project Rojo version. The repository currently pins Rojo in `rokit.toml`.

From the repository root:

```powershell
rokit install
rojo --version
rojo build -o DrawRacersDev.rbxlx
rojo serve
```

Then connect the Rojo plugin in Roblox Studio to the localhost server shown by `rojo serve`.

## A01 Rojo mapping
- `src/shared` -> `ReplicatedStorage/Shared`
- `src/server` -> `ServerScriptService`
- `src/client` -> `StarterPlayer/StarterPlayerScripts`

Detailed DataModel roots and real bootstrap modules are introduced by later tasks according to the production docs. Do not create future services/controllers early.

## Working loop
`ChatGPT/GitHub change -> git pull --ff-only -> Rojo -> Studio playtest -> PASS/FAIL -> next change`

Before pulling remote changes, run `git status` and do not overwrite uncommitted local work.
