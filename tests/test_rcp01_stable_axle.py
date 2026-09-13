from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    return text.split(start, 1)[1].split(end, 1)[0]


def test_rcp01_redraw_reuses_existing_twin_drives_and_joints() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    apply_body = section(runtime, "function RacerRuntime:_ApplyShapeSpec", "function RacerRuntime:ApplyShape")
    assert "LegPairAssembly.new" not in apply_body
    assert "self.legPair:StageRedraw(shapeSpec)" in apply_body
    assert "self.legPair:CommitStagedRedraw()" in apply_body
    stage = section(pair, "function LegPairAssembly:StageRedraw", "function LegPairAssembly:SetStageProgress")
    assert "LegDriveAssembly.new" not in stage
    assert 'Instance.new("HingeConstraint")' not in stage


def test_rcp01_redraw_reuses_existing_side_owners() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    body = section(pair, "function LegPairAssembly:StageRedraw", "function LegPairAssembly:SetStageProgress")
    assert "self.leftDrive:GetLeg():StageGeometry" in body
    assert "self.rightDrive:GetLeg():StageGeometry" in body
    assert "LegAssembly.new" not in body


def test_rcp01_motor_ownership_is_per_drive_and_pair_only_coordinates() -> None:
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert drive.count('Instance.new("HingeConstraint")') == 1
    assert 'Instance.new("HingeConstraint")' not in pair
    assert pair.count("LegDriveAssembly.new") == 2
    assert "SetMotorVelocity" in pair
