from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    return text.split(start, 1)[1].split(end, 1)[0]


def test_mr03_pair_owns_two_persistent_drives_and_no_shared_axle() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    assert pair.count("LegDriveAssembly.new") == 2
    assert drive.count('Instance.new("HingeConstraint")') == 1
    assert 'Instance.new("HingeConstraint")' not in pair
    for retired in ['"AxleRoot"', '"AxleJoint"', "AxleMotorAttachment", "LegSocketZAbs"]:
        assert retired not in pair


def test_mr03_initial_phase_is_split_across_two_explicit_mount_drives() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert 'side = "Left"' in pair
    assert 'side = "Right"' in pair
    assert "local initialPhase = params.initialPhaseDegrees or 0" in pair
    assert "initialPhaseDegrees = initialPhase" in pair
    assert "initialPhaseDegrees = initialPhase + PhysicsConfig.Motor.RightPhaseOffsetDegrees" in pair
    assert "RightPhaseOffsetDegrees" in pair
    assert '"LeftLegMount"' in pair and '"RightLegMount"' in pair


def test_mr03_runtime_constructs_pair_once_and_redraw_keeps_identity() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    initial = section(runtime, "function RacerRuntime:_CreateInitialLegPair", "function RacerRuntime:_ApplyShapeSpec")
    apply_body = section(runtime, "function RacerRuntime:_ApplyShapeSpec", "function RacerRuntime:ApplyShape")
    assert initial.count("LegPairAssembly.new") == 1
    assert "self.legPair = legPair" in initial
    assert "LegPairAssembly.new" not in apply_body
    assert "self.legPair:StageRedraw(shapeSpec)" in apply_body
    assert "self.legPair:CommitStagedRedraw()" in apply_body


def test_mr03_redraw_never_replaces_drive_mount_or_side_owners() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    stage = section(pair, "function LegPairAssembly:StageRedraw", "function LegPairAssembly:SetStageProgress")
    assert "LegDriveAssembly.new" not in stage
    assert "LegAssembly.new" not in stage
    assert "LeftLegMount" not in stage
    assert "RightLegMount" not in stage
    assert "self.leftDrive:GetLeg():StageGeometry" in stage
    assert "self.rightDrive:GetLeg():StageGeometry" in stage
