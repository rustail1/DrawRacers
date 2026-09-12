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

    attach_block = harness[harness.index("local function attachPlayer"):harness.index("local function attachNextAvailablePlayer")]
    assert "isolateCharacter(player.Character)" in attach_block
    assert "createActiveRacer(player)" in attach_block
    assert attach_block.index("isolateCharacter(player.Character)") < attach_block.index("createActiveRacer(player)")

    spawn_block = harness[harness.index("local function createActiveRacer"):harness.index("local function respawnActiveRacer")]
    assert "RacerRuntime.new" in spawn_block


def test_r08_minimum_useful_leg_extent_is_configured_and_server_enforced() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    service = read("src/server/Services/LegShapeService.lua")
    builder = read("src/shared/Math/LegShapeMath.lua")

    assert "MinUsefulLegExtent = 0.7" in config
    assert "geometryPlan.extent < geometryConfig.MinUsefulLegExtent" in builder
    assert 'return nil, "TOO_SHORT"' in builder
    assert "LegShapeMath.BuildCanonical" in service


def test_r08_antistall_is_bounded_and_only_eligible_on_explicit_flat_recovery_surfaces() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    anti_stall = read("src/server/Runtime/RacerAntiStall.lua")
    scene = read("src/server/M0TestScene.lua")
    telemetry = read("src/server/Runtime/DebugTelemetry.lua")
    panel = read("src/client/Controllers/DebugTuningPanel.lua")

    for token in [
        "ActivationForwardSpeed = 0.35",
        "ActivationDelay = 0.60",
        "MaxAccelerationX = 2.0",
        "MaxAssistDuration = 0.75",
        "DisableForwardSpeed = 1.0",
    ]:
        assert token in config, f"missing anti-stall config default: {token}"

    assert "GroundProbeDistance" not in config
    assert 'require(script.Parent:WaitForChild("RacerAntiStall"))' in runtime
    assert "RacerAntiStall.new" in runtime
    assert "antiStall:Destroy()" in runtime

    for token in [
        'game:GetService("CollectionService")',
        'Instance.new("VectorForce")',
        'HasTag(cursor, "RecoverySurface")',
        'GetAttribute("RequirementTag")',
        'requirementTag == "FAST_ROLL"',
        "GetTouchingParts()",
        "AssemblyMass * config.MaxAccelerationX",
        'SetAttribute("AntiStallActive"',
        "MaxAssistDuration",
        "DisableForwardSpeed",
    ]:
        assert token in anti_stall, f"missing bounded anti-stall token: {token}"

    assert "Workspace:Raycast" not in anti_stall
    assert "AntiStallSurface" not in anti_stall
    assert 'game:GetService("CollectionService")' in scene
    assert 'CollectionService:AddTag(part, "RecoverySurface")' in scene
    assert 'SetAttribute("RequirementTag", "FAST_ROLL")' in scene
    assert "AntiStallSurface" not in scene

    assert 'SetAttribute("DebugAntiStallActive"' in telemetry
    assert '{ key = "antiStallActive", attribute = "DebugAntiStallActive" }' in panel
