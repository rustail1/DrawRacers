from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_b09_two_horizontal_drives_keep_180_phase_target() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert "RightPhaseOffsetDegrees = 180" in config
    assert 'side == "Left" then -body.Size.X / 2 else body.Size.X / 2' in drive
    assert "Vector3.new(pivotX, 0, 0)" in drive
    assert 'side = "Left"' in pair and 'side = "Right"' in pair
    assert "initialPhaseDegrees = (params.initialPhaseDegrees or 0) + PhysicsConfig.Motor.RightPhaseOffsetDegrees" in pair
    assert "LegDriveMath.PairPhaseErrorDegrees" in pair
    assert "self.leftDrive:SetMotorVelocity" in pair
    assert "self.rightDrive:SetMotorVelocity" in pair
    assert "LegSocketZAbs" not in pair


def test_b09_same_shape_reaches_both_persistent_leg_owners() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert "leftDrive:GetLeg():InstallGeometry(params.shapeSpec, initialOffset)" in pair
    assert "rightDrive:GetLeg():InstallGeometry(params.shapeSpec, initialOffset)" in pair
    assert "self.leftDrive:GetLeg():StageGeometry(shapeSpec, offset)" in pair
    assert "self.rightDrive:GetLeg():StageGeometry(shapeSpec, offset)" in pair
    assert "LegDriveAssembly.new" not in pair.split("function LegPairAssembly:StageRedraw", 1)[1].split("function LegPairAssembly:SetStageProgress", 1)[0]


def test_b09_studio_spec_is_wired() -> None:
    assert (ROOT / "src/server/Tests/B09TwoLegPhaseSpec.lua").is_file()
    bootstrap = read("src/server/Bootstrap.server.lua")
    assert "B09TwoLegPhaseSpec" in bootstrap
    assert "B09TwoLegPhaseSpec.run()" in bootstrap
