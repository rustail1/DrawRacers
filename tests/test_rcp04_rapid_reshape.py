from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_rcp04_arc_length_reshape_math_is_pure_and_hub_to_tip() -> None:
    path = ROOT / "src/shared/Math/LegReshapeMath.lua"
    assert path.is_file(), "RCP-04 requires pure LegReshapeMath"
    text = path.read_text(encoding="utf-8")
    for token in [
        "function LegReshapeMath.Evaluate",
        "math.clamp(progress, 0, 1)",
        "totalLength",
        "builtLength",
        "partialEndpoint",
        "completeSegments",
    ]:
        assert token in text, f"missing RCP-04 math token: {token}"
    for forbidden in ["Workspace", "RunService", "Instance.new", "task.wait", "Heartbeat"]:
        assert forbidden not in text, f"reshape math must remain pure: {forbidden}"


def test_rcp04_config_keeps_arcade_duration_bounded() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    for token in [
        "LegReshape = {",
        "TypicalDuration = 0.10",
        "MinimumDuration = 0.08",
        "MaximumDuration = 0.15",
        "GravityCompensationFraction = 1.0",
    ]:
        assert token in config, f"missing RCP-04 config token: {token}"


def test_rcp04_leg_assembly_materializes_only_current_prefix() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert 'WaitForChild("LegReshapeMath")' in leg
    assert "function LegAssembly:ReplaceGeometry" in leg
    assert "function LegAssembly:SetReshapeProgress" in leg
    assert "function LegAssembly:CompleteReshape" in leg
    assert "LegReshapeMath.Evaluate" in leg
    assert "materializeCompleteSegment" in leg
    assert "partialEndpoint" in leg
    assert "updatePartialTip" in leg
    assert 'collider.Name = "ReshapeTipCollider"' in leg
    assert "for index = self.materializedCompleteSegments + 1, state.completeSegments do" in leg


def test_rcp04_pair_reuses_side_owners_and_only_uses_bounded_vertical_support() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert "function LegPairAssembly:BeginGeometryReshape" in pair
    assert "function LegPairAssembly:SetReshapeProgress" in pair
    assert "self.leftLeg:ReplaceGeometry(shapeSpec)" in pair
    assert "self.rightLeg:ReplaceGeometry(shapeSpec)" in pair
    assert "self.leftLeg:SetReshapeProgress" in pair
    assert "self.rightLeg:SetReshapeProgress" in pair
    assert "buildStagedSides" not in pair
    assert "oldLeft:Destroy()" not in pair and "oldRight:Destroy()" not in pair
    assert 'Instance.new("VectorForce")' in pair
    assert "Vector3.new(0," in pair
    assert "ApplyAtCenterOfMass = true" in pair
    assert "BodyCollider.Anchored" not in pair


def test_rcp04_runtime_drives_short_reshape_without_resetting_motor() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    assert "RunService.Heartbeat:Connect" in runtime
    assert "_reshapeConnection" in runtime
    assert "BeginGeometryReshape" in runtime
    assert "SetReshapeProgress" in runtime
    assert "local reshape = PhysicsConfig.LegReshape" in runtime
    assert "reshape.TypicalDuration" in runtime
    assert "self.legPair:SetEnabled(false)" not in runtime
    assert "BodyCollider.Anchored" not in runtime
