from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r14_5_transport_exception_path_is_directly_testable_and_bind_reuses_it() -> None:
    transport = read("src/server/Services/StrokeRemoteTransport.lua")
    studio_spec = read("src/server/Tests/B12StrokeRemoteSpec.lua")

    assert "function StrokeRemoteTransport.ProcessSafely" in transport
    assert "StrokeRemoteTransport.ProcessSafely(processor, player, payload)" in transport
    assert "StrokeRemoteTransport.ProcessSafely" in studio_spec
    assert 'rejectReasonCode == "SERVER_ERROR"' in studio_spec
    assert "B12 injected processor failure" in studio_spec


def test_r14_6_recovery_preserves_authoritative_shape_and_runtime_identity() -> None:
    harness = read("src/server/Tests/M0HumanHarness.lua")
    start = harness.index("local function respawnActiveRacer")
    end = harness.index("local function destroyActiveRacer", start)
    body = harness[start:end]

    assert "activeRacer:Destroy()" not in body
    assert "createActiveRacer(player)" not in body
    assert "GetCurrentShapeSpec" in body
    assert "GetShapeVersion" in body
    assert "model:PivotTo" in body
    assert "AssemblyLinearVelocity = Vector3.zero" in body
    assert "AssemblyAngularVelocity = Vector3.zero" in body
    assert "shapeSpecAfter" in body
    assert "shapeVersionAfter" in body
