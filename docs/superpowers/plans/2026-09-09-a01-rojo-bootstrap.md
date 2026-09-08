# A01 Rojo Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a clean Git + Rojo baseline that builds, serves, and syncs with Roblox Studio without implementing later architecture/gameplay tasks.

**Architecture:** Keep the repository minimal. Rojo maps three filesystem roots into the canonical Roblox DataModel entry points, while all detailed architecture remains owned by the v1.3.4 docs and later A02+ tasks.

**Tech Stack:** Git, Rokit, Rojo 7.7.0, Roblox Studio, Luau filesystem layout.

**Spec:** `docs/superpowers/specs/2026-09-09-a01-rojo-bootstrap-design.md`

## Global Constraints
- Work on `main`; no branch/PR.
- Existing `rokit.toml` pin `rojo-rbx/rojo@7.7.0` remains unchanged.
- Do not create gameplay code, future services/controllers, Remotes, UI, or fake Roblox IDs.
- `docs/` v1.3.4 remains source of truth.
- A01 is accepted only after local `rojo build`, `rojo serve`, and Studio sync round-trip pass.

---

### Task 1: Repository hygiene and Rojo mapping

**Files:**
- Create: `.gitignore`
- Create: `default.project.json`
- Create: `src/shared/.gitkeep`
- Create: `src/server/.gitkeep`
- Create: `src/client/.gitkeep`
- Create: `assets/.gitkeep`
- Create: `tests/.gitkeep`

**Interfaces:**
- Consumes: existing `rokit.toml` and v1.3.4 docs.
- Produces: Rojo filesystem roots mapped to `ReplicatedStorage/Shared`, `ServerScriptService`, and `StarterPlayer/StarterPlayerScripts`.

- [ ] **Step 1: Create `.gitignore`**

Use:

```gitignore
# Rojo build outputs
*.rbxl
*.rbxlx
*.rbxm
*.rbxmx

# Rokit local state / generic local env
.env
.env.*

# Editors / OS
.vscode/
.idea/
.DS_Store
Thumbs.db

# Temporary / logs
*.log
*.tmp
```

- [ ] **Step 2: Create `default.project.json`**

Use:

```json
{
  "name": "DrawRacers",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Shared": {
        "$path": "src/shared"
      }
    },
    "ServerScriptService": {
      "$path": "src/server"
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "$path": "src/client"
      }
    }
  }
}
```

- [ ] **Step 3: Track empty project roots**

Create empty `.gitkeep` files at the five paths listed above. Rojo ignores these non-Roblox source files; they exist only so Git retains the directories before A02 creates real modules.

- [ ] **Step 4: Static repository verification**

Verify all expected root files/paths exist and `rokit.toml` still contains `rojo-rbx/rojo@7.7.0`.

Expected: no gameplay `.lua/.luau` files added.

---

### Task 2: Root handoff files

**Files:**
- Create: `README.md`
- Create: `AGENTS.md`

**Interfaces:**
- Consumes: `docs/23_PROJECT_SETUP_TOOLCHAIN.md`, `docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`, `docs/AGENTS.md`.
- Produces: a root entry point for humans/AI that routes all work to v1.3.4 docs without duplicating product rules.

- [ ] **Step 1: Create root `README.md`**

It must state: current source of truth is `docs/`, current task is A01, install with `rokit install`, build with `rojo build -o DrawRacersDev.rbxlx`, serve with `rojo serve`, and no A02/gameplay work starts before A01 Studio acceptance.

- [ ] **Step 2: Create root `AGENTS.md`**

It must instruct AI workers to read `docs/AGENTS.md`, `docs/FEATURE_LIST.md`, `docs/SESSION.md`, and exact task row in `docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`; work only on current task; avoid `_HISTORY`; never invent Roblox IDs; never create duplicate top-level architecture.

- [ ] **Step 3: Static verification**

Confirm root instructions use `docs/...` paths (not broken relative paths) and do not duplicate/override v1.3.4 owner specs.

---

### Task 3: Human A01 acceptance

**Files:**
- No repository changes until human result is known.

**Interfaces:**
- Consumes: committed A01 baseline.
- Produces: PASS/FAIL evidence for A01.

- [ ] **Step 1: Pull on Windows**

```powershell
cd C:\Dev\DrawRacers
git status
git pull --ff-only
rokit install
```

Expected: clean pull, no merge conflict.

- [ ] **Step 2: Verify Rojo build**

```powershell
rojo --version
rojo build -o DrawRacersDev.rbxlx
```

Expected: Rojo 7.7.0 available and `DrawRacersDev.rbxlx` builds without an error.

- [ ] **Step 3: Verify serve + Studio round-trip**

```powershell
rojo serve
```

Open Roblox Studio, connect the Rojo plugin to the shown localhost server, verify `ReplicatedStorage/Shared`, `ServerScriptService`, and `StarterPlayer/StarterPlayerScripts` are synchronized and no Rojo errors appear.

- [ ] **Step 4: Report acceptance**

Human reports either `A01 PASS` or the exact terminal/Studio error. Do not start A02 on failure.
