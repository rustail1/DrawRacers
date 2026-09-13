from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_human_reference_requires_twin_side_drives_to_target_180_degrees() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    evidence = read("src/server/Tests/R17PhaseEvidence.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    assert "RightPhaseOffsetDegrees = 180" in config
    assert "PHASE_TARGET_DEGREES = 180" in evidence
    assert 'side = "Left"' in pair and 'side = "Right"' in pair
    assert "RightPhaseOffsetDegrees" in pair
    assert "LegDriveMath.PairPhaseErrorDegrees" in pair
    assert pair.count("LegDriveAssembly.new") == 2
    assert drive.count('Instance.new("HingeConstraint")') == 1
    assert 'Instance.new("HingeConstraint")' not in pair


def test_human_video_rider_mount_aligns_seat_reference_instead_of_burying_hrp() -> None:
    rider = read("src/client/Controllers/RiderPresentationController.lua")
    for token in [
        "seatPart", '"LowerTorso"', '"Torso"', "FindFirstChild(name, true)",
        "seatPart.Size.Y * 0.5", "function RiderPresentationController:_targetSeatCFrame",
        "record.visual:GetPivot():ToObjectSpace(record.seatPart.CFrame)", "targetSeat * localSeat:Inverse()",
    ]:
        assert token in rider
    assert "RIDER_MOUNT_Y_OFFSET = 0.30" not in rider
    assert "CanCollide = false" in rider
    assert "Massless = true" in rider


def test_rider_step_closes_candidate_loop_before_stale_cleanup() -> None:
    rider = read("src/client/Controllers/RiderPresentationController.lua")
    step = rider.split("function RiderPresentationController:_step()", 1)[1].split("function RiderPresentationController:Start()", 1)[0]
    assert "\t\t\t\tend\n\t\t\tend\n\t\tend\n\tend\n\n\tlocal stale" in step
