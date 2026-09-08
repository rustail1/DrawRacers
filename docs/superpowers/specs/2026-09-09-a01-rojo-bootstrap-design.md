# A01 Rojo Bootstrap Design

## Goal
Create the smallest reproducible Git + Rojo baseline required by task A01 in `66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`, without implementing A02+ architecture or gameplay.

## Approved approach
Work directly on `main` with no branch/PR. Keep the existing `docs/` production handoff and existing Rokit pin `rojo-rbx/rojo@7.7.0`. Add only repository hygiene, a minimal Rojo project mapping, tracked source roots, and root-level handoff instructions.

## Rojo mapping
`default.project.json` maps only the source roots needed for the baseline:

- `src/shared` -> `ReplicatedStorage/Shared`
- `src/server` -> `ServerScriptService`
- `src/client` -> `StarterPlayer/StarterPlayerScripts`

A01 does not create future Services, Controllers, Remotes, UI, runtime objects, gameplay code, or deployment IDs. Those belong to later tasks.

## Files
Create:
- `.gitignore`
- `default.project.json`
- `README.md`
- `AGENTS.md`
- `src/shared/.gitkeep`
- `src/server/.gitkeep`
- `src/client/.gitkeep`
- `assets/.gitkeep`
- `tests/.gitkeep`

Keep unchanged:
- `rokit.toml`
- `docs/**`

## Verification
A01 is not accepted from GitHub edits alone. After pulling the commit on Windows, the human runs:

```powershell
rokit install
rojo --version
rojo build -o DrawRacersDev.rbxlx
rojo serve
```

Then open/connect Roblox Studio through the Rojo plugin and verify a sync round-trip with no Rojo/Studio errors. Human acceptance closes A01; until then A01 remains pending verification.

## Constraints
- No fake Roblox IDs.
- No gameplay code.
- No empty future service/controller modules.
- No duplicate Studio-managed script hierarchy.
- `docs/` v1.3.4 remains the product/implementation source of truth.
