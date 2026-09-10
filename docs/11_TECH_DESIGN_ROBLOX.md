# 11 — TECHNICAL DESIGN FOR ROBLOX

> PRODUCT LOCK v1.3.4: final target is an 8-player live drawing race; 2-player is an implementation/integration stage only. Product power is never sold.

## 1. Architecture principles
- Server authoritative for race state/rewards/checkpoints.
- Prefer Roblox Server Authority for competitive physics; profile before fallback.
- Client owns input preview/camera/UI responsiveness.
- Server validates stroke payload and creates authoritative leg geometry.
- Config-driven TrackPieces/content.
- Services/controllers split by responsibility, not giant manager.

## 2. DataModel / module ownership
The **exact empty-repository DataModel tree, top-level module names and ownership are defined only in `21_SYSTEM_CLASS_ARCHITECTURE.md`**. This file defines technical direction and must not maintain a second tree.

Required architectural roots are: shared Config/Types/Math/Net, semantic Remotes, server Services + Runtime objects, client Controllers, runtime Workspace containers and tests. In an existing project, reuse an equivalent only after reconnaissance and explicit owner mapping; do not create duplicate families.

## 3. Remotes
Minimal semantic API:
- `SubmitStroke(points, clientSequence)` client→server.
- `StrokeResult({sequence, accepted, shapeVersion?, rejectReasonCode?})` server→owner for UX. Exact payload lives only in `22_NETWORK_DATA_CONTRACTS.md`.
- Race state replicated via authoritative state/remotes as architecture requires.

Never accept:
- `IWon`
- arbitrary reward amount;
- client finish time as truth;
- client world CFrame as race authority.

## 4. Stroke validation
Server checks:
- player is in valid race state;
- rate limit;
- payload type/size;
- finite numeric values;
- points inside normalized bounds;
- minimum useful length;
- simplification/resampling caps;
- sequence/order to reject stale requests.

## 5. Stroke math
Client and server can share deterministic-ish pure modules for:
- dedupe;
- RDP simplify;
- resample;
- center/normalize;
- collider segment construction plan.
Server reruns critical validation.

## 6. Physical leg representation
Recommended prototype:
`Hub BasePart + N simple capsule/box-like Part segments + WeldConstraints + one HingeConstraint Motor`.

Do NOT make every point a motor. Separate:
- visual curve: smoother/more segments;
- physics colliders: fewer segments.

EditableMesh is optional later for visuals; it is not required for the locked core implementation.

## 7. Self-collision handling — canonical
- `RacerBody ↔ RacerLeg = no` for **all** racer bodies/legs, including own assembly.
- `RacerLeg ↔ RacerLeg = no`; `RacerBody ↔ RacerBody = no`.
- `RacerBody/RacerLeg ↔ Track = collide`.
- `Trigger` is overlap/query only; `Decoration` never drives gameplay collision.
- Inner-hub physical segments may additionally be `CanCollide=false` per `73`, but this never changes the global rule above.
Exact implementation matrix is `65`; gameplay edge-case owner is `28`. There is no alternate “own-assembly collision” policy.

## 8. Redraw swap
Build next shape off/disabled → validate → attach at current hubs/phase → enable → remove old. Avoid frame where racer has no legs due to failed build.

## 9. Lane constraint
Gameplay is 2.5D: X forward, Y vertical, Z fixed around lane center. Use constraint/force strategy that preserves physical bounce but prevents drift into neighbor lane.

## 10. Body stabilization
R16.1 upright-body contract is canonical for the current core: `BodyCollider` remains physically free to translate in X/Y while lane Z translation stays mechanically constrained, but all three body rotation axes are locked/corrected toward upright by the stabilization constraint. The stabilizer may apply corrective torque only; it must not provide forward propulsion, vertical lift, or per-frame position teleports. Exact tolerances and numeric tuning are owned by `03/16` and verified by B10/Studio evidence.

## 11. Network model
### Preferred
Roblox Server Authority: server source of truth with client prediction where supported.

### Fallback after profiling only
Client network ownership for own racer assembly + server envelope/checkpoint validation. This increases security surface and must not be default simply for convenience.

## 12. Checkpoint/anti-cheat
- ordered checkpoints;
- lane bounds;
- max reasonable displacement/speed envelope with tolerance for physics spikes;
- suspicious state accumulates, no instant ban from one anomaly;
- invalid finish → no reward + telemetry.

## 13. TrackBuilder
Track definition = ordered list of piece IDs + parameter snapshots. Build once per heat seed, then replicate same definition across lanes.

Each piece pivoted from Start to current End; validator verifies required markers.

## 14. Data
Persistent profile shape is **not duplicated here**. The only canonical serialized profile is `31_SAVE_DATA_MIGRATION_RECOVERY.md`. `PlayerDataService` is the only writer.

Developer Product grants follow `56_PURCHASE_RECEIPT_GRANT_CONTRACT.md`: a `PurchaseId` must be recorded in the same authoritative profile mutation that grants value, so retries cannot duplicate currency/entitlements. Never assume purchase prompt completion alone means item safely granted.

## 15. Performance budget strategy
- bounded collider segments per racer;
- max 8 active racers;
- static track parts anchored;
- decoration non-collidable;
- visual LOD for distant racers;
- pooled/reused visuals where useful;
- rebuild legs only on completed stroke, not every pointer move;
- profile worst-case ugly self-intersecting strokes on low-end mobile.

## 16. Security
Restricted drawing: stroke only creates locomotion geometry inside bounded canvas/size; no free world drawing, text/image upload, arbitrary asset creation or scripting.

## 17. Tests
Pure math unit tests: simplify/resample/bounds.  
Server tests: invalid payload/rate/sequence.  
Studio human tests: feel, collision, camera, redraw, mobile input.  
Regression: old obstacles, finish, respawn, DataStore, purchases after shared-system changes.


## 18. Implementation architecture source
This file defines technical direction. Exact module ownership/API/dependencies live in `21_SYSTEM_CLASS_ARCHITECTURE.md`; remote/data schemas live in `22_NETWORK_DATA_CONTRACTS.md`; project bootstrap lives in `23_PROJECT_SETUP_TOOLCHAIN.md`; QA/regression lives in `24_TESTING_QA_MATRIX.md`. Do not duplicate those contracts here.

## 19. Platform validation snapshot
As of 2026-09, Roblox Server Authority is full release and `Workspace.AuthorityMode` exposes server/automatic authority modes. The project therefore tests `Server` authority in M1 as the preferred competitive physics mode. If current engine behavior causes a blocking issue, use a documented Decision Log and validated fallback rather than silently transferring race truth to clients. See `27_PLATFORM_SNAPSHOT_2026-09.md`.


## Exact implementation roots v1.3.4
Architecture ownership remains `21/22`; exact Studio Instance/property/collision contract is `65`; exact UI child hierarchy is `68`; external environment/Asset/Product IDs are loaded from `70` and never invented/hard-coded.