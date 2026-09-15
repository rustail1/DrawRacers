# ARCHITECTURE MAP — CURRENT CORE V3 NAVIGATION CACHE

Status: **CURRENT 2026-09-15**. Navigation only; current code + Source of Truth win if this map becomes stale.

## Active drawing -> locomotion path

```text
DrawingController
  -> SubmitStroke / StrokeRemoteTransport
  -> LegShapeService
  -> CanonicalLegShape + GeometryMath
  -> ShapeSpec
  -> RacerRuntime
       -> CoreV3/FallRecovery (out-of-bounds only)
       -> CoreV3/LegCoreController
       -> SharedAxle
       -> Left LegGeometry (-Z)
       -> Right LegGeometry (+Z, 180°)
       -> LegClearanceController
```

## Current owners
| Responsibility | Current file(s) | Notes |
|---|---|---|
| client draw/prediction | `src/client/Controllers/DrawingController.lua` | input/preview/result presentation |
| stroke transport | `src/shared/Net/StrokeRemoteTransport.lua` | transport only |
| server shape authority | `src/server/Services/LegShapeService.lua` | validation, pending safety, mechanical result |
| canonical shape | `src/shared/Math/CanonicalLegShape.lua`, `GeometryMath.lua` | ShapeSpec/segmentPlan |
| racer lifecycle | `src/server/Runtime/RacerRuntime.lua` | body, ShapeVersion, Core V3 adapter |
| rebuild state machine | `src/server/Runtime/CoreV3/LegCoreController.lua` | EMPTY/PREVIEW/WAIT_CLEAR/ACTIVE |
| one axle/hinge | `src/server/Runtime/CoreV3/SharedAxle.lua` | exactly one HingeConstraint |
| side geometry | `src/server/Runtime/CoreV3/LegGeometry.lua` | preview + physical colliders |
| clearance | `src/server/Runtime/CoreV3/LegClearanceController.lua` | whole-pair +Y clearance only |
| out-of-bounds recovery | `src/server/Runtime/CoreV3/FallRecovery.lua` | Y threshold, same racer/pair, saved spawn/lane |
| Core V3 tuning | `src/server/Runtime/CoreV3/LegCoreConfig.lua` | mount/material/motor/rebuild numbers |
| automated Core V3 suite | `src/server/Tests/C01CoreV3SharedAxleSpec.lua` ... `C08CoreV3FallRecoverySpec.lua` | C01–C08 |
| human flat harness | `src/server/Tests/CoreV3FlatHarness.lua` | ROUND/reference shapes/20 redraws |

## Approved next owner — not yet accepted
Dedicated Core V3 2.5D lane/upright owner:
- Z translation lane-plane lock;
- upright torque/orientation stabilization;
- X/Y translation untouched;
- no +X/vertical helper.

Preferred primitive boundary: PlaneConstraint + bounded AlignOrientation/equivalent.

## Legacy files still present but NOT active Core V3 owners
The following may remain in the filesystem until post-Flat cleanup, but must not be reconnected to Core V3:
- `LegPairAssembly.lua`
- `LegDriveAssembly.lua`
- `LegAssembly.lua`
- `LegCollisionSafety.lua`
- `RedrawSpawnSafety.lua`
- `RacerAntiStall.lua`
- old `RacerStabilizer.lua` path

## Fast bug routing
| Symptom | First files |
|---|---|
| drawing accepted but no legs | `LegShapeService`, `RacerRuntime`, `LegCoreController` |
| one side wrong / wrong phase | `SharedAxle`, `LegGeometry`, `LegCoreConfig` |
| motor commanded but no motion | `SharedAxle`, `LegCoreController`, `LegGeometry`, `CoreV3FlatHarness` |
| redraw stuck/failed | `LegCoreController`, `LegClearanceController`, `LegShapeService` |
| sideways lane fall/tumble | approved next Core V3 lane/upright owner + `RacerRuntime` body setup |
| false acceptance | `CoreV3DriveAcceptanceGate`, `CoreV3FlatHarness`, C07 |

Do not start from legacy CR2/CR3/R17 modules for current locomotion bugs.
