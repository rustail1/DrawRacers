# B12 SubmitStroke / StrokeResult Design

Status: APPROVED DESIGN — user approved in chat on 2026-09-09.

## Goal
Connect the existing local drawing flow to the authoritative B11 `LegShapeService` using the exact minimal semantic remote contract from `21/22`, without introducing generic RPC, client-authored geometry, or later race-service architecture.

## Scope
B12 adds only the transport boundary for stroke submission/result. It does not implement B13 atomic redraw semantics, B14 abuse stress soak, D05 `RacerService`, race lifecycle, rewards, checkpoints, or persistence.

## DataModel and names
Under `ReplicatedStorage/Remotes` create exactly:
- `SubmitStroke` (`RemoteEvent`)
- `StrokeResult` (`RemoteEvent`)

Add `ReplicatedStorage/Shared/Net/RemoteNames.lua` as the canonical semantic name registry. No generic `RPC`, `Invoke`, `SetProperty`, `SpawnThing`, or equivalent remote is allowed.

## Client → Server payload
`SubmitStroke` payload:
```lua
{
    sequence = integer,
    points = {
        { x = number, y = number },
        ...
    },
}
```

The client may only send normalized stroke intent. It may not send Roblox `Instance`s, `CFrame`, world positions, segment plans, physical properties, shape version, reward state, or authoritative result data.

## Server validation order
The transport handler validates before calling B11:
1. player has a resolved racer runtime through injected `resolveRacer(player)`;
2. payload is a table;
3. `sequence` is a positive integer;
4. sequence is newer than the last accepted/pending sequence for that player;
5. payload structure is bounded and points are a dense array;
6. every point is exactly `{x:number,y:number}` with finite numeric coordinates;
7. point count does not exceed `PhysicsConfig.StrokeProcessing.MaxRawPoints = 96`;
8. estimated payload size does not exceed `MaxStrokePayloadBytes = 4096`;
9. submit cooldown obeys `StrokeSubmitCooldown = 0.20s`;
10. only then convert to `Vector2` and call `LegShapeService.ValidateAndBuild`.

B11 remains responsible for authoritative clamp/dedupe/RDP/resample/min-length/radial/segment-plan validation and geometry build.

## Sequence semantics
Transport state is server-only and per player.

Track:
- `lastAcceptedSequence` — highest sequence that reached an accepted B11 result;
- `pendingSequence` — sequence currently being processed, if any;
- `lastRequestAt` — server clock used for cooldown.

Rules:
- `sequence <= max(lastAcceptedSequence, pendingSequence)` rejects as `STALE_SEQUENCE`;
- a pending sequence is reserved before potentially expensive validation so duplicate/reentrant delivery fails closed;
- rejected malformed/rate-limited requests do not advance `lastAcceptedSequence`;
- after a completed non-accepted B11 validation, the pending reservation is cleared so a newer sequence can proceed;
- after accepted B11 validation, `lastAcceptedSequence` becomes that sequence.

## Rate limiting
Use server monotonic time (`os.clock()` or equivalent injected clock for tests). Default cooldown comes from `16`: `0.20s`.

A request inside the cooldown returns `StrokeResult` with:
```lua
{
    sequence = sequence,
    accepted = false,
    rejectReasonCode = "RATE_LIMITED",
}
```
when the sequence itself is valid enough to echo safely.

## Payload-size guard
B12 must hard-cap transport work before shape construction. Payload size is estimated deterministically from the semantic payload fields; the implementation must fail closed at `> 4096` bytes without serializing arbitrary Instances or traversing unbounded tables. The point-count cap of 96 is applied before any expensive work.

## Server → Client result
`StrokeResult` is a `RemoteEvent` with one table payload.

Accepted:
```lua
{
    sequence = sequence,
    accepted = true,
    shapeVersion = integer,
}
```

Rejected, when sequence is safely available:
```lua
{
    sequence = sequence,
    accepted = false,
    rejectReasonCode = string,
}
```

If payload/sequence is too malformed to safely identify a valid sequence, the server fails closed and does not fabricate an echo sequence.

## Dependency injection / B12 boundary
Do not implement D05 `RacerService` early. Create a focused server transport module/service that accepts `resolveRacer(player)` and optional clock dependencies. Production bootstrap may leave player submission binding disabled until a real resolver is available, while Studio B12 tests inject a deterministic resolver.

This preserves the `21` owner boundary: B12 owns networking; B11 owns shape validation/build; D05 later owns Player → RacerRuntime mapping.

## Client behavior
`DrawingController` keeps local live preview behavior from B02.

On pointer release:
- normalize the local DrawInputRect stroke into `[-1,+1]` payload coordinates using the canonical center/Y-direction semantics;
- increment a local monotonically increasing `sequence`;
- send `SubmitStroke`;
- do not mark that submitted stroke as the authoritative accepted shape yet.

On `StrokeResult`:
- ignore results older than the latest submitted sequence;
- if accepted, promote the matching submitted stroke to `acceptedPoints`/thumbnail;
- if rejected, preserve the prior accepted preview and show a bounded validation message;
- a rejected/stale/malformed result must never clear the existing accepted shape.

B13 will later change the physical rebuild path to fully atomic old/new leg swapping. B12 only establishes the exact request/result boundary.

## Security invariants
- Client creates no world geometry.
- Client cannot choose `ShapeVersion`.
- Client cannot target another racer.
- No generic remote surface.
- Server caps point count and payload work before B11 build.
- Invalid/stale/rate-limited submit leaves current accepted shape intact.

## Acceptance
B12 is accepted only when tests demonstrate:
- exact two remote names/classes;
- valid submit reaches B11 and returns accepted `shapeVersion`;
- malformed payload, malformed point, NaN/Inf, >96 points, >4096-byte payload, stale sequence, and cooldown spam fail closed;
- absent racer fails closed;
- no generic RPC exists;
- rejected paths do not change accepted shape/version;
- DrawingController sends exact semantic payload and only promotes preview after matching accepted `StrokeResult`;
- Studio prints `[DrawRacers][B12] SubmitStroke/StrokeResult tests PASS` with no DrawRacers red error.
