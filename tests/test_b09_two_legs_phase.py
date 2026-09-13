from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_b09_two_lower_drives_keep_180_initial_phase_with_one_command_owner() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert "RightPhaseOffsetDegrees = 180" in config
    assert "bodyMount: Attachment" in drive
    assert "params.bodyMount" in drive
    assert "body.Size.X / 2" not in drive
    assert '"LeftLegMount"' in pair and '"RightLegMount"' in pair
    assert 'side = "Left"' in pair and 'side = "Right"' in pair
    assert "initialPhaseDegrees = initialPhase" in pair
    assert "initialPhaseDegrees = initialPhase + PhysicsConfig.Motor.RightPhaseOffsetDegrees" in pair
    assert "local baseOmega = LegDriveMath.ComputeAngularVelocity" in pair
    assert "self.leftDrive:SetMotorVelocity(baseOmega)" in pair
    assert "self.rightDrive:SetMotorVelocity(baseOmega)" in pair
    assert "ComputePhaseCorrection" not in pair
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
