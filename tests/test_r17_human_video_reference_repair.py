from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_human_video_proves_shared_side_legs_are_co_phased_not_opposed() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    b09 = read("src/server/Tests/B09TwoLegPhaseSpec.lua")
    evidence = read("src/server/Tests/R17PhaseEvidence.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")

    # Human reference-video evidence: the two depth-separated rigid copies keep
    # the same angular orientation. One axle remains correct; the old 180-degree
    # local offset made the visible pair wrap around the cube like a cage.
    assert "RightPhaseOffsetDegrees = 0" in config
    assert "PHASE_TARGET_DEGREES = 0" in evidence
    assert "co-phase" in b09.lower()
    assert "expected 0" in b09.lower()

    assert 'side = "Left"' in pair and 'side = "Right"' in pair
    assert "RightPhaseOffsetDegrees" in pair
    assert pair.count('Instance.new("HingeConstraint")') == 1


def test_human_video_rider_mount_aligns_seat_reference_instead_of_burying_hrp() -> None:
    rider = read("src/client/Controllers/RiderPresentationController.lua")

    # The current fixed HRP +0.30 mount visibly buries most of a 0.65 avatar in
    # the 3-stud cube. Mount by a pelvis/torso reference and its half-height.
    for token in [
        "seatPart",
        'FindFirstChild("LowerTorso")',
        'FindFirstChild("Torso")',
        "seatPart.Size.Y * 0.5",
        "function RiderPresentationController:_targetSeatCFrame",
        "record.visual:GetPivot():ToObjectSpace(record.seatPart.CFrame)",
        "targetSeat * localSeat:Inverse()",
    ]:
        assert token in rider, f"missing rider seat-mount repair token: {token}"

    assert "RIDER_MOUNT_Y_OFFSET = 0.30" not in rider
    assert "body.Size.Y * 0.5 + RIDER_MOUNT_Y_OFFSET" not in rider
    assert "CanCollide = false" in rider
    assert "Massless = true" in rider
