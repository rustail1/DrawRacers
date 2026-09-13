from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_cr3_free_draw_has_no_center_start_gate_or_marker() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    canonical = read("src/shared/Math/CanonicalLegShape.lua")
    controller = read("src/client/Controllers/DrawingController.lua")
    for retired in ["PivotStartRadiusNormalized", "START_OFF_PIVOT"]:
        assert retired not in config + canonical + controller
    for retired in ["PivotMarker", "PIVOT_COLOR", "START FROM THE DOT"]:
        assert retired not in controller
    pointer = controller.split('function DrawingController:_onPointer', 1)[1]
    assert "semantic.Magnitude" not in pointer


def test_cr3_support_anchor_is_geometry_derived_and_translation_only() -> None:
    canonical = read("src/shared/Math/CanonicalLegShape.lua")
    assert "selectSupportAnchor" in canonical
    assert "leftCandidate" in canonical
    assert "topCandidate" in canonical
    assert "rightCandidate" in canonical
    assert "firstCleaned" in canonical
    assert "point - supportAnchor" in canonical
    assert "presentationAnchor" in canonical
    assert "CenterOnBounds" not in canonical
    assert "AnchorToFirstPoint" not in canonical


def test_cr3_accepted_origin_may_be_any_point_index() -> None:
    controller = read("src/client/Controllers/DrawingController.lua")
    assert "hasOrigin" in controller
    assert "math.abs(first.x)" not in controller
    assert "math.abs(first.y)" not in controller


def test_cr3_gameplay_canvas_has_no_thumbnail_square() -> None:
    controller = read("src/client/Controllers/DrawingController.lua")
    assert "AcceptedShapeThumbnail" not in controller
    assert "_renderThumbnail" not in controller
    assert "fitSemanticPointsToPixels" not in controller


def test_cr3_pair_owns_explicit_lower_body_mounts() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert "LegMountHorizontalFraction = 0.78" in config
    assert "LegMountVerticalFraction = -0.72" in config
    assert '"LeftLegMount"' in pair
    assert '"RightLegMount"' in pair
    assert "LegMountHorizontalFraction" in pair
    assert "LegMountVerticalFraction" in pair
    assert "mountY" in pair


def test_cr3_drive_consumes_supplied_mount_instead_of_side_midpoint() -> None:
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    assert "bodyMount: Attachment" in drive
    assert "params.bodyMount" in drive
    assert "body.Size.X / 2" not in drive
    assert "pivotX" not in drive
    assert "bodyAttachment.Position" not in drive


def test_cr3_pair_commands_one_base_omega_without_differential_chasing() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    drive_math = read("src/shared/Math/LegDriveMath.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    assert "local baseOmega = LegDriveMath.ComputeAngularVelocity" in pair
    assert "self.leftDrive:SetMotorVelocity(baseOmega)" in pair
    assert "self.rightDrive:SetMotorVelocity(baseOmega)" in pair
    assert "ComputePhaseCorrection" not in pair
    for retired in ["PhaseCorrectionGain", "MaxPhaseCorrection", "PhaseDeadbandDegrees"]:
        assert retired not in config
    assert "ComputePhaseCorrection" not in drive_math
    assert "RightPhaseOffsetDegrees = 180" in config


def test_cr3_redraw_keeps_mount_drive_joint_and_leg_owners_persistent() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    stage = pair.split("function LegPairAssembly:StageRedraw", 1)[1].split("function LegPairAssembly:SetStageProgress", 1)[0]
    commit = pair.split("function LegPairAssembly:CommitStagedRedraw", 1)[1].split("function LegPairAssembly:CancelStagedRedraw", 1)[0]
    for forbidden in ["LegDriveAssembly.new", "LeftLegMount", "RightLegMount", "Destroy()"]:
        assert forbidden not in stage
        assert forbidden not in commit
    assert "InstallGeometry" not in stage
    assert "CommitStagedGeometry" in commit
