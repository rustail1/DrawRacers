from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r08_touch_layout_is_selected_before_first_stroke_and_never_reflows_mid_stroke() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    assert 'game:GetService("UserInputService")' in drawing
    assert "TouchEnabled" in drawing
    assert "MouseEnabled" in drawing
    assert "GetLastInputType" in drawing
    assert "_pendingLayoutFamily" in drawing
    assert "_applyPendingLayout" in drawing

    start_block = drawing[drawing.index('if event.phase == "start" then'):drawing.index('elseif event.phase == "move" then')]
    assert "_applyLayout(event.family)" not in start_block


def test_r08_g0_isolates_roblox_character_from_racer_physics() -> None:
    harness = read("src/server/Tests/M0HumanHarness.lua")

    for token in [
        "isolateCharacter",
        "restoreCharacter",
        "CharacterAdded",
        "HumanoidRootPart",
        "CanCollide = false",
        "CanTouch = false",
        "CanQuery = false",
        "Anchored = true",
    ]:
        assert token in harness, f"missing G0 character isolation token: {token}"


def test_r08_minimum_useful_leg_extent_is_configured_and_server_enforced() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    service = read("src/server/Services/LegShapeService.lua")

    assert "MinUsefulLegExtent = 0.7" in config
    assert "geometryPlan.extent < PhysicsConfig.LegGeometry.MinUsefulLegExtent" in service
    assert 'reject("TOO_SHORT")' in service


def test_r08_antistall_is_bounded_and_only_eligible_on_explicit_flat_recovery_surfaces() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    anti_stall = read("src/server/Runtime/RacerAntiStall.lua")
    scene = read("src/server/M0TestScene.lua")

    for token in [
        "ActivationForwardSpeed = 0.35",
        "ActivationDelay = 0.60",
        "MaxAccelerationX = 2.0",
        "MaxAssistDuration = 0.75",
        "DisableForwardSpeed = 1.0",
    ]:
        assert token in config, f"missing anti-stall config default: {token}"

    assert 'require(script.Parent:WaitForChild("RacerAntiStall"))' in runtime
    assert "RacerAntiStall.new" in runtime
    assert "antiStall:Destroy()" in runtime

    for token in [
        'Instance.new("VectorForce")',
        'GetAttribute("AntiStallSurface") == true',
        "AssemblyMass * config.MaxAccelerationX",
        'SetAttribute("AntiStallActive"',
        "MaxAssistDuration",
        "DisableForwardSpeed",
    ]:
        assert token in anti_stall, f"missing bounded anti-stall token: {token}"

    assert 'SetAttribute("AntiStallSurface", antiStallSurface == true)' in scene
    assert 'makeTrackPart("EntryFloor", 0, config.Pieces[1].StartX, config.Lane.TopY, config.Lane.Thickness, obstacleLab, true)' in scene
    assert 'makeTrackPart("FlatFloor", piece.StartX, piece.StartX + piece.Length, config.Lane.TopY, config.Lane.Thickness, parent, true)' in scene
    assert "RecoveryAfter" in scene and "true" in scene
