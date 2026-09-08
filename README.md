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
**A03 — M0 test scene.**

A01 and A02 are ACCEPTED. Do not start A04 or gameplay until A03 passes its acceptance contract.

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

## Accepted bootstrap state
- A01: Git/Rojo baseline, build/serve and Studio sync round-trip accepted.
- A02: `src/shared/Config`, `src/shared/Types`, `Bootstrap.server.lua`, `Bootstrap.client.lua` accepted in Studio Play.
- A03 is next: reproducible M0 lane/test scene using the canonical level/Studio contracts.

A02 deliberately does **not** create empty future `Services`, `Runtime`, `Controllers`, `Math`, or `Net` roots. Those appear only when their owning implementation task needs them.

## Working loop
`ChatGPT/GitHub change -> git pull --ff-only -> Rojo -> Studio playtest -> PASS/FAIL -> next change`

Before pulling remote changes, run `git status` and do not overwrite uncommitted local work.
