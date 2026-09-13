from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def current_cr3() -> str:
    return read("docs/CR3_CURRENT_SOURCE_OF_TRUTH.md")


def test_r16_1_body_orientation_is_arcade_upright() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    assert "Enum.AlignType.AllAxes" in stabilizer
    assert "orientationAlign.CFrame = CFrame.identity" in stabilizer
    assert "orientationAlign.RigidityEnabled = true" in stabilizer
    assert "Enum.AlignType.PrimaryAxisParallel" not in stabilizer


def test_r16_1_upright_attachment_uses_identity_basis_for_all_axes() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    assert "orientationAttachment.Axis = Vector3.xAxis" in stabilizer
    assert "orientationAttachment.SecondaryAxis = Vector3.yAxis" in stabilizer
    assert "orientationAttachment.Axis = Vector3.zAxis" not in stabilizer


def test_r16_2_cr3_lower_drive_mounts_have_one_owner() -> None:
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    config = read("src/shared/Config/PhysicsConfig.lua")
    assert "bodyMount: Attachment" in drive
    assert "params.bodyMount" in drive
    assert "body.Size.X / 2" not in drive
    assert '"LeftLegMount"' in pair and '"RightLegMount"' in pair
    assert "LegMountHorizontalFraction = 0.78" in config
    assert "LegMountVerticalFraction = -0.72" in config
    assert "LegSocketZAbs" not in pair
    assert "HubOffsetX" not in pair
    assert "LeftHub" not in runtime and "RightHub" not in runtime


def test_r16_2_current_source_records_cr3_twin_drive_lower_mount_layout() -> None:
    current = current_cr3()
    assert "CR3" in current
    for token in ["LeftLegMount", "RightLegMount", "LegDriveAssembly", "DriveJoint"]:
        assert token in current
    assert "No current `AxleRoot` / `AxleJoint`" in current


def test_r16_3_one_shape_builds_two_same_xy_legs_about_two_lower_mounts() -> None:
    geometry = read("src/shared/Math/GeometryMath.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "local mapped = point * geometry.LegCanvasHalfSpan" in geometry
    assert "MaxLegExtentFromHub" in geometry
    initial = runtime.split("function RacerRuntime:_CreateInitialLegPair", 1)[1].split("function RacerRuntime:_ApplyShapeSpec", 1)[0]
    assert initial.count("LegPairAssembly.new") == 1
    assert 'side = "Left"' in pair and 'side = "Right"' in pair
    assert '"LeftLegMount"' in pair and '"RightLegMount"' in pair
    assert "leftDrive:GetLeg():InstallGeometry(params.shapeSpec, initialOffset)" in pair
    assert "rightDrive:GetLeg():InstallGeometry(params.shapeSpec, initialOffset)" in pair
    assert '"DriveWeld"' in leg
    apply_shape_spec = runtime.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split("function RacerRuntime:ApplyShape", 1)[0]
    assert "shapeSpec.normalizedPoints" not in apply_shape_spec


def test_r16_3b_server_uses_geometry_support_anchor_without_resizing_or_center_gate() -> None:
    builder = read("src/shared/Math/CanonicalLegShape.lua")
    service = read("src/server/Services/LegShapeService.lua")
    config = read("src/shared/Config/PhysicsConfig.lua")
    assert "START_OFF_PIVOT" not in builder
    assert "PivotStartRadiusNormalized" not in config
    assert "selectSupportAnchor" in builder
    assert "point - supportAnchor" in builder
    assert "presentationAnchor" in builder
    assert "AnchorToFirstPoint" not in builder
    assert "CenterOnBounds" not in builder
    assert "CanonicalLegShape.Build" in service


def test_r16_3b_internal_apply_shape_cannot_bypass_shared_canonical_builder() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    internal_shape = runtime.split("local function makeInternalShapeSpec", 1)[1].split("local function publishValidatedShapeState", 1)[0]
    assert "CanonicalLegShape.Build" in internal_shape
    assert "PhysicsConfig.StrokeProcessing" in internal_shape
    assert "PhysicsConfig.LegGeometry" in internal_shape
    assert "normalizedPoints = canonical.normalizedPoints" in internal_shape
    assert "segmentPlan = canonical.segmentPlan" in internal_shape
    assert "StrokeMath." not in internal_shape
    assert "GeometryMath." not in internal_shape


def test_cr3_current_source_supersedes_cr2_fixed_center_and_phase_chasing() -> None:
    current = current_cr3()
    design = read("docs/superpowers/specs/2026-09-14-core-repair-v3-free-draw-single-phase-design.md")
    assert "free drawing" in current.lower() or "free drawing surface" in current.lower()
    assert "support anchor" in current.lower()
    assert "LegDriveAssembly" in current
    assert "shared axle" not in current.lower() or "no current" in current.lower()
    assert "differential" in current.lower() and "no" in current.lower()
    assert "free draw" in design.lower()


def test_cr3_network_contract_returns_authoritative_points_with_client_only_presentation_anchor() -> None:
    current = current_cr3()
    assert "StrokeResult.acceptedPoints" in current
    assert "presentationAnchor" in current
    assert "not part of the network payload" in current
    assert "authoritative" in current.lower()


def test_cr3_status_keeps_human_g0_pending() -> None:
    current = current_cr3()
    assert "CR3" in current
    assert "G0" in current
    assert "PENDING" in current
    assert "HUMAN" in current.upper()


def test_cr3_owner_contract_matches_upright_free_draw_and_current_tuning() -> None:
    current = current_cr3()
    assert "support anchor" in current.lower()
    assert "twin" in current.lower() or "two persistent" in current.lower()
    assert "upright" in current.lower()
    assert "LegCanvasHalfSpan = 3.2" in current
    assert "MaxLegExtentFromHub = 4.5" in current
    assert "TargetTipSpeed = 10.5" in current


def test_r16_technical_contract_does_not_reintroduce_free_body_roll() -> None:
    current = current_cr3()
    assert "upright" in current.lower()
    assert "RigidityEnabled = true" in current


def test_r16_current_source_records_human_pending() -> None:
    current = current_cr3()
    assert "G0 / HUMAN STUDIO: PENDING" in current
    assert "do not claim" in current.lower()


def test_r16_qa_contract_keeps_upright_and_transactional_redraw_acceptance() -> None:
    current = current_cr3()
    assert "upright" in current.lower()
    assert "old physical geometry remains active" in current.lower()
    assert "commit" in current.lower()


def test_latest_phase_decision_is_180_with_single_pair_command_owner() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    drive_math = read("src/shared/Math/LegDriveMath.lua")
    assert "RightPhaseOffsetDegrees = 180" in config
    assert "LegDriveMath.PairPhaseErrorDegrees" in pair
    assert "local baseOmega = LegDriveMath.ComputeAngularVelocity" in pair
    assert "self.leftDrive:SetMotorVelocity(baseOmega)" in pair
    assert "self.rightDrive:SetMotorVelocity(baseOmega)" in pair
    assert "ComputePhaseCorrection" not in pair
    assert "ComputePhaseCorrection" not in drive_math
    assert "SignedShortestDeltaDegrees" in drive_math
    assert "SetInitialPhaseDegrees" not in pair
    assert "_StepLegPhaseSync" not in read("src/server/Runtime/RacerRuntime.lua")
