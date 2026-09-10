from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_5_tuning_has_single_material_owners_and_flat_measurement_harness() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    scene = read("src/shared/Config/M0SceneConfig.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    harness_config = read("src/shared/Config/StudioHarnessConfig.lua")
    bootstrap = read("src/server/Bootstrap.server.lua")
    harness = read("src/server/Tests/R16StageBHarness.lua")
    shapes = read("src/server/Tests/R16ReferenceShapes.lua")
    session = read("docs/SESSION.md")

    assert "PhysicalMaterials = {" in config
    assert "LegSegment = {" in config
    assert "Body = {" in config
    assert "PhysicsConfig.PhysicalMaterials.LegSegment" in leg
    assert "PhysicsConfig.PhysicalMaterials.Body" in runtime

    for token in [
        "FlatIgnoreSeconds = 2.0",
        "FlatMeasureSeconds = 3.0",
        "FlatSpeedMin = 4.0",
        "FlatSpeedMax = 7.0",
    ]:
        assert token in scene

    assert 'R16B = "R16B"' in harness_config
    assert 'harnessMode == "R16B"' in bootstrap
    assert 'WaitForChild("R16StageBHarness")' in bootstrap

    assert "ROUND_01" in shapes
    assert "waitForTrackContact" in harness
    assert "FlatIgnoreSeconds" in harness
    assert "FlatMeasureSeconds" in harness
    assert "FlatSpeedMin" in harness
    assert "FlatSpeedMax" in harness
    assert 'GetAttribute("AntiStallActive")' in harness
    assert "R16.5" in harness

    assert "Stage B implementation authorized by Product Owner" in session
    assert "Studio Gate A remains HUMAN STUDIO PENDING" in session
