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
    ]:
        assert token in config, f"missing RCP-04 config token: {token}"


def test_rcp04_leg_assembly_can_apply_partial_geometry_without_midpoint_growth() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert 'WaitForChild("LegReshapeMath")' in leg
    assert "function LegAssembly:SetReshapeProgress" in leg
    assert "LegReshapeMath.Evaluate" in leg
    assert "partialEndpoint" in leg
    assert "setDynamicFrame(self.root, segment, self.partialColliderWeld, a, endpoint)" in leg
    assert "segment.Size = Vector3.new(" in leg
    assert "segment.CanCollide = visibleLength" in leg
    assert 'partialCollider.Name = "ReshapeTipCollider"' in leg


def test_rcp04_pair_uses_one_visible_pair_and_same_progress_for_both_sides() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert "function LegPairAssembly:BeginGeometryReshape" in pair
    assert "function LegPairAssembly:SetReshapeProgress" in pair
    assert "self.leftLeg:SetReshapeProgress(progress)" in pair
    assert "self.rightLeg:SetReshapeProgress(progress)" in pair
    assert "stagedLeft:SetReshapeProgress(0)" in pair
    assert "stagedRight:SetReshapeProgress(0)" in pair
    assert "oldLeft:Destroy()" in pair and "oldRight:Destroy()" in pair
    assert "VectorForce" not in pair


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
