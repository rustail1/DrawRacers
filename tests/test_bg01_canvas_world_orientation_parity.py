from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_bg01_redraw_reuses_persistent_twin_drive_and_leg_owners() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    stage = pair.split("function LegPairAssembly:StageRedraw", 1)[1].split("function LegPairAssembly:SetStageProgress", 1)[0]
    assert "self.leftDrive:GetLeg():StageGeometry(shapeSpec, offset)" in stage
    assert "self.rightDrive:GetLeg():StageGeometry(shapeSpec, offset)" in stage
    assert "LegDriveAssembly.new" not in stage
    assert "LegAssembly.new" not in stage
    assert 'Instance.new("HingeConstraint")' not in stage


def test_bg01_phase_relationship_is_owned_by_pair_not_geometry() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "PhysicsConfig.Motor.RightPhaseOffsetDegrees" in pair
    assert "LegDriveMath.PairPhaseErrorDegrees" in pair
    assert "self.leftDrive:SetMotorVelocity(baseOmega)" in pair
    assert "self.rightDrive:SetMotorVelocity(baseOmega)" in pair
    assert "ComputePhaseCorrection" not in pair
    assert "phaseDegrees" not in leg
    assert "structuralPhase" not in leg.lower()


def test_bg01_support_anchor_restores_free_draw_presentation_without_changing_network_truth() -> None:
    canonical = read("src/shared/Math/CanonicalLegShape.lua")
    drawing = read("src/client/Controllers/DrawingController.lua")
    assert "AnchorToFirstPoint" not in canonical
    assert "selectSupportAnchor" in canonical
    assert "presentationAnchor" in canonical
    assert "_presentationAnchors" in drawing
    assert "_acceptedPresentationAnchor" in drawing
    assert "PivotMarker" not in drawing
    assert "START FROM THE DOT" not in drawing
