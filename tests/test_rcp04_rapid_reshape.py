from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_rcp04_reshape_math_remains_pure_for_visual_staging() -> None:
    reshape = read("src/shared/Math/LegReshapeMath.lua")
    assert "function LegReshapeMath.Evaluate" in reshape
    for forbidden in ["Instance.new", "Workspace", "RunService", "RemoteEvent"]:
        assert forbidden not in reshape


def test_rcp04_config_keeps_arcade_duration_bounded_without_gravity_compensation() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    for token in ["TypicalDuration = 0.10", "MinimumDuration = 0.08", "MaximumDuration = 0.15"]:
        assert token in config
    assert "GravityCompensationFraction" not in config


def test_rcp04_leg_assembly_stages_only_visual_geometry_until_commit() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "function LegAssembly:StageGeometry" in leg
    assert "function LegAssembly:SetStageProgress" in leg
    assert "function LegAssembly:CommitStagedGeometry" in leg
    stage = leg.split("function LegAssembly:SetStageProgress", 1)[1].split("function LegAssembly:CommitStagedGeometry", 1)[0]
    assert 'makeFolder("StageVisual"' in stage
    assert "self.segmentsFolder:Destroy()" not in stage
    assert "ReshapeTipCollider" not in leg


def test_rcp04_pair_reuses_drive_owners_and_uses_collision_safety_not_vertical_support() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    stage = pair.split("function LegPairAssembly:StageRedraw", 1)[1].split("function LegPairAssembly:SetStageProgress", 1)[0]
    assert "LegCollisionSafety.FindSafeMountOffset" in stage
    assert "self.leftDrive:GetLeg():StageGeometry" in stage
    assert "self.rightDrive:GetLeg():StageGeometry" in stage
    assert "LegDriveAssembly.new" not in stage
    assert "VectorForce" not in pair


def test_rcp04_runtime_drives_short_transaction_without_resetting_body_or_drives() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    apply = runtime.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split("function RacerRuntime:ApplyShape", 1)[0]
    assert "reshape.TypicalDuration" in apply
    assert "task.wait(duration / 3)" in apply
    assert "self.legPair:StageRedraw(shapeSpec)" in apply
    assert "self.legPair:CommitStagedRedraw()" in apply
    for forbidden in ["self.body.CFrame =", "AssemblyLinearVelocity =", "AssemblyAngularVelocity =", "LegPairAssembly.new"]:
        assert forbidden not in apply
