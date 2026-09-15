# DrawRacers — current local development entrypoint

Status: **CORE V3 / LOCAL FILE WORKFLOW / HUMAN PHYSICS PENDING — 2026-09-15**

DrawRacers is currently in the M0 Core V3 Flat Physics phase. The current mechanical authority is:

1. `docs/CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`
2. `docs/SESSION.md`
3. `docs/FEATURE_LIST.md`
4. `docs/ARCHITECTURE_MAP.md`
5. only the owner docs relevant to the bounded task

Do **not** use deleted CR2/CR3/R15–R17 mechanical implementation history as current locomotion guidance.

## Current Core V3 contract

- one authoritative drawing -> one `ShapeSpec`;
- two depth-separated side legs from the same XY shape;
- LEFT on `-Z`, RIGHT on `+Z`;
- RIGHT structurally opposed by `180°`;
- exactly one shared axle and one `HingeConstraint`;
- `HingeConstraint.Enabled` stays `true`;
- motor OFF = `ActuatorType.None`, motor ON = `ActuatorType.Motor`;
- normal +X movement must come only from `motor -> axle -> legs -> Track contact/friction -> BodyCollider`;
- redraw is transactional: `PREVIEW -> WAIT_CLEAR -> ACTIVE`, fail-closed;
- accepted shape/version commits only after real `ACTIVE`;
- current automated Studio suite is `C01–C07`;
- obstacles are blocked until the human Flat Gate passes.

Forbidden as normal Core V3 locomotion:
- constant +X `VectorForce`;
- forward `LinearVelocity` / `BodyVelocity`;
- AntiStall propulsion;
- obstacle-recovery propulsion;
- `PivotTo` / Body CFrame / Position locomotion;
- a second side motor/hinge.

## Approved next architecture repair

DrawRacers is a **2.5D** side-view physics game:

```text
X translation = FREE
Y translation = FREE
Z translation = LOCKED TO LANE

Body orientation = upright stabilized
Shared axle rotation = free
```

Implement this with a dedicated Core V3 lane/orientation owner. Preferred boundary:
- `PlaneConstraint` for Z-plane confinement;
- bounded torque-only `AlignOrientation` (or equivalent) for upright stabilization;
- no position mover that supplies normal +X or +Y locomotion.

See `docs/DECISION_LOG_CORE_V3_2P5D_LANE_2026-09-15.md`.

## Current workflow

Development currently runs **without Git/GitHub**.

The exact local folder/archive supplied for a session is the baseline. Work in a separate copy/overlay where practical, then validate through Rojo/Roblox Studio. Do not branch, commit, push, pull, or open PRs unless the Product Owner explicitly re-enables Git.

Useful local commands when available:

```powershell
rojo build -o DrawRacersDev.rbxlx
rojo serve
```

The repository's legacy Python `verify.py` suite still contains superseded CR2/R17 implementation-detail contracts and is **not** the authority for the Core V3 Flat Gate. Current Core V3 automated authority is Studio `C01–C07`. Static/build checks do not prove Roblox solver behavior.

## Current acceptance order

1. `COREV3_TEST` -> C01–C07.
2. `COREV3` -> one ROUND from rest for at least 5 seconds.
3. Confirm Z lane lock + upright behavior.
4. Confirm real leg/Track contact and relative axle/body rotation.
5. Confirm natural +X movement with no horizontal helper.
6. Then test `SMALL_ROUND`, `LONG`, `HOOK`, `ASYMMETRIC`.
7. Then 20 redraws while moving.
8. Only after human Flat PASS: resume obstacle work and post-Flat legacy cleanup.

Until Roblox Studio evidence exists, report:

`AUTOMATED PASS / HUMAN PHYSICS PENDING`

## Documentation index

Start at `docs/README.md`.

Current documentation audit: `docs/79_CURRENT_CORE_V3_DOCUMENTATION_AUDIT_2026-09-15.md`.
